import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static final _money =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
  static final _rangeFmt = DateFormat('d MMM y', 'tr_TR');

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _kpis = {};
  Map<String, dynamic> _sales = {};
  List<Map<String, dynamic>> _staff = const [];

  // Default: bu ay
  late DateTimeRange _range;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0));
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
      final api = context.read<SalonApiClient>();
      final results = await Future.wait([
        api.getReportKpis(from: _range.start, to: _range.end),
        api.getReportSales(from: _range.start, to: _range.end).catchError((_) => <String, dynamic>{}),
        api.getReportStaff(from: _range.start, to: _range.end).catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _kpis = results[0] as Map<String, dynamic>;
        _sales = results[1] as Map<String, dynamic>;
        _staff = results[2] as List<Map<String, dynamic>>;
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

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() => _range = picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar'),
        actions: [
          IconButton(
              icon: const Icon(Icons.calendar_month), onPressed: _pickRange),
        ],
      ),
      body: ResponsiveCenter(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${_rangeFmt.format(_range.start)} – ${_rangeFmt.format(_range.end)}',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Text(_error!, style: TextStyle(color: scheme.error))
              else ...[
                _KpiGrid(kpis: _kpis, money: _money),
                const SizedBox(height: 16),
                if (_staff.isNotEmpty) ...[
                  Text(
                    'Personel performansı',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  for (final s in _staff.take(10))
                    Card(
                      child: ListTile(
                        dense: true,
                        title: Text((s['name'] ?? s['personnelName'] ?? '?').toString()),
                        subtitle: Text(
                          [
                            if (s['appointmentCount'] != null)
                              '${s['appointmentCount']} randevu',
                            if (s['totalRevenue'] != null)
                              _money.format(
                                  (s['totalRevenue'] as num?)?.toDouble() ?? 0),
                          ].join(' · '),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
                if (_sales.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Satış özeti',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          for (final entry in _sales.entries)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Text(entry.key,
                                          style: const TextStyle(fontSize: 13))),
                                  Text(
                                      entry.value is num
                                          ? _money.format(
                                              (entry.value as num).toDouble())
                                          : entry.value.toString(),
                                      style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis, required this.money});
  final Map<String, dynamic> kpis;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = <_Kpi>[];
    void add(String label, dynamic v, {bool isMoney = false}) {
      if (v == null) return;
      String value;
      if (isMoney && v is num) {
        value = money.format(v.toDouble());
      } else {
        value = v.toString();
      }
      entries.add(_Kpi(label: label, value: value));
    }

    add('Toplam ciro', kpis['totalRevenue'] ?? kpis['revenue'], isMoney: true);
    add('Randevu sayısı', kpis['appointmentCount'] ?? kpis['totalAppointments']);
    add('Tamamlanan', kpis['completedAppointments'] ?? kpis['completed']);
    add('İptal', kpis['cancelledAppointments'] ?? kpis['cancelled']);
    add('Yeni müşteri', kpis['newClients']);
    add('Ortalama sepet', kpis['averageBasket'], isMoney: true);

    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'KPI verisi bulunamadı (backend boş veya alan adları farklı).',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final k in entries)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(k.label,
                    style: TextStyle(
                        fontSize: 11, color: scheme.onPrimaryContainer)),
                const SizedBox(height: 2),
                Text(k.value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Kpi {
  const _Kpi({required this.label, required this.value});
  final String label;
  final String value;
}
