import 'package:callcenter_salonuser_mobil/models/before_after_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// `GET /api/sln-before-after` — oncesi/sonrasi foto galeri.
class BeforeAfterPage extends StatefulWidget {
  const BeforeAfterPage({super.key});

  @override
  State<BeforeAfterPage> createState() => _BeforeAfterPageState();
}

class _BeforeAfterPageState extends State<BeforeAfterPage> {
  static final _dateFmt = DateFormat('d MMM y', 'tr_TR');

  bool _loading = true;
  String? _error;
  List<BeforeAfterPhoto> _photos = const [];

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
      final list = await context.read<SalonApiClient>().fetchBeforeAfter();
      if (!mounted) return;
      setState(() { _photos = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = dioErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _create() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _BeforeAfterCreateSheet(),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _delete(BeforeAfterPhoto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Foto sil'),
        content: Text('${p.clientName} kaydi silinecek.'),
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
      await context.read<SalonApiClient>().deleteBeforeAfter(p.id);
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
        title: const Text('Oncesi/Sonrasi'),
        actions: [
          IconButton(tooltip: 'Yenile', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Yeni'),
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
    if (_photos.isEmpty) return const Center(child: Text('Foto kaydi yok.'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _photos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final p = _photos[i];
          final scheme = Theme.of(context).colorScheme;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(p.clientName, style: Theme.of(context).textTheme.titleSmall)),
                    if (p.isPublic)
                      const Chip(
                        label: Text('Galeri', style: TextStyle(fontSize: 10)),
                        avatar: Icon(Icons.public, size: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                    IconButton(
                      tooltip: 'Sil',
                      onPressed: () => _delete(p),
                      icon: Icon(Icons.delete_outline, color: scheme.error),
                    ),
                  ]),
                  Text([
                    if (p.serviceName != null) p.serviceName!,
                    if (p.personnelName != null) p.personnelName!,
                    _dateFmt.format(p.createdAt),
                  ].join(' · '),
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _PhotoBox(label: 'Once', url: p.beforePhotoUrl)),
                    const SizedBox(width: 8),
                    Expanded(child: _PhotoBox(label: 'Sonra', url: p.afterPhotoUrl)),
                  ]),
                  if (p.notes != null && p.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(p.notes!, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
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

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.label, required this.url});
  final String label;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: url == null || url!.isEmpty
            ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported_outlined, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ))
            : Stack(fit: StackFit.expand, children: [
                Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => Center(child: Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant))),
                Positioned(
                  left: 4, top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
      ),
    );
  }
}

class _BeforeAfterCreateSheet extends StatefulWidget {
  const _BeforeAfterCreateSheet();

  @override
  State<_BeforeAfterCreateSheet> createState() => _BeforeAfterCreateSheetState();
}

class _BeforeAfterCreateSheetState extends State<_BeforeAfterCreateSheet> {
  final _clientIdCtrl = TextEditingController();
  final _serviceIdCtrl = TextEditingController();
  final _personnelIdCtrl = TextEditingController();
  final _beforeCtrl = TextEditingController();
  final _afterCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isPublic = false;
  bool _saving = false;

  @override
  void dispose() {
    _clientIdCtrl.dispose();
    _serviceIdCtrl.dispose();
    _personnelIdCtrl.dispose();
    _beforeCtrl.dispose();
    _afterCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final clientId = int.tryParse(_clientIdCtrl.text);
    if (clientId == null || clientId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Musteri ID girin.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<SalonApiClient>().createBeforeAfter(BeforeAfterPhotoCreate(
            slnClientId: clientId,
            serviceId: int.tryParse(_serviceIdCtrl.text),
            personnelId: int.tryParse(_personnelIdCtrl.text),
            beforePhotoUrl: _beforeCtrl.text.trim().isEmpty ? null : _beforeCtrl.text.trim(),
            afterPhotoUrl: _afterCtrl.text.trim().isEmpty ? null : _afterCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            isPublic: _isPublic,
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
              Text('Yeni oncesi/sonrasi', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text(
                'NOT: ID alanlarini Musteriler/Hizmetler/Personel sayfalarindan kontrol edin. Foto upload mobil-da link yapistirma; cekim icin web panel.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _clientIdCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Musteri ID *'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _serviceIdCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hizmet ID'))),
              ]),
              const SizedBox(height: 8),
              TextField(controller: _personnelIdCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Personel ID')),
              const SizedBox(height: 8),
              TextField(controller: _beforeCtrl, decoration: const InputDecoration(labelText: 'Once foto URL')),
              const SizedBox(height: 8),
              TextField(controller: _afterCtrl, decoration: const InputDecoration(labelText: 'Sonra foto URL')),
              const SizedBox(height: 8),
              TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Not')),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Public galeride goster'),
                contentPadding: EdgeInsets.zero,
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
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
