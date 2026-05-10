import 'package:callcenter_salonuser_mobil/models/inventory_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// `GET /api/sln-products` — urun listesi + arama + ekle/duzenle/sil.
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  static final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  bool _loading = true;
  String? _error;
  List<SlnProduct> _products = const [];
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
      final list = await context.read<SalonApiClient>().fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = list;
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

  Future<void> _openEditor({SlnProduct? existing}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _ProductEditPage(existing: existing)),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _delete(SlnProduct p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Urunu sil'),
        content: Text('${p.name} silinecek. Devam edilsin mi?'),
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
      await context.read<SalonApiClient>().deleteProduct(p.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Urun silindi.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    }
  }

  List<SlnProduct> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _products;
    return _products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.categoryName.toLowerCase().contains(q) ||
          (p.barcode?.toLowerCase().contains(q) ?? false) ||
          (p.brandName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Urunler'),
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
        label: const Text('Yeni urun'),
      ),
      body: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Urun adi, kategori, marka, barkod ara...',
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
      return const Center(child: Text('Urun bulunamadi.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final p = items[i];
          final scheme = Theme.of(context).colorScheme;
          return Card(
            child: ListTile(
              title: Text(p.name),
              subtitle: Text([
                p.categoryName,
                if (p.brandName != null && p.brandName!.isNotEmpty) p.brandName!,
                if (p.barcode != null && p.barcode!.isNotEmpty) 'Barkod: ${p.barcode}',
                if (!p.isActive) 'Pasif',
              ].join(' · ')),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_money.format(p.salePrice),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      p.isLowStock ? Icons.warning_amber : Icons.inventory_2_outlined,
                      size: 14,
                      color: p.isLowStock ? scheme.error : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${p.stockQuantity.toStringAsFixed(p.stockQuantity == p.stockQuantity.truncate() ? 0 : 2)} ${p.unit}',
                      style: TextStyle(
                        fontSize: 12,
                        color: p.isLowStock ? scheme.error : scheme.onSurfaceVariant,
                      ),
                    ),
                  ]),
                ],
              ),
              onTap: () => _openEditor(existing: p),
              onLongPress: () => _delete(p),
            ),
          );
        },
      ),
    );
  }
}

/// Yeni urun veya mevcut duzenleme. Backend `SlnProductCreateDto` kategori ZORUNLU
/// kabul eder; bu nedenle once kategorileri yukler. Marka opsiyonel.
class _ProductEditPage extends StatefulWidget {
  const _ProductEditPage({this.existing});
  final SlnProduct? existing;

  @override
  State<_ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<_ProductEditPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<SlnProductCategory> _categories = const [];
  List<SlnBrand> _brands = const [];

  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController(text: '0');
  final _salePriceCtrl = TextEditingController(text: '0');
  final _stockCtrl = TextEditingController(text: '0');
  final _minStockCtrl = TextEditingController(text: '0');
  final _unitCtrl = TextEditingController(text: 'Adet');
  int? _categoryId;
  int? _brandId;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _nameCtrl.text = p.name;
      _barcodeCtrl.text = p.barcode ?? '';
      _purchasePriceCtrl.text = p.purchasePrice.toStringAsFixed(2);
      _salePriceCtrl.text = p.salePrice.toStringAsFixed(2);
      _stockCtrl.text = p.stockQuantity.toString();
      _minStockCtrl.text = p.minStockLevel.toString();
      _unitCtrl.text = p.unit;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bootstrap();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _salePriceCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<SalonApiClient>();
      final cats = await api.fetchProductCategories();
      List<SlnBrand> brands = const [];
      try {
        brands = await api.fetchProductBrands();
      } catch (_) {/* opsiyonel */}
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _brands = brands;
        _loading = false;
        if (widget.existing != null) {
          // Existing kayda categoryId/brandId yansitmiyor — DTO'da yok. Kategori adina gore esle.
          for (final c in cats) {
            if (c.name == widget.existing!.categoryName) _categoryId = c.id;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = dioErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Urun adi zorunlu.')));
      return;
    }
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori secin.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final dto = SlnProductCreate(
        categoryId: _categoryId!,
        brandId: _brandId,
        name: _nameCtrl.text.trim(),
        barcode: _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
        purchasePrice: double.tryParse(_purchasePriceCtrl.text.replaceAll(',', '.')) ?? 0,
        salePrice: double.tryParse(_salePriceCtrl.text.replaceAll(',', '.')) ?? 0,
        stockQuantity: double.tryParse(_stockCtrl.text.replaceAll(',', '.')) ?? 0,
        minStockLevel: double.tryParse(_minStockCtrl.text.replaceAll(',', '.')) ?? 0,
        unit: _unitCtrl.text.trim().isEmpty ? 'Adet' : _unitCtrl.text.trim(),
      );
      final api = context.read<SalonApiClient>();
      if (widget.existing == null) {
        await api.createProduct(dto);
      } else {
        await api.updateProduct(widget.existing!.id, dto);
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
        title: Text(widget.existing == null ? 'Yeni urun' : widget.existing!.name),
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
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Urun adi *')),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _categoryId,
          decoration: const InputDecoration(labelText: 'Kategori *'),
          items: [for (final c in _categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
          onChanged: (v) => setState(() => _categoryId = v),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          initialValue: _brandId,
          decoration: const InputDecoration(labelText: 'Marka (opsiyonel)'),
          items: [
            const DropdownMenuItem(value: null, child: Text('— Yok —')),
            for (final b in _brands) DropdownMenuItem(value: b.id, child: Text(b.name)),
          ],
          onChanged: (v) => setState(() => _brandId = v),
        ),
        const SizedBox(height: 8),
        TextField(controller: _barcodeCtrl, decoration: const InputDecoration(labelText: 'Barkod')),
        const SizedBox(height: 8),
        TextField(controller: _unitCtrl, decoration: const InputDecoration(labelText: 'Birim (Adet, kg, lt...)')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _purchasePriceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Alis fiyati'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _salePriceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Satis fiyati'),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _stockCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Stok miktari'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _minStockCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Min stok seviyesi'),
            ),
          ),
        ]),
        const SizedBox(height: 16),
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
