import 'package:callcenter_salonuser_mobil/models/inventory_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// `GET /api/sln-products/suppliers` — tedarikci CRUD.
class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  static final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  bool _loading = true;
  String? _error;
  List<SlnSupplier> _suppliers = const [];
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
      final list = await context.read<SalonApiClient>().fetchSuppliers();
      if (!mounted) return;
      setState(() {
        _suppliers = list;
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

  Future<void> _openEditor({SlnSupplier? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SupplierEditSheet(existing: existing),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _delete(SlnSupplier s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tedarikciyi sil'),
        content: Text('${s.name} silinecek. Devam edilsin mi?'),
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
      await context.read<SalonApiClient>().deleteSupplier(s.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tedarikci silindi.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    }
  }

  List<SlnSupplier> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _suppliers;
    return _suppliers.where((s) {
      return s.name.toLowerCase().contains(q) ||
          (s.contactPerson?.toLowerCase().contains(q) ?? false) ||
          (s.phone?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tedarikciler'),
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
        label: const Text('Yeni tedarikci'),
      ),
      body: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Tedarikci adi, kisi, telefon ara...',
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
      return const Center(child: Text('Tedarikci bulunamadi.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final s = items[i];
          final scheme = Theme.of(context).colorScheme;
          return Card(
            child: ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: Text(s.name),
              subtitle: Text([
                if (s.contactPerson != null && s.contactPerson!.isNotEmpty) s.contactPerson!,
                if (s.phone != null && s.phone!.isNotEmpty) s.phone!,
                if (!s.isActive) 'Pasif',
              ].join(' · ')),
              trailing: s.balance == 0
                  ? null
                  : Text(
                      _money.format(s.balance),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: s.balance < 0 ? scheme.error : null,
                      ),
                    ),
              onTap: () => _openEditor(existing: s),
              onLongPress: () => _delete(s),
            ),
          );
        },
      ),
    );
  }
}

class _SupplierEditSheet extends StatefulWidget {
  const _SupplierEditSheet({this.existing});
  final SlnSupplier? existing;

  @override
  State<_SupplierEditSheet> createState() => _SupplierEditSheetState();
}

class _SupplierEditSheetState extends State<_SupplierEditSheet> {
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _taxNoCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _contactCtrl.text = e.contactPerson ?? '';
      _phoneCtrl.text = e.phone ?? '';
      _emailCtrl.text = e.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _taxNoCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tedarikci adi zorunlu.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final dto = SlnSupplierCreate(
        name: _nameCtrl.text.trim(),
        contactPerson: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        taxNumber: _taxNoCtrl.text.trim().isEmpty ? null : _taxNoCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      final api = context.read<SalonApiClient>();
      if (widget.existing == null) {
        await api.createSupplier(dto);
      } else {
        await api.updateSupplier(widget.existing!.id, dto);
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
              Text(widget.existing == null ? 'Yeni tedarikci' : widget.existing!.name,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Firma adi *')),
              const SizedBox(height: 8),
              TextField(controller: _contactCtrl, decoration: const InputDecoration(labelText: 'Yetkili kisi')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telefon'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-posta'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              TextField(controller: _addressCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Adres')),
              const SizedBox(height: 8),
              TextField(controller: _taxNoCtrl, decoration: const InputDecoration(labelText: 'Vergi no')),
              const SizedBox(height: 8),
              TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notlar')),
              const SizedBox(height: 16),
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
