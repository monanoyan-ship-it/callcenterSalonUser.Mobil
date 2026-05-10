import 'package:callcenter_salonuser_mobil/models/marketing_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// `GET /api/sln-marketing/campaigns` — SMS kampanyalari.
class CampaignsPage extends StatefulWidget {
  const CampaignsPage({super.key});

  @override
  State<CampaignsPage> createState() => _CampaignsPageState();
}

class _CampaignsPageState extends State<CampaignsPage> {
  static final _dateFmt = DateFormat('d MMM y HH:mm', 'tr_TR');

  bool _loading = true;
  String? _error;
  List<SlnCampaign> _items = const [];

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
      final list = await context.read<SalonApiClient>().fetchCampaigns();
      if (!mounted) return;
      setState(() { _items = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = dioErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _openEditor({SlnCampaign? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CampaignEditSheet(existing: existing),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _delete(SlnCampaign c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kampanyayi sil'),
        content: Text('${c.name} silinecek. Devam edilsin mi?'),
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
      await context.read<SalonApiClient>().deleteCampaign(c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kampanya silindi.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    }
  }

  Future<void> _send(SlnCampaign c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kampanyayi gonder'),
        content: Text('"${c.name}" kampanyasi tum hedef musterilere gonderilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgec')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gonder'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<SalonApiClient>().sendCampaign(c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gonderim baslatildi.')));
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
        title: const Text('SMS Kampanyalari'),
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
        label: const Text('Yeni kampanya'),
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
              FilledButton(onPressed: _load, child: const Text('Tekrar dene')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Kampanya yok.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final c = _items[i];
          final scheme = Theme.of(context).colorScheme;
          Color bg;
          Color fg;
          switch (c.statusId) {
            case 1: bg = scheme.surfaceContainerHighest; fg = scheme.onSurfaceVariant; break;
            case 2: bg = const Color(0xFFFEF3C7); fg = const Color(0xFF92400E); break;
            case 3: bg = const Color(0xFFD1FAE5); fg = const Color(0xFF065F46); break;
            default: bg = scheme.errorContainer; fg = scheme.onErrorContainer;
          }
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(c.name, style: Theme.of(context).textTheme.titleSmall)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                      child: Text(c.statusLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(c.messageTemplate,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.people_outline, size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${c.sentCount} / ${c.totalRecipients} gonderildi',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    const Spacer(),
                    if (c.scheduledAt != null)
                      Text('Planli: ${_dateFmt.format(c.scheduledAt!)}',
                          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant))
                    else if (c.sentAt != null)
                      Text(_dateFmt.format(c.sentAt!),
                          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    if (c.statusId == 1 || c.statusId == 2)
                      TextButton.icon(
                        onPressed: () => _openEditor(existing: c),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Duzenle'),
                      ),
                    if (c.statusId == 1 || c.statusId == 2)
                      TextButton.icon(
                        onPressed: () => _send(c),
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Gonder'),
                      ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Sil',
                      onPressed: () => _delete(c),
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

class _CampaignEditSheet extends StatefulWidget {
  const _CampaignEditSheet({this.existing});
  final SlnCampaign? existing;

  @override
  State<_CampaignEditSheet> createState() => _CampaignEditSheetState();
}

class _CampaignEditSheetState extends State<_CampaignEditSheet> {
  final _nameCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _segmentCtrl = TextEditingController();
  DateTime? _scheduledAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _messageCtrl.text = e.messageTemplate;
      _segmentCtrl.text = e.segmentFilter ?? '';
      _scheduledAt = e.scheduledAt;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _messageCtrl.dispose();
    _segmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _scheduledAt ?? DateTime.now().add(const Duration(hours: 1)),
      locale: const Locale('tr', 'TR'),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
    );
    if (t == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
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
      final dto = SlnCampaignCreate(
        name: _nameCtrl.text.trim(),
        messageTemplate: _messageCtrl.text.trim(),
        segmentFilter: _segmentCtrl.text.trim().isEmpty ? null : _segmentCtrl.text.trim(),
        scheduledAt: _scheduledAt,
      );
      final api = context.read<SalonApiClient>();
      if (widget.existing == null) {
        await api.createCampaign(dto);
      } else {
        await api.updateCampaign(widget.existing!.id, dto);
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
              Text(widget.existing == null ? 'Yeni kampanya' : widget.existing!.name,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Kampanya adi *')),
              const SizedBox(height: 8),
              TextField(
                controller: _messageCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mesaj sablonu *',
                  helperText: '{name}, {discount} gibi placeholder kullanabilirsiniz',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _segmentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Segment filtresi (opsiyonel)',
                  helperText: 'Bos = tum musteriler. Web preset isimlerini kullanabilirsiniz.',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(_scheduledAt == null
                    ? 'Hemen (zamanlanmamis)'
                    : 'Zamanlandi: ${DateFormat('d MMM y HH:mm', 'tr_TR').format(_scheduledAt!)}'),
                trailing: Wrap(spacing: 4, children: [
                  if (_scheduledAt != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _scheduledAt = null),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_calendar),
                    onPressed: _pickSchedule,
                  ),
                ]),
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
