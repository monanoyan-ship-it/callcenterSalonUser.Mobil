import 'package:callcenter_salonuser_mobil/models/appointment_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tek randevu satır kartı. Dashboard, AppointmentsListPage gibi yerlerde
/// tutarlı görünüm için ortak. `dateFmt` null ise sadece saat aralığı,
/// dolu ise üstte tarih+saat satırı gösterilir.
class AppointmentTile extends StatelessWidget {
  const AppointmentTile({
    super.key,
    required this.appointment,
    required this.hourFmt,
    this.dateFmt,
    this.onTap,
  });

  final Appointment appointment;
  final DateFormat hourFmt;
  final DateFormat? dateFmt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final services = appointment.serviceNames.join(', ');
    final timeRange =
        '${hourFmt.format(appointment.startTime)}–${hourFmt.format(appointment.endTime)}';
    final dateLine = dateFmt?.format(appointment.startTime);

    final body = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              timeRange,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dateLine != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      dateLine,
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appointment.clientName.isEmpty
                            ? 'İsimsiz müşteri'
                            : appointment.clientName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    AppointmentStatusPill(appointment: appointment),
                  ],
                ),
                if (services.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      services,
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Personel: ${appointment.personnelName}',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ),
                if (appointment.clientIsBlacklisted ||
                    appointment.clientNoShowCount > 0) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: [
                      if (appointment.clientIsBlacklisted)
                        const _MiniWarn(text: 'Kara liste', color: Color(0xFFB91C1C)),
                      if (appointment.clientNoShowCount > 0)
                        _MiniWarn(
                          text: '${appointment.clientNoShowCount}× no-show',
                          color: const Color(0xFFB45309),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Card(
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

class AppointmentStatusPill extends StatelessWidget {
  const AppointmentStatusPill({super.key, required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    if (appointment.isCancelled) {
      bg = scheme.errorContainer;
      fg = scheme.onErrorContainer;
    } else if (appointment.isCompleted) {
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurfaceVariant;
    } else if (appointment.isConfirmed) {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF065F46);
    } else {
      bg = const Color(0xFFE0E7FF);
      fg = const Color(0xFF1E40AF);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        appointment.statusLabel,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _MiniWarn extends StatelessWidget {
  const _MiniWarn({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
