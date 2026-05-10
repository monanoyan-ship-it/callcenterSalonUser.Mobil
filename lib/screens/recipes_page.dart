import 'package:callcenter_salonuser_mobil/models/inventory_models.dart';
import 'package:callcenter_salonuser_mobil/models/sln_service.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// `GET /api/sln-recipes` — recete (urun → hizmet maliyet formulu).
class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  static final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  bool _loading = true;
  String? _error;
  List<SlnRecipe> _recipes = const [];
  String _query = '';

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
      final list = await context.read<SalonApiClient>().fetchRecipes();
      if (!mounted) return;
      setState(() {
        _recipes = list;
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

  Future<void> _openEditor({SlnRecipe? existing}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _RecipeEditPage(existing: existing)),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _delete(SlnRecipe r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Receteyi sil'),
        content: Text('${r.name} silinecek. Devam edilsin mi?'),
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
      await context.read<SalonApiClient>().deleteRecipe(r.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recete silindi.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    }
  }

  List<SlnRecipe> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _recipes;
    return _recipes.where((r) {
      return r.name.toLowerCase().contains(q) ||
          (r.serviceName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receteler'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni recete'),
      ),
      body: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Recete adi veya hizmet ara...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
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
      return const Center(child: Text('Recete bulunamadi.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final r = items[i];
          final scheme = Theme.of(context).colorScheme;
          return Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(r.name),
              subtitle: Text([
                if (r.serviceName != null && r.serviceName!.isNotEmpty)
                  'Hizmet: ${r.serviceName}',
                '${r.items.length} kalem',
                if (!r.isActive) 'Pasif',
              ].join(' · ')),
              trailing: Text(_money.format(r.estimatedCost),
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
              onTap: () => _openEditor(existing: r),
              onLongPress: () => _delete(r),
            ),
          );
        },
      ),
    );
  }
}

class _RecipeEditPage extends StatefulWidget {
  const _RecipeEditPage({this.existing});
  final SlnRecipe? existing;

  @override
  State<_RecipeEditPage> createState() => _RecipeEditPageState();
}

class _RecipeEditPageState extends State<_RecipeEditPage> {
  static final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  bool _loading = true;
  bool _saving = false;
  String? _error;

  List<SlnProduct> _products = const [];
  List<SlnServiceCategory> _serviceCategories = const [];

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int? _serviceId;
  bool _isActive = true;
  final _items = <_DraftItem>[];

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    if (r != null) {
      _nameCtrl.text = r.name;
      _descCtrl.text = r.description ?? '';
      _serviceId = r.serviceId;
      _isActive = r.isActive;
      _items.addAll(r.items.map((i) => _DraftItem(
            productId: i.productId,
            productName: i.productName,
            quantity: i.quantity,
            unit: i.unit,
            notes: i.notes,
          )));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bootstrap();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<SalonApiClient>();
      final products = await api.fetchProducts();
      final cats = await api.getServiceCategories();
      if (!mounted) return;
      setState(() {
        _products = products;
        _serviceCategories = cats;
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

  Future<void> _addItem() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Once urun tanimlayin (Phase 9.2).')),
      );
      return;
    }
    final picked = await showModalBottomSheet<_DraftItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RecipeItemSheet(products: _products),
    );
    if (picked != null && mounted) setState(() => _items.add(picked));
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recete adi zorunlu.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final dto = SlnRecipeCreate(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        serviceId: _serviceId,
        isActive: _isActive,
        items: [
          for (var i = 0; i < _items.length; i++)
            SlnRecipeItemCreate(
              productId: _items[i].productId,
              quantity: _items[i].quantity,
              unit: _items[i].unit,
              notes: _items[i].notes,
              sortOrder: i,
            ),
        ],
      );
      final api = context.read<SalonApiClient>();
      if (widget.existing == null) {
        await api.createRecipe(dto);
      } else {
        await api.updateRecipe(widget.existing!.id, dto);
      }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Yeni recete' : widget.existing!.name),
        actions: [
          IconButton(
            tooltip: 'Kaydet',
            onPressed: _saving || _loading ? null : _save,
            icon: const Icon(Icons.save_outlined),
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
              FilledButton(onPressed: _bootstrap, child: const Text('Tekrar dene')),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Recete adi *')),
        const SizedBox(height: 8),
        TextField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Aciklama')),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          initialValue: _serviceId,
          decoration: const InputDecoration(labelText: 'Bagli hizmet (opsiyonel)'),
          items: [
            const DropdownMenuItem(value: null, child: Text('— Yok —')),
            for (final cat in _serviceCategories.where((c) => c.isActive))
              for (final s in cat.services.where((s) => s.isActive))
                DropdownMenuItem(value: s.id, child: Text('${cat.name} · ${s.name}')),
          ],
          onChanged: (v) => setState(() => _serviceId = v),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Aktif'),
          contentPadding: EdgeInsets.zero,
          value: _isActive,
          onChanged: (v) => setState(() => _isActive = v),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text('Urun kalemleri', style: Theme.of(context).textTheme.titleSmall)),
          TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Urun ekle'),
          ),
        ]),
        if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Henuz urun kalemi yok.'),
          ),
        for (var i = 0; i < _items.length; i++)
          Card(
            child: ListTile(
              title: Text(_items[i].productName),
              subtitle: Text('${_items[i].quantity.toStringAsFixed(_items[i].quantity == _items[i].quantity.truncate() ? 0 : 2)} ${_items[i].unit}'
                  '${_items[i].notes != null && _items[i].notes!.isNotEmpty ? ' · ${_items[i].notes}' : ''}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => _items.removeAt(i)),
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (widget.existing != null)
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Expanded(child: Text('Tahmini maliyet (mevcut)')),
                Text(_money.format(widget.existing!.estimatedCost),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: const Text('Kaydet'),
        ),
      ],
    );
  }
}

class _DraftItem {
  _DraftItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    this.notes,
  });

  final int productId;
  final String productName;
  final double quantity;
  final String unit;
  final String? notes;
}

class _RecipeItemSheet extends StatefulWidget {
  const _RecipeItemSheet({required this.products});
  final List<SlnProduct> products;

  @override
  State<_RecipeItemSheet> createState() => _RecipeItemSheetState();
}

class _RecipeItemSheetState extends State<_RecipeItemSheet> {
  SlnProduct? _product;
  final _qtyCtrl = TextEditingController(text: '1');
  final _unitCtrl = TextEditingController(text: 'gr');
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final p = _product;
    if (p == null) return;
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 1;
    Navigator.pop(
      context,
      _DraftItem(
        productId: p.id,
        productName: p.name,
        quantity: qty,
        unit: _unitCtrl.text.trim().isEmpty ? p.unit : _unitCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Urun ekle', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<SlnProduct>(
                initialValue: _product,
                decoration: const InputDecoration(labelText: 'Urun *'),
                isExpanded: true,
                items: [
                  for (final p in widget.products)
                    DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) {
                  setState(() {
                    _product = v;
                    if (v != null) _unitCtrl.text = v.unit;
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Miktar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _unitCtrl,
                    decoration: const InputDecoration(labelText: 'Birim (gr/ml/Adet)'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Not')),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _product == null ? null : _confirm,
                icon: const Icon(Icons.check),
                label: const Text('Ekle'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
