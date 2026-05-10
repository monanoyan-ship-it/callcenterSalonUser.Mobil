import 'package:callcenter_salonuser_mobil/models/waitlist_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// `GET /api/sln-waitlist` — bekleme listesi.
/// Yeni kayit eklemek icin SlnClient + Service secimi gerekir; mobile-da
/// olusturma yerine status guncelleme + iptal cogu kullanim icin yeterli.
class WaitlistPage extends StatefulWidget {
  const WaitlistPage({super.key});

  @override
  State<WaitlistPage> createState() => _WaitlistPageState();
}

class _WaitlistPageState extends State<WaitlistPage> {
  static final _dateFmt = DateFormat('d MMM y', 'tr_TR');

  bool _loading = true;
  String? _error;
  List<WaitlistEntry> _entries = const [];
  int? _statusFilter;

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
      final list = await context.read<SalonApiClient>().fetchWaitlist();
      if (!mounted) return;
      setState(() { _entries = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = dioErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _setStatus(WaitlistEntry e, int statusId) async {
    try {
      await context.read<SalonApiClient>().updateWaitlistStatus(e.id, statusId);
      if (!mounted) return;
      _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(err))));
    }
  }

  Future<void> _delete(WaitlistEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kaydi sil'),
        content: Text('${e.clientName} kaydi silinecek.'),
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
      await context.read<SalonApiClient>().deleteWaitlistEntry(e.id);
      if (!mounted) return;
      _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(err))));
    }
  }

  List<WaitlistEntry> get _filtered {
    if (_statusFilter == null) return _entries;
    return _entries.where((e) => e.statusId == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bekleme Listesi'),
        actions: [
          IconButton(tooltip: 'Yenile', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  _chip('Hepsi', _statusFilter == null, () => setState(() => _statusFilter = null)),
                  _chip('Bekliyor', _statusFilter == 1, () => setState(() => _statusFilter = 1)),
                  _chip('Bilgilendirildi', _statusFilter == 2, () => setState(() => _statusFilter = 2)),
                  _chip('Cevaplandi', _statusFilter == 3, () => setState(() => _statusFilter = 3)),
                  _chip('Iptal', _statusFilter == 4, () => setState(() => _statusFilter = 4)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _chip(String l, bool s, VoidCallback t) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(label: Text(l), selected: s, onSelected: (_) => t()),
      );

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
    final items = _filtered;
    if (items.isEmpty) return const Center(child: Text('Bekleyen kayit yok.'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final e = items[i];
          final scheme = Theme.of(context).colorScheme;
          Color bg;
          Color fg;
          switch (e.statusId) {
            case 1: bg = const Color(0xFFFEF3C7); fg = const Color(0xFF92400E); break;
            case 2: bg = const Color(0xFFE0E7FF); fg = const Color(0xFF3730A3); break;
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
                    Expanded(child: Text(e.clientName, style: Theme.of(context).textTheme.titleSmall)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                      child: Text(e.statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('${e.serviceName} · ${_dateFmt.format(e.preferredDate)}'
                      '${e.preferredTimeSlot != null ? ' · ${e.preferredTimeSlot}' : ''}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                  if (e.preferredPersonnelName != null && e.preferredPersonnelName!.isNotEmpty)
                    Text('Personel: ${e.preferredPersonnelName}',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (e.clientPhone != null && e.clientPhone!.isNotEmpty)
                    Text('Tel: ${e.clientPhone}',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (e.notes != null && e.notes!.isNotEmpty)
                    Text(e.notes!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  Row(children: [
                    if (e.statusId == 1)
                      TextButton.icon(
                        onPressed: () => _setStatus(e, 2),
                        icon: const Icon(Icons.notifications_active_outlined, size: 18),
                        label: const Text('Bilgilendir'),
                      ),
                    if (e.statusId == 2)
                      TextButton.icon(
                        onPressed: () => _setStatus(e, 3),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Cevaplandi'),
                      ),
                    if (e.statusId != 4)
                      TextButton.icon(
                        onPressed: () => _setStatus(e, 4),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Iptal'),
                      ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Sil',
                      onPressed: () => _delete(e),
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
