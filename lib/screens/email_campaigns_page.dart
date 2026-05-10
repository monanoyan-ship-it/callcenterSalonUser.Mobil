import 'package:callcenter_salonuser_mobil/models/marketing_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// `GET /api/sln-email-campaigns` — HTML email kampanyalari + open/click metrikleri.
class EmailCampaignsPage extends StatefulWidget {
  const EmailCampaignsPage({super.key});

  @override
  State<EmailCampaignsPage> createState() => _EmailCampaignsPageState();
}

class _EmailCampaignsPageState extends State<EmailCampaignsPage> {
  static final _dateFmt = DateFormat('d MMM y HH:mm', 'tr_TR');

  bool _loading = true;
  String? _error;
  List<SlnEmailCampaign> _items = const [];

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
      final list = await context.read<SalonApiClient>().fetchEmailCampaigns();
      if (!mounted) return;
      setState(() { _items = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = dioErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _openEditor({SlnEmailCampaign? existing}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _EmailCampaignEditPage(existing: existing)),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _delete(SlnEmailCampaign c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email kampanyasini sil'),
        content: Text('"${c.subject}" silinecek.'),
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
      await context.read<SalonApiClient>().deleteEmailCampaign(c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kampanya silindi.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    }
  }

  Future<void> _send(SlnEmailCampaign c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email kampanyasini gonder'),
        content: Text('"${c.subject}" tum hedef musterilere gonderilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgec')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gonder')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<SalonApiClient>().sendEmailCampaign(c.id);
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
        title: const Text('Email Kampanyalari'),
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
        label: const Text('Yeni email'),
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
    if (_items.isEmpty) {
      return const Center(child: Text('Email kampanyasi yok.'));
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
          final openRate = c.sentCount == 0 ? 0 : (c.openCount / c.sentCount * 100).round();
          final clickRate = c.sentCount == 0 ? 0 : (c.clickCount / c.sentCount * 100).round();
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.email_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(c.subject, style: Theme.of(context).textTheme.titleSmall, overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                      child: Text(c.statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
                    ),
                  ]),
                  if (c.isPaid || c.statusId == 3) const SizedBox(height: 4),
                  if (c.statusId == 3) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 12, children: [
                      _StatBlock(label: 'Gonderildi', value: '${c.sentCount}/${c.totalRecipients}'),
                      _StatBlock(label: 'Acildi', value: '${c.openCount} (%$openRate)'),
                      _StatBlock(label: 'Tiklandi', value: '${c.clickCount} (%$clickRate)'),
                    ]),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      c.scheduledAt != null
                          ? 'Planli: ${_dateFmt.format(c.scheduledAt!)}'
                          : 'Hemen gonderilecek',
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
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

extension on SlnEmailCampaign {
  // gerekirse ileride status hesaplari icin yer
  bool get isPaid => false;
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _EmailCampaignEditPage extends StatefulWidget {
  const _EmailCampaignEditPage({this.existing});
  final SlnEmailCampaign? existing;

  @override
  State<_EmailCampaignEditPage> createState() => _EmailCampaignEditPageState();
}

class _EmailCampaignEditPageState extends State<_EmailCampaignEditPage> {
  final _subjectCtrl = TextEditingController();
  final _htmlCtrl = TextEditingController();
  final _segmentCtrl = TextEditingController();
  DateTime? _scheduledAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _subjectCtrl.text = e.subject;
      _htmlCtrl.text = e.htmlBody;
      _segmentCtrl.text = e.segmentFilter ?? '';
      _scheduledAt = e.scheduledAt;
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _htmlCtrl.dispose();
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
    if (_subjectCtrl.text.trim().isEmpty || _htmlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konu ve HTML icerik zorunlu.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final dto = SlnEmailCampaignCreate(
        subject: _subjectCtrl.text.trim(),
        htmlBody: _htmlCtrl.text,
        segmentFilter: _segmentCtrl.text.trim().isEmpty ? null : _segmentCtrl.text.trim(),
        scheduledAt: _scheduledAt,
      );
      final api = context.read<SalonApiClient>();
      if (widget.existing == null) {
        await api.createEmailCampaign(dto);
      } else {
        await api.updateEmailCampaign(widget.existing!.id, dto);
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
        title: Text(widget.existing == null ? 'Yeni email' : 'Email duzenle'),
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
            TextField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Konu *')),
            const SizedBox(height: 8),
            TextField(
              controller: _htmlCtrl,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'HTML icerik *',
                alignLabelWithHint: true,
                helperText: 'Tam HTML yazabilirsiniz veya basit metin',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _segmentCtrl,
              decoration: const InputDecoration(
                labelText: 'Segment filtresi (opsiyonel)',
                helperText: 'Bos = tum email izinli musteriler',
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
