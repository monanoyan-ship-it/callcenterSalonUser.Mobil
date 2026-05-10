import 'package:callcenter_salonuser_mobil/models/cash_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Kasa hareketleri — `GET /api/sln-finance/cash-registers` + transactions.
/// Web Cash/Index.cshtml + Cash.js paralel.
class CashPage extends StatefulWidget {
  const CashPage({super.key});

  @override
  State<CashPage> createState() => _CashPageState();
}

class _CashPageState extends State<CashPage> {
  bool _loading = true;
  String? _error;
  List<CashRegister> _registers = const [];

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
      final list = await context.read<SalonApiClient>().fetchCashRegisters();
      if (!mounted) return;
      setState(() {
        _registers = list;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasa'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ResponsiveCenter(child: _body()),
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
    if (_registers.isEmpty) {
      return const Center(child: Text('Kasa bulunamadi.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _registers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final r = _registers[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: r.isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(Icons.point_of_sale,
                    color: r.isActive
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              title: Text(r.name),
              subtitle: Text([
                if (r.branchName != null) r.branchName!,
                if (!r.isActive) 'Pasif',
              ].join(' · ')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CashRegisterDetailPage(register: r),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class CashRegisterDetailPage extends StatefulWidget {
  const CashRegisterDetailPage({super.key, required this.register});

  final CashRegister register;

  @override
  State<CashRegisterDetailPage> createState() => _CashRegisterDetailPageState();
}

class _CashRegisterDetailPageState extends State<CashRegisterDetailPage> {
  static final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  static final _hour = DateFormat('d MMM HH:mm', 'tr_TR');

  bool _loading = true;
  String? _error;
  List<CashTransaction> _transactions = const [];
  Map<String, dynamic> _summary = const {};

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
      final api = context.read<SalonApiClient>();
      final txList = await api.fetchCashTransactions(widget.register.id);
      Map<String, dynamic> sum = const {};
      try {
        sum = await api.fetchCashDailySummary(widget.register.id);
      } catch (_) {
        // ozet baslarsiz olabilir; transactions yine gosterilir.
      }
      if (!mounted) return;
      setState(() {
        _transactions = txList;
        _summary = sum;
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

  Future<void> _addTransaction() async {
    final result = await showModalBottomSheet<CashTransactionCreate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddTransactionSheet(),
    );
    if (result == null || !mounted) return;
    try {
      await context.read<SalonApiClient>().addCashTransaction(widget.register.id, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hareket eklendi.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dioErrorMessage(e))),
      );
    }
  }

  double _summaryNum(String key) {
    final v = _summary[key];
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.register.name),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransaction,
        icon: const Icon(Icons.add),
        label: const Text('Hareket'),
      ),
      body: ResponsiveCenter(child: _body()),
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
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_summary.isNotEmpty) ...[
            Card(
              color: scheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Bugun', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _summaryRow('Gelir', _summaryNum('totalIncome'), color: const Color(0xFF065F46)),
                    _summaryRow('Gider', _summaryNum('totalExpense'), color: scheme.error),
                    const Divider(),
                    _summaryRow('Net nakit', _summaryNum('netCash'), bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text('Hareketler', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          if (_transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Henuz hareket yok.'),
            ),
          for (final t in _transactions)
            Card(
              child: ListTile(
                leading: Icon(
                  t.isIncome
                      ? Icons.arrow_downward
                      : t.isExpense
                          ? Icons.arrow_upward
                          : Icons.swap_horiz,
                  color: t.isIncome
                      ? const Color(0xFF065F46)
                      : t.isExpense
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                ),
                title: Text(t.description.isEmpty ? t.typeLabel : t.description),
                subtitle: Text('${_hour.format(t.createdAt)} · ${t.paymentLabel}'),
                trailing: Text(
                  '${t.isExpense ? '-' : '+'} ${_money.format(t.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: t.isIncome
                        ? const Color(0xFF065F46)
                        : t.isExpense
                            ? scheme.error
                            : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false, Color? color}) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(label, style: style)),
        Text(_money.format(value), style: style),
      ]),
    );
  }
}

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet();

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  int _typeId = 1;
  int _payMethodId = 1;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutar girin.')),
      );
      return;
    }
    Navigator.pop(
      context,
      CashTransactionCreate(
        transactionTypeId: _typeId,
        amount: amount,
        description: _descCtrl.text.trim(),
        paymentMethodId: _payMethodId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Yeni hareket', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('Gelir'), icon: Icon(Icons.arrow_downward)),
                ButtonSegment(value: 2, label: Text('Gider'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: 3, label: Text('Transfer'), icon: Icon(Icons.swap_horiz)),
              ],
              selected: {_typeId},
              onSelectionChanged: (s) => setState(() => _typeId = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Tutar (TL)'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _payMethodId,
              decoration: const InputDecoration(labelText: 'Odeme tipi'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Nakit')),
                DropdownMenuItem(value: 2, child: Text('Kredi Karti')),
                DropdownMenuItem(value: 3, child: Text('Havale/EFT')),
              ],
              onChanged: (v) => setState(() => _payMethodId = v ?? 1),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Aciklama'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Ekle'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
