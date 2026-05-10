import 'package:callcenter_salonuser_mobil/models/appointment_models.dart';
import 'package:callcenter_salonuser_mobil/screens/appointment_edit_dialog.dart';
import 'package:callcenter_salonuser_mobil/screens/invoice_edit_page.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/appointment_tile.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Randevu detayı + status workflow aksiyonları.
/// Pop sırasında değişiklik yapıldıysa `bool true` döndürür → liste yenilensin.
class AppointmentDetailPage extends StatefulWidget {
  const AppointmentDetailPage({super.key, required this.appointmentId});

  final int appointmentId;

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  static final _hour = DateFormat('HH:mm', 'tr_TR');
  static final _date = DateFormat('d MMMM y EEEE', 'tr_TR');
  static final _money =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  bool _loading = true;
  bool _busy = false;
  bool _changed = false;
  String? _error;
  Appointment? _appointment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final a = await context
          .read<SalonApiClient>()
          .getAppointment(widget.appointmentId);
      if (!mounted) return;
      setState(() {
        _appointment = a;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = dioErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _confirmAndChangeStatus({
    required int targetStatus,
    required String confirmTitle,
    required String confirmBody,
    required String successHint,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(confirmTitle),
        content: Text(confirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Onayla')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final res = await context.read<SalonApiClient>().updateAppointmentStatus(
            id: widget.appointmentId,
            statusId: targetStatus,
          );
      if (!mounted) return;
      _changed = true;
      // Listeyi yenilemeden önce yerel kart'ı taze appointment ile değiştir.
      await _load();
      if (!mounted) return;
      final msg = res.penalty > 0
          ? '$successHint · ${_money.format(res.penalty)} ceza uygulandı'
          : (res.message ?? successHint);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dioErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
          title: const Text('Randevu detayı'),
          actions: [
            if (_appointment != null &&
                !_appointment!.isCancelled &&
                !_appointment!.isCompleted)
              IconButton(
                tooltip: 'Düzenle',
                icon: const Icon(Icons.edit_outlined),
                onPressed: _busy
                    ? null
                    : () async {
                        final saved = await AppointmentEditDialog.show(
                            context, _appointment!);
                        if (saved == true) {
                          _changed = true;
                          await _load();
                        }
                      },
              ),
          ],
        ),
        body: ResponsiveCenter(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorBody(message: _error!, onRetry: _load)
                  : _DetailBody(
                      appointment: _appointment!,
                      money: _money,
                      hourFmt: _hour,
                      dateFmt: _date,
                      busy: _busy,
                      onConfirm: () => _confirmAndChangeStatus(
                        targetStatus: AppointmentStatuses.confirmed,
                        confirmTitle: 'Randevuyu onayla',
                        confirmBody:
                            'Bu randevu "Onaylandı" durumuna alınacak. Devam edilsin mi?',
                        successHint: 'Randevu onaylandı.',
                      ),
                      onComplete: () => _confirmAndChangeStatus(
                        targetStatus: AppointmentStatuses.completed,
                        confirmTitle: 'Randevuyu tamamla',
                        confirmBody:
                            'Hizmet tamamlandı olarak işaretlenecek. Devam edilsin mi?',
                        successHint: 'Randevu tamamlandı.',
                      ),
                      onCancel: () => _confirmAndChangeStatus(
                        targetStatus: AppointmentStatuses.cancelled,
                        confirmTitle: 'Randevuyu iptal et',
                        confirmBody:
                            'Bu randevu iptal edilecek. Salon politikasına göre ceza uygulanabilir.',
                        successHint: 'Randevu iptal edildi.',
                      ),
                    ),
        ),
        bottomNavigationBar: _appointment == null
            ? null
            : ResponsiveCenter(
                expandHeight: false,
                child: _ActionBar(
                  appointment: _appointment!,
                  busy: _busy,
                  onConfirm: () => _confirmAndChangeStatus(
                    targetStatus: AppointmentStatuses.confirmed,
                    confirmTitle: 'Randevuyu onayla',
                    confirmBody:
                        'Bu randevu "Onaylandı" durumuna alınacak. Devam edilsin mi?',
                    successHint: 'Randevu onaylandı.',
                  ),
                  onComplete: () => _confirmAndChangeStatus(
                    targetStatus: AppointmentStatuses.completed,
                    confirmTitle: 'Randevuyu tamamla',
                    confirmBody:
                        'Hizmet tamamlandı olarak işaretlenecek. Devam edilsin mi?',
                    successHint: 'Randevu tamamlandı.',
                  ),
                  onCancel: () => _confirmAndChangeStatus(
                    targetStatus: AppointmentStatuses.cancelled,
                    confirmTitle: 'Randevuyu iptal et',
                    confirmBody:
                        'Bu randevu iptal edilecek. Salon politikasına göre ceza uygulanabilir.',
                    successHint: 'Randevu iptal edildi.',
                  ),
                  scheme: scheme,
                ),
              ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.appointment,
    required this.money,
    required this.hourFmt,
    required this.dateFmt,
    required this.busy,
    required this.onConfirm,
    required this.onComplete,
    required this.onCancel,
  });

  final Appointment appointment;
  final NumberFormat money;
  final DateFormat hourFmt;
  final DateFormat dateFmt;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final services = appointment.serviceNames;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Müşteri kartı
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appointment.clientName.isEmpty
                            ? 'İsimsiz müşteri'
                            : appointment.clientName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    AppointmentStatusPill(appointment: appointment),
                  ],
                ),
                if ((appointment.clientPhone ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.phone,
                            size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          appointment.clientPhone!,
                          style: TextStyle(
                              fontSize: 13, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                if (appointment.clientIsBlacklisted ||
                    appointment.clientNoShowCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (appointment.clientIsBlacklisted)
                          _Pill(
                            label: 'Kara liste',
                            icon: Icons.block,
                            color: const Color(0xFFB91C1C),
                          ),
                        if (appointment.clientNoShowCount > 0)
                          _Pill(
                            label:
                                '${appointment.clientNoShowCount}× no-show',
                            icon: Icons.warning_amber_outlined,
                            color: const Color(0xFFB45309),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Saat / personel kartı
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconRow(
                  icon: Icons.event,
                  text: dateFmt.format(appointment.startTime),
                ),
                const SizedBox(height: 6),
                _IconRow(
                  icon: Icons.access_time,
                  text:
                      '${hourFmt.format(appointment.startTime)} – ${hourFmt.format(appointment.endTime)}'
                      ' · ${appointment.durationMinutes} dk',
                ),
                const SizedBox(height: 6),
                _IconRow(
                  icon: Icons.person_outline,
                  text: 'Personel: ${appointment.personnelName}',
                ),
                if ((appointment.branchName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _IconRow(
                    icon: Icons.storefront_outlined,
                    text: 'Şube: ${appointment.branchName!}',
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Hizmetler
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.list_alt, size: 16, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Hizmetler',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (services.isEmpty)
                  Text(
                    'Hizmet seçilmemiş.',
                    style: TextStyle(
                        fontSize: 13, color: scheme.onSurfaceVariant),
                  )
                else
                  for (final s in services)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check, size: 14, color: scheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(s,
                                style: const TextStyle(fontSize: 13.5)),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Ödeme
        if (appointment.depositAmount > 0 || appointment.prepaidAmount > 0)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payments_outlined,
                          size: 16, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Ödeme',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (appointment.depositAmount > 0)
                    Text(
                      'Beklenen depozito: ${money.format(appointment.depositAmount)}',
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  if (appointment.prepaidAmount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        appointment.isPrepaid
                            ? 'Ön ödendi: ${money.format(appointment.prepaidAmount)}'
                            : 'Ödenen tutar: ${money.format(appointment.prepaidAmount)}',
                        style: TextStyle(
                            fontSize: 13.5, color: scheme.primary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if ((appointment.notes ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sticky_note_2_outlined,
                          size: 16, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Notlar',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(appointment.notes!.trim(),
                      style: const TextStyle(fontSize: 13.5, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
        if (appointment.isCancelled) ...[
          const SizedBox(height: 12),
          Card(
            color: scheme.errorContainer.withValues(alpha: 0.4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Bu randevu iptal edildi.',
                style: TextStyle(
                    fontSize: 13, color: scheme.onErrorContainer),
              ),
            ),
          ),
        ] else if (appointment.isCompleted) ...[
          const SizedBox(height: 12),
          Card(
            color: scheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Bu randevu tamamlandı.',
                style: TextStyle(
                    fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
        // P8.5 — Adisyon olustur. Iptal disindaki tum randevular icin gorunur;
        // online on odeme varsa indirim olarak yansir.
        if (!appointment.isCancelled) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoiceEditPage(
                    fromAppointment: AppointmentPrefill(
                      appointmentId: appointment.id,
                      slnClientId: appointment.slnClientId,
                      clientName: appointment.clientName,
                      clientPhone: appointment.clientPhone,
                      serviceIds: appointment.serviceIds,
                      personnelId: appointment.personnelId,
                      personnelName: appointment.personnelName,
                      isPrepaid: appointment.isPrepaid,
                      prepaidAmount: appointment.prepaidAmount,
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long_outlined),
            label: Text(appointment.isPrepaid && appointment.prepaidAmount > 0
                ? 'Adisyon olustur (kalan tahsilat)'
                : 'Adisyon olustur'),
          ),
        ],
      ],
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.cloud_off, size: 48, color: scheme.error),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar dene'),
          ),
        ),
      ],
    );
  }
}

/// Status'e göre primary/secondary aksiyon butonları.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.appointment,
    required this.busy,
    required this.onConfirm,
    required this.onComplete,
    required this.onCancel,
    required this.scheme,
  });

  final Appointment appointment;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (appointment.isPlanned) {
      children
        ..add(Expanded(
          child: FilledButton.icon(
            onPressed: busy ? null : onConfirm,
            icon: const Icon(Icons.check),
            label: const Text('Onayla'),
          ),
        ))
        ..add(const SizedBox(width: 8))
        ..add(Expanded(
          child: OutlinedButton.icon(
            onPressed: busy ? null : onCancel,
            icon: const Icon(Icons.close),
            label: const Text('İptal'),
            style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error.withValues(alpha: 0.5))),
          ),
        ));
    } else if (appointment.isConfirmed) {
      children
        ..add(Expanded(
          child: FilledButton.icon(
            onPressed: busy ? null : onComplete,
            icon: const Icon(Icons.task_alt),
            label: const Text('Tamamla'),
          ),
        ))
        ..add(const SizedBox(width: 8))
        ..add(Expanded(
          child: OutlinedButton.icon(
            onPressed: busy ? null : onCancel,
            icon: const Icon(Icons.close),
            label: const Text('İptal'),
            style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error.withValues(alpha: 0.5))),
          ),
        ));
    } else {
      // Tamamlandı veya İptal: aksiyon yok.
      return const SizedBox.shrink();
    }
    return Material(
      color: scheme.surface,
      elevation: 4,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: children),
        ),
      ),
    );
  }
}
