import 'package:callcenter_salonuser_mobil/models/consent_form_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConsentFormsPage extends StatefulWidget {
  const ConsentFormsPage({super.key});

  @override
  State<ConsentFormsPage> createState() => _ConsentFormsPageState();
}

class _ConsentFormsPageState extends State<ConsentFormsPage> {
  bool _loading = true;
  String? _error;
  List<ConsentForm> _forms = const [];

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
      final list = await context.read<SalonApiClient>().fetchConsentForms();
      if (!mounted) return;
      setState(() { _forms = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = dioErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _openEditor({ConsentForm? existing}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _ConsentFormEditPage(existing: existing)),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _delete(ConsentForm f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Formu sil'),
        content: Text('${f.title} silinecek.'),
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
      await context.read<SalonApiClient>().deleteConsentForm(f.id);
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
        title: const Text('Onam Formlari'),
        actions: [
          IconButton(tooltip: 'Yenile', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni form'),
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
    if (_forms.isEmpty) return const Center(child: Text('Onam formu yok.'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _forms.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final f = _forms[i];
          final scheme = Theme.of(context).colorScheme;
          return Card(
            child: ListTile(
              leading: Icon(
                f.requireSignature ? Icons.draw_outlined : Icons.description_outlined,
                color: f.isActive ? scheme.primary : scheme.onSurfaceVariant,
              ),
              title: Text(f.title),
              subtitle: Text([
                if (f.requireSignature) 'Imza zorunlu' else 'Onay yeterli',
                '${f.signedCount} imza',
                if (!f.isActive) 'Pasif',
              ].join(' · ')),
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _openEditor(existing: f);
                  if (v == 'delete') _delete(f);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Duzenle')),
                  const PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
              ),
              onTap: () => _openEditor(existing: f),
            ),
          );
        },
      ),
    );
  }
}

class _ConsentFormEditPage extends StatefulWidget {
  const _ConsentFormEditPage({this.existing});
  final ConsentForm? existing;

  @override
  State<_ConsentFormEditPage> createState() => _ConsentFormEditPageState();
}

class _ConsentFormEditPageState extends State<_ConsentFormEditPage> {
  final _titleCtrl = TextEditingController();
  final _htmlCtrl = TextEditingController();
  bool _requireSignature = false;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _htmlCtrl.text = e.htmlContent;
      _requireSignature = e.requireSignature;
      _isActive = e.isActive;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _htmlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _htmlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Baslik ve icerik zorunlu.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final dto = ConsentFormCreate(
        title: _titleCtrl.text.trim(),
        htmlContent: _htmlCtrl.text,
        requireSignature: _requireSignature,
        isActive: _isActive,
      );
      final api = context.read<SalonApiClient>();
      if (widget.existing == null) {
        await api.createConsentForm(dto);
      } else {
        await api.updateConsentForm(widget.existing!.id, dto);
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
        title: Text(widget.existing == null ? 'Yeni form' : 'Form duzenle'),
        actions: [
          IconButton(
            tooltip: 'Kaydet',
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Baslik *')),
            const SizedBox(height: 8),
            TextField(
              controller: _htmlCtrl,
              maxLines: 14,
              decoration: const InputDecoration(
                labelText: 'HTML icerik *',
                alignLabelWithHint: true,
                helperText: 'Onam metni: HTML veya duz metin',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Imza zorunlu'),
              subtitle: const Text('Acik: musteri parmak izi/dijital imza birakir'),
              contentPadding: EdgeInsets.zero,
              value: _requireSignature,
              onChanged: (v) => setState(() => _requireSignature = v),
            ),
            SwitchListTile(
              title: const Text('Aktif'),
              contentPadding: EdgeInsets.zero,
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
