import 'package:callcenter_salonuser_mobil/models/package_models.dart';
import 'package:callcenter_salonuser_mobil/models/sln_service.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// `GET /api/sln-packages/definitions` ve `/client-packages` — paket tanimlari
/// + satilan paketler iki sekme.
class PackagesPage extends StatefulWidget {
  const PackagesPage({super.key});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> with SingleTickerProviderStateMixin {
  static final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  static final _dateFmt = DateFormat('d MMM y', 'tr_TR');

  late TabController _tabs;

  bool _loading = true;
  String? _error;
  List<PackageDefinition> _defs = const [];
  List<ClientPackage> _clientPkgs = const [];
  List<SlnServiceCategory> _serviceCategories = const [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<SalonApiClient>();
      final defs = await api.fetchPackageDefinitions();
      final clients = await api.fetchClientPackages();
      final cats = await api.getServiceCategories();
      if (!mounted) return;
      setState(() {
        _defs = defs;
        _clientPkgs = clients;
        _serviceCategories = cats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = dioErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _openDefEditor({PackageDefinition? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DefEditSheet(existing: existing, categories: _serviceCategories),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _deleteDef(PackageDefinition d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paketi sil'),
        content: Text('${d.name} silinecek.'),
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
      await context.read<SalonApiClient>().deletePackageDefinition(d.id);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    }
  }

  Future<void> _useSession(ClientPackage cp) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seans kullan'),
        content: Text('${cp.clientName ?? "Musteri"} - ${cp.packageName}\n1 seans dusulecek (kalan ${cp.remainingSessions - 1}).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgec')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kullan')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<SalonApiClient>().usePackage(clientPackageId: cp.id);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paketler'),
        bottom: TabBar(controller: _tabs, tabs: const [
          Tab(text: 'Tanimlar'),
          Tab(text: 'Satilan'),
        ]),
        actions: [
          IconButton(tooltip: 'Yenile', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: _tabs.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openDefEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Yeni paket'),
            )
          : null,
      body: ResponsiveCenter(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Tekrar dene')),
                      ]),
                    ),
                  )
                : TabBarView(
                    controller: _tabs,
                    children: [_defsTab(), _clientPkgsTab()],
                  ),
      ),
    );
  }

  Widget _defsTab() {
    if (_defs.isEmpty) return const Center(child: Text('Paket tanimi yok.'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _defs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final d = _defs[i];
          final scheme = Theme.of(context).colorScheme;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(d.name, style: Theme.of(context).textTheme.titleSmall)),
                    if (!d.isActive)
                      const Chip(label: Text('Pasif', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
                  ]),
                  Text('Hizmet: ${d.serviceName}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                  Text('${d.totalSessions} seans · ${d.validDays} gun gecerli',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (d.description != null && d.description!.isNotEmpty)
                    Text(d.description!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  Row(children: [
                    Text('Toplam: ${_money.format(d.price)}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    Text('Seans: ${_money.format(d.pricePerSession)}',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Duzenle',
                      onPressed: () => _openDefEditor(existing: d),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Sil',
                      onPressed: () => _deleteDef(d),
                      icon: Icon(Icons.delete_outline, color: scheme.error),
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _clientPkgsTab() {
    if (_clientPkgs.isEmpty) return const Center(child: Text('Satilan paket yok.'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _clientPkgs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final cp = _clientPkgs[i];
          final scheme = Theme.of(context).colorScheme;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(cp.clientName ?? '-', style: Theme.of(context).textTheme.titleSmall)),
                    if (cp.isExpired)
                      Chip(
                        label: const Text('Suresi doldu', style: TextStyle(fontSize: 10)),
                        backgroundColor: scheme.errorContainer,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (!cp.isActive)
                      const Chip(label: Text('Pasif', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
                  ]),
                  Text('${cp.packageName} · ${cp.serviceName}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: cp.progress, minHeight: 6),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('${cp.usedSessions} / ${cp.totalSessions} seans · kalan ${cp.remainingSessions}',
                        style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    Text(_money.format(cp.paidAmount),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  if (cp.expiresAt != null)
                    Text('Bitis: ${_dateFmt.format(cp.expiresAt!)}',
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                  if (cp.isActive && !cp.isExpired && cp.remainingSessions > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _useSession(cp),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Seans kullan'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DefEditSheet extends StatefulWidget {
  const _DefEditSheet({this.existing, required this.categories});
  final PackageDefinition? existing;
  final List<SlnServiceCategory> categories;

  @override
  State<_DefEditSheet> createState() => _DefEditSheetState();
}

class _DefEditSheetState extends State<_DefEditSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sessionsCtrl = TextEditingController(text: '5');
  final _priceCtrl = TextEditingController(text: '0');
  final _validCtrl = TextEditingController(text: '365');
  int? _serviceId;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _descCtrl.text = e.description ?? '';
      _sessionsCtrl.text = e.totalSessions.toString();
      _priceCtrl.text = e.price.toStringAsFixed(2);
      _validCtrl.text = e.validDays.toString();
      _serviceId = e.serviceId;
      _isActive = e.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _sessionsCtrl.dispose();
    _priceCtrl.dispose();
    _validCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad ve hizmet zorunlu.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final dto = PackageDefinitionCreate(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        serviceId: _serviceId!,
        totalSessions: int.tryParse(_sessionsCtrl.text) ?? 5,
        price: double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0,
        validDays: int.tryParse(_validCtrl.text) ?? 365,
        isActive: _isActive,
      );
      final api = context.read<SalonApiClient>();
      if (widget.existing == null) {
        await api.createPackageDefinition(dto);
      } else {
        await api.updatePackageDefinition(widget.existing!.id, dto);
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
              Text(widget.existing == null ? 'Yeni paket' : widget.existing!.name,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Paket adi *')),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _serviceId,
                decoration: const InputDecoration(labelText: 'Hizmet *'),
                items: [
                  for (final cat in widget.categories.where((c) => c.isActive))
                    for (final s in cat.services.where((s) => s.isActive))
                      DropdownMenuItem(value: s.id, child: Text('${cat.name} · ${s.name}')),
                ],
                onChanged: (v) => setState(() => _serviceId = v),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _sessionsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Toplam seans *'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Toplam fiyat (TL) *'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: _validCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Gecerlilik suresi (gun)',
                  helperText: 'Satis tarihinden itibaren',
                ),
              ),
              const SizedBox(height: 8),
              TextField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Aciklama')),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Aktif'),
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 8),
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
