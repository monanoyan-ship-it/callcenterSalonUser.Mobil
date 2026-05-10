import 'package:callcenter_salonuser_mobil/models/marketing_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// `GET /api/sln-winback` — kayip musteri kazanim kurallari + onizleme +
/// kampanyaya donusturme.
class WinbackPage extends StatefulWidget {
  const WinbackPage({super.key});

  @override
  State<WinbackPage> createState() => _WinbackPageState();
}

class _WinbackPageState extends State<WinbackPage> {
  bool _loading = true;
  String? _error;
  List<SlnWinbackRule> _rules = const [];

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
      final list = await context.read<SalonApiClient>().fetchWinbackRules();
      if (!mounted) return;
      setState(() { _rules = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = dioErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _openEditor({SlnWinbackRule? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WinbackEditSheet(existing: existing),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _delete(SlnWinbackRule r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kurali sil'),
        content: Text('${r.name} silinecek.'),
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
      await context.read<SalonApiClient>().deleteWinbackRule(r.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kural silindi.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    }
  }

  Future<void> _toggle(SlnWinbackRule r) async {
    try {
      await context.read<SalonApiClient>().toggleWinbackRule(r.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    }
  }

  Future<void> _preview(SlnWinbackRule r) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final p = await context.read<SalonApiClient>().previewWinback(r.id);
      if (!mounted) return;
      Navigator.pop(context); // spinner
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _PreviewSheet(preview: p, rule: r, onConvert: () async {
          Navigator.pop(context);
          await _convert(r);
        }),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    }
  }

  Future<void> _convert(SlnWinbackRule r) async {
    try {
      await context.read<SalonApiClient>().winbackToCampaign(r.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Winback kampanyasi olusturuldu (Taslak).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Winback (Kayip musteri)'),
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
        label: const Text('Yeni kural'),
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
    if (_rules.isEmpty) {
      return const Center(child: Text('Winback kurali yok.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _rules.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final r = _rules[i];
          final scheme = Theme.of(context).colorScheme;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(r.name, style: Theme.of(context).textTheme.titleSmall)),
                    Switch(value: r.isActive, onChanged: (_) => _toggle(r)),
                  ]),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    Chip(
                      avatar: Icon(r.channelId == 2 ? Icons.email_outlined : Icons.sms_outlined, size: 14),
                      label: Text(r.channelLabel, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      avatar: const Icon(Icons.schedule, size: 14),
                      label: Text('${r.inactiveDays} gun pasif', style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                    ),
                    if (r.discountPercent != null)
                      Chip(
                        avatar: const Icon(Icons.percent, size: 14),
                        label: Text('%${r.discountPercent} indirim', style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                      ),
                  ]),
                  const SizedBox(height: 4),
                  Text(r.messageTemplate,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Row(children: [
                    TextButton.icon(
                      onPressed: () => _preview(r),
                      icon: const Icon(Icons.preview, size: 18),
                      label: const Text('Onizle'),
                    ),
                    TextButton.icon(
                      onPressed: () => _openEditor(existing: r),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Duzenle'),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Sil',
                      onPressed: () => _delete(r),
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
}

class _PreviewSheet extends StatelessWidget {
  const _PreviewSheet({required this.preview, required this.rule, required this.onConvert});
  final SlnWinbackPreview preview;
  final SlnWinbackRule rule;
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat('d MMM y', 'tr_TR');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(rule.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('${rule.inactiveDays} gun pasif musteri tablosu',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _Stat(label: 'Uygun', value: '${preview.eligibleClients}'),
                _Stat(label: 'SMS ulasilir', value: '${preview.smsReachableClients}'),
                _Stat(label: 'Email ulasilir', value: '${preview.emailReachableClients}'),
                _Stat(label: 'Iletisim eksik', value: '${preview.missingContactCount}'),
              ]),
              const SizedBox(height: 12),
              Card(
                color: scheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(preview.messagePreview),
                ),
              ),
              const SizedBox(height: 12),
              Text('Aday musteriler (${preview.candidates.length})',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: preview.candidates.length,
                  itemBuilder: (_, i) {
                    final c = preview.candidates[i];
                    return ListTile(
                      dense: true,
                      title: Text(c.clientName),
                      subtitle: Text([
                        if (c.phone != null && c.phone!.isNotEmpty) c.phone!,
                        if (c.email != null && c.email!.isNotEmpty) c.email!,
                        '${c.inactiveDays} gun',
                        if (c.lastVisitAt != null) 'Son ziyaret: ${fmt.format(c.lastVisitAt!)}',
                      ].join(' · ')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: preview.eligibleClients == 0 ? null : onConvert,
                icon: const Icon(Icons.send),
                label: const Text('Kampanyaya cevir (Taslak)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _WinbackEditSheet extends StatefulWidget {
  const _WinbackEditSheet({this.existing});
  final SlnWinbackRule? existing;

  @override
  State<_WinbackEditSheet> createState() => _WinbackEditSheetState();
}

class _WinbackEditSheetState extends State<_WinbackEditSheet> {
  final _nameCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: '30');
  final _messageCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  int _channelId = 1;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _daysCtrl.text = e.inactiveDays.toString();
      _messageCtrl.text = e.messageTemplate;
      _discountCtrl.text = e.discountPercent?.toString() ?? '';
      _channelId = e.channelId;
      _isActive = e.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _daysCtrl.dispose();
    _messageCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad ve mesaj zorunlu.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final dto = SlnWinbackRuleCreate(
        name: _nameCtrl.text.trim(),
        inactiveDays: int.tryParse(_daysCtrl.text) ?? 30,
        channelId: _channelId,
        messageTemplate: _messageCtrl.text.trim(),
        discountPercent: int.tryParse(_discountCtrl.text),
        isActive: _isActive,
      );
      final api = context.read<SalonApiClient>();
      if (widget.existing == null) {
        await api.createWinbackRule(dto);
      } else {
        await api.updateWinbackRule(widget.existing!.id, dto);
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
              Text(widget.existing == null ? 'Yeni kural' : widget.existing!.name,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Kural adi *')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _daysCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pasif gun *'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _discountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Indirim %'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('SMS'), icon: Icon(Icons.sms_outlined)),
                  ButtonSegment(value: 2, label: Text('Email'), icon: Icon(Icons.email_outlined)),
                ],
                selected: {_channelId},
                onSelectionChanged: (s) => setState(() => _channelId = s.first),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mesaj sablonu *',
                  helperText: '{name}, {discount} placeholderlari',
                ),
              ),
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
