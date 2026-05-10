import 'package:callcenter_salonuser_mobil/models/personnel_price_models.dart';
import 'package:callcenter_salonuser_mobil/models/portal_personnel.dart';
import 'package:callcenter_salonuser_mobil/models/sln_service.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// `GET /api/sln-personnel-prices` — personel bazli hizmet fiyat overrides.
class PersonnelPricesPage extends StatefulWidget {
  const PersonnelPricesPage({super.key});

  @override
  State<PersonnelPricesPage> createState() => _PersonnelPricesPageState();
}

class _PersonnelPricesPageState extends State<PersonnelPricesPage> {
  static final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  bool _loading = true;
  String? _error;
  List<PersonnelServicePrice> _prices = const [];
  List<PortalPersonnel> _personnel = const [];
  List<SlnServiceCategory> _serviceCategories = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<SalonApiClient>();
      final prices = await api.fetchPersonnelPrices();
      final pers = await api.getPersonnel();
      final cats = await api.getServiceCategories();
      if (!mounted) return;
      setState(() {
        _prices = prices;
        _personnel = pers;
        _serviceCategories = cats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = dioErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _add() async {
    if (_personnel.isEmpty || _serviceCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personel ve hizmet listesi gerekli.')),
      );
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PriceAddSheet(personnel: _personnel, categories: _serviceCategories),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _delete(PersonnelServicePrice p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Override sil'),
        content: Text('${p.personnelName} - ${p.serviceName} fiyat overrides silinecek.'),
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
      await context.read<SalonApiClient>().deletePersonnelPrice(p.id);
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
        title: const Text('Personel Fiyat Override'),
        actions: [
          IconButton(tooltip: 'Yenile', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Yeni override'),
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Tekrar dene')),
          ]),
        ),
      );
    }
    if (_prices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Henuz personel-hizmet ozel fiyati yok.\n'
            'Default hizmet fiyati gecerlidir.\n'
            'Personel uzmanlik veya senior tariffi icin override ekleyin.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _prices.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final p = _prices[i];
          final scheme = Theme.of(context).colorScheme;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Text(p.personnelName.isNotEmpty ? p.personnelName[0] : '?',
                    style: TextStyle(color: scheme.onPrimaryContainer)),
              ),
              title: Text(p.personnelName),
              subtitle: Text(p.serviceName),
              trailing: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(_money.format(p.price),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                IconButton(
                  tooltip: 'Sil',
                  onPressed: () => _delete(p),
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _PriceAddSheet extends StatefulWidget {
  const _PriceAddSheet({required this.personnel, required this.categories});
  final List<PortalPersonnel> personnel;
  final List<SlnServiceCategory> categories;

  @override
  State<_PriceAddSheet> createState() => _PriceAddSheetState();
}

class _PriceAddSheetState extends State<_PriceAddSheet> {
  int? _personnelId;
  int? _serviceId;
  final _priceCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_personnelId == null || _serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Personel ve hizmet secin.')));
      return;
    }
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tutar girin.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<SalonApiClient>().createPersonnelPrice(PersonnelServicePriceCreate(
            personnelId: _personnelId!,
            serviceId: _serviceId!,
            price: price,
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
              Text('Yeni override', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _personnelId,
                decoration: const InputDecoration(labelText: 'Personel *'),
                items: [
                  for (final p in widget.personnel.where((p) => p.isActive))
                    DropdownMenuItem(value: p.id, child: Text(p.title)),
                ],
                onChanged: (v) => setState(() => _personnelId = v),
              ),
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
              TextField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Ozel fiyat (TL) *',
                  helperText: 'Default hizmet fiyatinin uzerine yazilir',
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
