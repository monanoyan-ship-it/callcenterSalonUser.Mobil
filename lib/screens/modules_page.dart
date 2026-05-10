import 'package:callcenter_salonuser_mobil/models/module_request_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// `GET /api/sln-module-requests` + `/available` — modul satin alma talepleri
/// (admin onayli) + mevcut talep edilebilir moduller.
class ModulesPage extends StatefulWidget {
  const ModulesPage({super.key});

  @override
  State<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> with SingleTickerProviderStateMixin {
  static final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  static final _dateFmt = DateFormat('d MMM y HH:mm', 'tr_TR');

  late TabController _tabs;

  bool _loading = true;
  String? _error;
  List<ModuleRequest> _requests = const [];
  List<AvailableModule> _available = const [];

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
      final reqs = await api.fetchModuleRequests();
      List<AvailableModule> avs = const [];
      try {
        avs = await api.fetchAvailableModules();
      } catch (_) {/* opsiyonel */}
      if (!mounted) return;
      setState(() {
        _requests = reqs;
        _available = avs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = dioErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _request(AvailableModule m) async {
    final notesCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${m.name} talep et'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.price != null && m.price! > 0)
              Text('Fiyat: ${_money.format(m.price)}'),
            const SizedBox(height: 8),
            TextField(controller: notesCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Talep notu (opsiyonel)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgec')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Talep gonder')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<SalonApiClient>().createModuleRequest(
            moduleId: m.id,
            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Talep gonderildi.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    }
  }

  Future<void> _cancel(ModuleRequest r) async {
    if (r.statusId != 1) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Talebi iptal et'),
        content: Text('${r.moduleName ?? "Modul"} talebi iptal edilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgec')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Iptal et'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<SalonApiClient>().cancelModuleRequest(r.id);
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
        title: const Text('Moduller'),
        bottom: TabBar(controller: _tabs, tabs: const [
          Tab(text: 'Talep edilebilir'),
          Tab(text: 'Taleplerim'),
        ]),
        actions: [
          IconButton(tooltip: 'Yenile', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
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
                    children: [_availableTab(), _requestsTab()],
                  ),
      ),
    );
  }

  Widget _availableTab() {
    if (_available.isEmpty) return const Center(child: Text('Talep edilebilir modul yok.'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _available.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final m = _available[i];
          final scheme = Theme.of(context).colorScheme;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.extension_outlined, color: scheme.onPrimaryContainer),
              ),
              title: Text(m.name),
              subtitle: m.description != null && m.description!.isNotEmpty
                  ? Text(m.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
                  : null,
              trailing: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
                if (m.price != null && m.price! > 0)
                  Text(_money.format(m.price), style: const TextStyle(fontWeight: FontWeight.w600)),
                FilledButton.tonalIcon(
                  onPressed: () => _request(m),
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text('Talep'),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _requestsTab() {
    if (_requests.isEmpty) return const Center(child: Text('Talep yok.'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final r = _requests[i];
          final scheme = Theme.of(context).colorScheme;
          Color bg;
          Color fg;
          switch (r.statusId) {
            case 1: bg = const Color(0xFFFEF3C7); fg = const Color(0xFF92400E); break;
            case 2: bg = const Color(0xFFD1FAE5); fg = const Color(0xFF065F46); break;
            case 3: bg = scheme.errorContainer; fg = scheme.onErrorContainer; break;
            default: bg = scheme.surfaceContainerHighest; fg = scheme.onSurfaceVariant;
          }
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(r.moduleName ?? '#${r.moduleId}',
                        style: Theme.of(context).textTheme.titleSmall)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                      child: Text(r.statusLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
                    ),
                  ]),
                  Text('${r.requestTypeName ?? (r.requestTypeId == 2 ? "Iptal" : "Aktivasyon")} · '
                      '${_dateFmt.format(r.requestedAt)}',
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  if (r.catalogPrice != null && r.catalogPrice! > 0)
                    Text('Fiyat: ${_money.format(r.catalogPrice)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (r.requestNotes != null && r.requestNotes!.isNotEmpty)
                    Text('Notum: ${r.requestNotes}', style: const TextStyle(fontSize: 12)),
                  if (r.adminNotes != null && r.adminNotes!.isNotEmpty)
                    Text('Admin: ${r.adminNotes}',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  if (r.statusId == 1)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _cancel(r),
                        icon: Icon(Icons.cancel_outlined, size: 18, color: scheme.error),
                        label: Text('Talebi iptal et', style: TextStyle(color: scheme.error)),
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
