import 'package:callcenter_salonuser_mobil/models/expense_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// `GET /api/sln-finance/expenses` — gider listesi + kategori secimi + ay ozeti.
class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  static final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  static final _dateFmt = DateFormat('d MMM y', 'tr_TR');

  bool _loading = true;
  String? _error;
  List<Expense> _expenses = const [];
  List<ExpenseCategory> _categories = const [];
  int? _categoryFilter;
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<SalonApiClient>();
      final cats = await api.fetchExpenseCategories();
      final exp = await api.fetchExpenses(
        from: _range?.start,
        to: _range?.end.add(const Duration(days: 1)),
        categoryId: _categoryFilter,
      );
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _expenses = exp;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = dioErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && mounted) {
      setState(() => _range = picked);
      _load();
    }
  }

  Future<void> _create() async {
    if (_categories.isEmpty) {
      final ok = await _addCategoryDialog();
      if (ok != true || !mounted) return;
      await _load();
      if (!mounted) return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExpenseCreateSheet(categories: _categories),
    );
    if (saved == true && mounted) _load();
  }

  Future<bool?> _addCategoryDialog() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Once kategori ekleyin'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Kategori adi'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgec')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ekle')),
        ],
      ),
    );
    if (ok != true || !mounted) return false;
    try {
      await context.read<SalonApiClient>().createExpenseCategory(ctrl.text.trim());
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
      }
      return false;
    }
  }

  Future<void> _delete(Expense e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gideri sil'),
        content: Text('${_money.format(e.amount)} tutarli ${e.categoryName} gideri silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgec')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<SalonApiClient>().deleteExpense(e.id);
      if (!mounted) return;
      _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(err))));
    }
  }

  double get _total => _expenses.fold(0, (s, e) => s + e.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giderler'),
        actions: [
          IconButton(tooltip: 'Yenile', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Yeni gider'),
      ),
      body: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(_range == null
                            ? 'Tarih araligi'
                            : '${_dateFmt.format(_range!.start)} – ${_dateFmt.format(_range!.end)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: _categoryFilter,
                        decoration: const InputDecoration(labelText: 'Kategori', isDense: true),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Hepsi')),
                          for (final c in _categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (v) {
                          setState(() => _categoryFilter = v);
                          _load();
                        },
                      ),
                    ),
                  ]),
                  if (_expenses.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Card(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            const Expanded(child: Text('Toplam', style: TextStyle(fontWeight: FontWeight.w600))),
                            Text(_money.format(_total),
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.error)),
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Tekrar dene')),
          ]),
        ),
      );
    }
    if (_expenses.isEmpty) return const Center(child: Text('Bu donemde gider yok.'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _expenses.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final e = _expenses[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                child: Icon(Icons.arrow_upward, color: Theme.of(context).colorScheme.onErrorContainer),
              ),
              title: Text(e.categoryName),
              subtitle: Text([
                _dateFmt.format(e.expenseDate),
                e.paymentLabel,
                if (e.description != null && e.description!.isNotEmpty) e.description!,
              ].join(' · ')),
              trailing: Text(_money.format(e.amount),
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.error)),
              onLongPress: () => _delete(e),
            ),
          );
        },
      ),
    );
  }
}

class _ExpenseCreateSheet extends StatefulWidget {
  const _ExpenseCreateSheet({required this.categories});
  final List<ExpenseCategory> categories;

  @override
  State<_ExpenseCreateSheet> createState() => _ExpenseCreateSheetState();
}

class _ExpenseCreateSheetState extends State<_ExpenseCreateSheet> {
  int? _categoryId;
  int _payMethodId = 1;
  DateTime _date = DateTime.now();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) _categoryId = widget.categories.first.id;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1),
      initialDate: _date,
      locale: const Locale('tr', 'TR'),
    );
    if (d != null && mounted) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (_categoryId == null) return;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tutar girin.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<SalonApiClient>().createExpense(ExpenseCreate(
            categoryId: _categoryId!,
            amount: amount,
            expenseDate: _date,
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            paymentMethodId: _payMethodId,
          ));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Yeni gider', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Kategori *'),
                items: [for (final c in widget.categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Tutar (TL) *'),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text('Tarih: ${DateFormat('d MMM y', 'tr_TR').format(_date)}'),
                trailing: IconButton(icon: const Icon(Icons.edit_calendar), onPressed: _pickDate),
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
              TextField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Aciklama')),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: const Text('Kaydet'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
