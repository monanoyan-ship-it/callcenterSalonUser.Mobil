import 'package:callcenter_salonuser_mobil/models/appointment_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/appointment_tile.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Randevu listesi — tarih aralığı + status filtreleri.
/// Tap → AppointmentDetailPage (P2.4). MainShell BottomNav'a eklenir (P2.6).
class AppointmentsListPage extends StatefulWidget {
  const AppointmentsListPage({super.key});

  @override
  State<AppointmentsListPage> createState() => _AppointmentsListPageState();
}

enum _DateFilter { today, tomorrow, yesterday, thisWeek, custom }

class _AppointmentsListPageState extends State<AppointmentsListPage> {
  static final _hour = DateFormat('HH:mm', 'tr_TR');
  static final _dayDate = DateFormat('d MMM', 'tr_TR');
  static final _rangeFmt = DateFormat('d MMM y', 'tr_TR');

  _DateFilter _dateFilter = _DateFilter.today;
  DateTimeRange? _customRange;
  int? _statusFilter; // null = hepsi

  bool _loading = true;
  String? _error;
  List<Appointment> _appointments = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  ({DateTime from, DateTime to}) get _resolvedRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_dateFilter) {
      case _DateFilter.today:
        return (from: today, to: today.add(const Duration(days: 1)));
      case _DateFilter.tomorrow:
        return (from: today.add(const Duration(days: 1)), to: today.add(const Duration(days: 2)));
      case _DateFilter.yesterday:
        return (from: today.subtract(const Duration(days: 1)), to: today);
      case _DateFilter.thisWeek:
        // Pazartesi başlangıç (1=Mon ... 7=Sun)
        final start = today.subtract(Duration(days: now.weekday - 1));
        return (from: start, to: start.add(const Duration(days: 7)));
      case _DateFilter.custom:
        final r = _customRange;
        if (r == null) return (from: today, to: today.add(const Duration(days: 1)));
        return (from: r.start, to: r.end.add(const Duration(days: 1)));
    }
  }

  String get _rangeLabel {
    final r = _resolvedRange;
    final endInclusive = r.to.subtract(const Duration(days: 1));
    if (r.from.isAtSameMomentAs(endInclusive) ||
        r.from.add(const Duration(days: 1)).isAtSameMomentAs(r.to)) {
      return _rangeFmt.format(r.from);
    }
    return '${_rangeFmt.format(r.from)} – ${_rangeFmt.format(endInclusive)}';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<SalonApiClient>();
      final r = _resolvedRange;
      final list = await api.getAppointments(
        from: r.from,
        to: r.to,
        statusId: _statusFilter,
      );
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (!mounted) return;
      setState(() {
        _appointments = list;
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

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customRange ??
          DateTimeRange(
              start: DateTime(now.year, now.month, now.day),
              end: DateTime(now.year, now.month, now.day)),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _dateFilter = _DateFilter.custom;
      });
      await _load();
    }
  }

  void _setDateFilter(_DateFilter f) {
    if (f == _DateFilter.custom) {
      _pickCustomRange();
      return;
    }
    setState(() => _dateFilter = f);
    _load();
  }

  void _setStatusFilter(int? s) {
    setState(() => _statusFilter = s);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevular'),
        actions: [
          IconButton(
            tooltip: 'Tarih aralığı seç',
            icon: const Icon(Icons.calendar_month),
            onPressed: _pickCustomRange,
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            _FilterRow(
              dateFilter: _dateFilter,
              statusFilter: _statusFilter,
              rangeLabel: _rangeLabel,
              onDateFilter: _setDateFilter,
              onStatusFilter: _setStatusFilter,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              Icon(Icons.cloud_off,
                                  size: 36, color: scheme.error),
                              const SizedBox(height: 12),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              Center(
                                child: FilledButton.icon(
                                  onPressed: _load,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Tekrar dene'),
                                ),
                              ),
                            ],
                          )
                        : _appointments.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(40),
                                children: [
                                  Icon(Icons.event_busy,
                                      size: 56,
                                      color: scheme.onSurfaceVariant),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Bu aralıkta randevu yok.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                    16, 8, 16, 24),
                                itemCount: _appointments.length,
                                separatorBuilder: (ctx, idx) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final a = _appointments[i];
                                  // Bugün dışı tarihlerde tarih satırı göster.
                                  final showDate = _dateFilter !=
                                          _DateFilter.today ||
                                      a.startTime.day != DateTime.now().day;
                                  return AppointmentTile(
                                    appointment: a,
                                    hourFmt: _hour,
                                    dateFmt: showDate ? _dayDate : null,
                                    onTap: () {
                                      // P2.4: AppointmentDetailPage push (henüz yok).
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Detay sayfası P2.4 ile gelecek (id ${a.id}).'),
                                          duration:
                                              const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.dateFilter,
    required this.statusFilter,
    required this.rangeLabel,
    required this.onDateFilter,
    required this.onStatusFilter,
  });

  final _DateFilter dateFilter;
  final int? statusFilter;
  final String rangeLabel;
  final ValueChanged<_DateFilter> onDateFilter;
  final ValueChanged<int?> onStatusFilter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ChipBtn(
                  label: 'Bugün',
                  selected: dateFilter == _DateFilter.today,
                  onTap: () => onDateFilter(_DateFilter.today),
                ),
                const SizedBox(width: 6),
                _ChipBtn(
                  label: 'Yarın',
                  selected: dateFilter == _DateFilter.tomorrow,
                  onTap: () => onDateFilter(_DateFilter.tomorrow),
                ),
                const SizedBox(width: 6),
                _ChipBtn(
                  label: 'Dün',
                  selected: dateFilter == _DateFilter.yesterday,
                  onTap: () => onDateFilter(_DateFilter.yesterday),
                ),
                const SizedBox(width: 6),
                _ChipBtn(
                  label: 'Bu hafta',
                  selected: dateFilter == _DateFilter.thisWeek,
                  onTap: () => onDateFilter(_DateFilter.thisWeek),
                ),
                const SizedBox(width: 6),
                _ChipBtn(
                  label: dateFilter == _DateFilter.custom
                      ? rangeLabel
                      : 'Aralık seç',
                  selected: dateFilter == _DateFilter.custom,
                  onTap: () => onDateFilter(_DateFilter.custom),
                  icon: Icons.date_range,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2, bottom: 4),
            child: Text(
              rangeLabel,
              style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ChipBtn(
                  label: 'Tümü',
                  selected: statusFilter == null,
                  onTap: () => onStatusFilter(null),
                ),
                const SizedBox(width: 6),
                _ChipBtn(
                  label: 'Planlandı',
                  selected: statusFilter == AppointmentStatuses.planned,
                  onTap: () => onStatusFilter(AppointmentStatuses.planned),
                ),
                const SizedBox(width: 6),
                _ChipBtn(
                  label: 'Onaylandı',
                  selected: statusFilter == AppointmentStatuses.confirmed,
                  onTap: () => onStatusFilter(AppointmentStatuses.confirmed),
                ),
                const SizedBox(width: 6),
                _ChipBtn(
                  label: 'Tamamlandı',
                  selected: statusFilter == AppointmentStatuses.completed,
                  onTap: () => onStatusFilter(AppointmentStatuses.completed),
                ),
                const SizedBox(width: 6),
                _ChipBtn(
                  label: 'İptal',
                  selected: statusFilter == AppointmentStatuses.cancelled,
                  onTap: () => onStatusFilter(AppointmentStatuses.cancelled),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipBtn extends StatelessWidget {
  const _ChipBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 12,
        color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
