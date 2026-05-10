import 'package:callcenter_salonuser_mobil/models/invoice_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Adisyon listesi — `GET /api/sln-finance/invoices`. Web Invoices/Index.cshtml paralel.
/// Tap → InvoiceDetailPage (P8.3 eklendiginde).
class InvoicesListPage extends StatefulWidget {
  const InvoicesListPage({super.key});

  @override
  State<InvoicesListPage> createState() => _InvoicesListPageState();
}

enum _DateFilter { today, thisWeek, thisMonth, custom }

class _InvoicesListPageState extends State<InvoicesListPage> {
  static final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  static final _dateTime = DateFormat('d MMM HH:mm', 'tr_TR');
  static final _rangeFmt = DateFormat('d MMM y', 'tr_TR');

  _DateFilter _dateFilter = _DateFilter.today;
  DateTimeRange? _customRange;
  int? _statusFilter; // null = hepsi; 1=Acik, 2=Odendi, 3=Iptal, 4=Iade

  bool _loading = true;
  String? _error;
  List<SlnInvoice> _invoices = const [];
  String _searchQuery = '';

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
      case _DateFilter.thisWeek:
        final start = today.subtract(Duration(days: now.weekday - 1));
        return (from: start, to: start.add(const Duration(days: 7)));
      case _DateFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final next = DateTime(now.year, now.month + 1, 1);
        return (from: start, to: next);
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
      final list = await api.fetchInvoices(
        from: r.from,
        to: r.to,
        statusId: _statusFilter,
      );
      list.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
      if (!mounted) return;
      setState(() {
        _invoices = list;
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
            end: DateTime(now.year, now.month, now.day),
          ),
      locale: const Locale('tr', 'TR'),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateFilter = _DateFilter.custom;
      _customRange = picked;
    });
    await _load();
  }

  List<SlnInvoice> get _filtered {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _invoices;
    return _invoices.where((inv) {
      return inv.invoiceNo.toLowerCase().contains(q) ||
          (inv.clientName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adisyonlar'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Filters(
              rangeLabel: _rangeLabel,
              dateFilter: _dateFilter,
              statusFilter: _statusFilter,
              onDateFilter: (f) {
                setState(() => _dateFilter = f);
                _load();
              },
              onStatusFilter: (s) {
                setState(() => _statusFilter = s);
                _load();
              },
              onCustomTap: _pickCustomRange,
              onSearch: (v) => setState(() => _searchQuery = v),
            ),
            const Divider(height: 1),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Tekrar dene')),
            ],
          ),
        ),
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return const Center(child: Text('Adisyon bulunamadi.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _InvoiceTile(invoice: items[i], money: _money, dateFmt: _dateTime),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.rangeLabel,
    required this.dateFilter,
    required this.statusFilter,
    required this.onDateFilter,
    required this.onStatusFilter,
    required this.onCustomTap,
    required this.onSearch,
  });

  final String rangeLabel;
  final _DateFilter dateFilter;
  final int? statusFilter;
  final ValueChanged<_DateFilter> onDateFilter;
  final ValueChanged<int?> onStatusFilter;
  final VoidCallback onCustomTap;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Adisyon no veya musteri ara...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: onSearch,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip('Bugun', dateFilter == _DateFilter.today,
                    () => onDateFilter(_DateFilter.today)),
                _chip('Bu hafta', dateFilter == _DateFilter.thisWeek,
                    () => onDateFilter(_DateFilter.thisWeek)),
                _chip('Bu ay', dateFilter == _DateFilter.thisMonth,
                    () => onDateFilter(_DateFilter.thisMonth)),
                _chip(
                  dateFilter == _DateFilter.custom ? rangeLabel : 'Aralik...',
                  dateFilter == _DateFilter.custom,
                  onCustomTap,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip('Hepsi', statusFilter == null, () => onStatusFilter(null)),
                _chip('Acik', statusFilter == 1, () => onStatusFilter(1)),
                _chip('Odendi', statusFilter == 2, () => onStatusFilter(2)),
                _chip('Iptal', statusFilter == 3, () => onStatusFilter(3)),
                _chip('Iade', statusFilter == 4, () => onStatusFilter(4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({
    required this.invoice,
    required this.money,
    required this.dateFmt,
  });

  final SlnInvoice invoice;
  final NumberFormat money;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color badgeBg;
    Color badgeFg;
    String badgeLabel;
    switch (invoice.statusId) {
      case 1:
        badgeBg = const Color(0xFFFEF3C7);
        badgeFg = const Color(0xFF92400E);
        badgeLabel = 'Acik';
        break;
      case 2:
        badgeBg = const Color(0xFFD1FAE5);
        badgeFg = const Color(0xFF065F46);
        badgeLabel = 'Odendi';
        break;
      case 3:
        badgeBg = scheme.errorContainer;
        badgeFg = scheme.onErrorContainer;
        badgeLabel = 'Iptal';
        break;
      case 4:
        badgeBg = scheme.surfaceContainerHighest;
        badgeFg = scheme.onSurfaceVariant;
        badgeLabel = 'Iade';
        break;
      default:
        badgeBg = scheme.surfaceContainerHighest;
        badgeFg = scheme.onSurfaceVariant;
        badgeLabel = '?';
    }

    return Card(
      child: InkWell(
        onTap: () {
          // P8.3 InvoiceDetailPage eklendiginde route burada acilacak.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adisyon detayi (P8.3) yakinda.')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '#${invoice.invoiceNo}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: badgeFg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(dateFmt.format(invoice.invoiceDate)),
              if (invoice.clientName != null && invoice.clientName!.isNotEmpty)
                Text(invoice.clientName!,
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${invoice.items.length} kalem',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  Text(
                    money.format(invoice.netAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
