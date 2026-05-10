import 'package:callcenter_salonuser_mobil/models/sln_service.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  static final _money =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

  bool _loading = true;
  String? _error;
  List<SlnServiceCategory> _categories = const [];

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
      final list = await context.read<SalonApiClient>().getServiceCategories();
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (!mounted) return;
      setState(() {
        _categories = list;
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

  Future<void> _newCategory() async {
    final saved = await CategoryEditDialog.show(context);
    if (saved == true) _load();
  }

  Future<void> _editCategory(SlnServiceCategory cat) async {
    final saved = await CategoryEditDialog.show(context, existing: cat);
    if (saved == true) _load();
  }

  Future<void> _deleteCategory(SlnServiceCategory cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategoriyi sil'),
        content: Text(
            '"${cat.name}" kategorisi ve içindeki ${cat.services.length} hizmet silinecek (backend cascade davranışına göre). Devam edilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<SalonApiClient>().deleteCategory(cat.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _newService(SlnServiceCategory cat) async {
    final saved = await ServiceEditDialog.show(context, categoryId: cat.id);
    if (saved == true) _load();
  }

  Future<void> _editService(SlnService svc) async {
    final saved = await ServiceEditDialog.show(context,
        categoryId: svc.categoryId, existing: svc);
    if (saved == true) _load();
  }

  Future<void> _deleteService(SlnService svc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hizmeti sil'),
        content: Text('"${svc.name}" silinsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<SalonApiClient>().deleteService(svc.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hizmetler'),
        actions: [
          IconButton(
            tooltip: 'Yeni kategori',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: _newCategory,
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
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
                  : _categories.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(40),
                          children: [
                            Icon(Icons.list_alt,
                                size: 56, color: scheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(
                              'Henüz hizmet kategorisi yok. Sağ üstten ekleyebilirsiniz.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                          children: [
                            for (final cat in _categories)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Card(
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      childrenPadding: EdgeInsets.zero,
                                      initiallyExpanded: true,
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              cat.name,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600),
                                            ),
                                          ),
                                          if (!cat.isActive)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: scheme
                                                    .surfaceContainerHighest,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                'Pasif',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: scheme
                                                        .onSurfaceVariant),
                                              ),
                                            ),
                                          PopupMenuButton<String>(
                                            icon:
                                                const Icon(Icons.more_vert, size: 20),
                                            onSelected: (v) {
                                              if (v == 'add') _newService(cat);
                                              if (v == 'edit') _editCategory(cat);
                                              if (v == 'del') _deleteCategory(cat);
                                            },
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(
                                                  value: 'add',
                                                  child: Text('Hizmet ekle')),
                                              PopupMenuItem(
                                                  value: 'edit',
                                                  child:
                                                      Text('Kategoriyi düzenle')),
                                              PopupMenuItem(
                                                  value: 'del',
                                                  child: Text(
                                                      'Kategoriyi sil',
                                                      style: TextStyle(
                                                          color: Colors.red))),
                                            ],
                                          ),
                                        ],
                                      ),
                                      children: [
                                        if (cat.services.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 0, 16, 12),
                                            child: Text(
                                              'Bu kategoride hizmet yok.',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: scheme
                                                      .onSurfaceVariant),
                                            ),
                                          )
                                        else
                                          for (final s in cat.services)
                                            ListTile(
                                              dense: true,
                                              title: Text(s.name),
                                              subtitle: Text(
                                                '${s.durationMinutes} dk · ${_money.format(s.price)}',
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              trailing: PopupMenuButton<String>(
                                                icon: const Icon(
                                                    Icons.more_vert,
                                                    size: 18),
                                                onSelected: (v) {
                                                  if (v == 'edit') {
                                                    _editService(s);
                                                  }
                                                  if (v == 'del') {
                                                    _deleteService(s);
                                                  }
                                                },
                                                itemBuilder: (_) => const [
                                                  PopupMenuItem(
                                                      value: 'edit',
                                                      child: Text('Düzenle')),
                                                  PopupMenuItem(
                                                      value: 'del',
                                                      child: Text('Sil',
                                                          style: TextStyle(
                                                              color: Colors.red))),
                                                ],
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
        ),
      ),
    );
  }
}

class CategoryEditDialog extends StatefulWidget {
  const CategoryEditDialog({super.key, this.existing});
  final SlnServiceCategory? existing;

  static Future<bool?> show(BuildContext context,
      {SlnServiceCategory? existing}) {
    return showDialog<bool>(
        context: context, builder: (_) => CategoryEditDialog(existing: existing));
  }

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _sort;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _sort =
        TextEditingController(text: '${widget.existing?.sortOrder ?? 0}');
  }

  @override
  void dispose() {
    _name.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'İsim zorunlu');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final dto = SlnServiceCategoryCreate(
        name: _name.text.trim(),
        sortOrder: int.tryParse(_sort.text.trim()) ?? 0,
      );
      final api = context.read<SalonApiClient>();
      if (widget.existing == null) {
        await api.createCategory(dto);
      } else {
        await api.updateCategory(widget.existing!.id, dto);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = dioErrorMessage(e);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title:
          Text(widget.existing == null ? 'Yeni kategori' : 'Kategoriyi düzenle'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'İsim')),
            const SizedBox(height: 8),
            TextField(
                controller: _sort,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sıra')),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Vazgeç')),
        FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet')),
      ],
    );
  }
}

class ServiceEditDialog extends StatefulWidget {
  const ServiceEditDialog(
      {super.key, required this.categoryId, this.existing});
  final int categoryId;
  final SlnService? existing;

  static Future<bool?> show(BuildContext context,
      {required int categoryId, SlnService? existing}) {
    return showDialog<bool>(
      context: context,
      builder: (_) =>
          ServiceEditDialog(categoryId: categoryId, existing: existing),
    );
  }

  @override
  State<ServiceEditDialog> createState() => _ServiceEditDialogState();
}

class _ServiceEditDialogState extends State<ServiceEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _duration;
  late final TextEditingController _price;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _duration = TextEditingController(
        text: '${widget.existing?.durationMinutes ?? 30}');
    _price = TextEditingController(
        text: widget.existing == null
            ? '0'
            : widget.existing!.price.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _name.dispose();
    _duration.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'İsim zorunlu');
      return;
    }
    final dur = int.tryParse(_duration.text.trim()) ?? 30;
    final price = double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final dto = SlnServiceCreate(
        categoryId: widget.categoryId,
        name: _name.text.trim(),
        durationMinutes: dur,
        price: price,
      );
      final api = context.read<SalonApiClient>();
      if (widget.existing == null) {
        await api.createService(dto);
      } else {
        await api.updateService(widget.existing!.id, dto);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = dioErrorMessage(e);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.existing == null ? 'Yeni hizmet' : 'Hizmeti düzenle'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'İsim')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                      controller: _duration,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Süre (dk)')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Fiyat ₺')),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Vazgeç')),
        FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet')),
      ],
    );
  }
}
