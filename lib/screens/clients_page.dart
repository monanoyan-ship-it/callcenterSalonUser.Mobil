import 'package:callcenter_salonuser_mobil/models/sln_client.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  static final _money =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<SlnClient> _clients = const [];

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<SalonApiClient>().getClients();
      if (!mounted) return;
      setState(() {
        _clients = list;
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

  List<SlnClient> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _clients;
    return _clients.where((c) {
      return c.fullName.toLowerCase().contains(q) ||
          (c.phone ?? '').toLowerCase().contains(q) ||
          (c.email ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openCreate() async {
    final saved = await ClientEditDialog.show(context);
    if (saved == true) _load();
  }

  Future<void> _openClient(SlnClient c) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ClientDetailPage(clientId: c.id)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteriler'),
        actions: [
          IconButton(
            tooltip: 'Yeni müşteri',
            icon: const Icon(Icons.person_add_alt),
            onPressed: _openCreate,
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Ad / telefon / e-posta ara…',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              Center(
                                child: FilledButton.icon(
                                  onPressed: _load,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Tekrar dene'),
                                ),
                              ),
                            ],
                          )
                        : _filtered.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(40),
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 56, color: scheme.onSurfaceVariant),
                                  const SizedBox(height: 12),
                                  Text(
                                    _search.text.isNotEmpty
                                        ? 'Eşleşen müşteri yok.'
                                        : 'Henüz müşteri eklenmemiş.',
                                    textAlign: TextAlign.center,
                                    style:
                                        TextStyle(color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(12, 8, 12, 24),
                                itemCount: _filtered.length,
                                separatorBuilder: (ctx, idx) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, i) {
                                  final c = _filtered[i];
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            scheme.primaryContainer,
                                        child: Text(
                                          c.fullName.isEmpty
                                              ? '?'
                                              : c.fullName.characters.first
                                                  .toUpperCase(),
                                          style: TextStyle(
                                              color:
                                                  scheme.onPrimaryContainer,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(child: Text(c.fullName)),
                                          if (c.isFavorite)
                                            const Icon(Icons.star,
                                                size: 14,
                                                color: Color(0xFFF59E0B)),
                                        ],
                                      ),
                                      subtitle: Text(
                                        [
                                          if ((c.phone ?? '').isNotEmpty) c.phone,
                                          '${c.visitCount} ziyaret · ${_money.format(c.totalSpent)}',
                                        ].whereType<String>().join(' · '),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => _openClient(c),
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────── Client detail ───────────

class ClientDetailPage extends StatefulWidget {
  const ClientDetailPage({super.key, required this.clientId});
  final int clientId;

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  static final _money =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
  static final _date = DateFormat('d MMM y', 'tr_TR');

  bool _loading = true;
  String? _error;
  bool _changed = false;
  SlnClientDetail? _client;

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
      final c = await context.read<SalonApiClient>().getClient(widget.clientId);
      if (!mounted) return;
      setState(() {
        _client = c;
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

  Future<void> _edit() async {
    final c = _client;
    if (c == null) return;
    final saved = await ClientEditDialog.show(context, existing: c);
    if (saved == true) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Müşteriyi sil'),
        content: const Text('Bu müşteri kalıcı olarak silinecek. Devam edilsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<SalonApiClient>().deleteClient(widget.clientId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dioErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = _client;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(_changed),
        ),
        title: Text(c?.fullName ?? 'Müşteri'),
        actions: [
          if (c != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _edit,
              tooltip: 'Düzenle',
            ),
          if (c != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
              tooltip: 'Sil',
            ),
        ],
      ),
      body: ResponsiveCenter(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null || c == null
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(child: Text(_error ?? 'Bulunamadı')),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.fullName,
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w700)),
                              if ((c.phone ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(c.phone!,
                                      style: TextStyle(
                                          color: scheme.onSurfaceVariant)),
                                ),
                              if ((c.email ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(c.email!,
                                      style: TextStyle(
                                          color: scheme.onSurfaceVariant)),
                                ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _StatChip(
                                      label: 'Ziyaret',
                                      value: '${c.visitCount}'),
                                  _StatChip(
                                      label: 'Harcama',
                                      value: _money.format(c.totalSpent)),
                                  if (c.lastVisit != null)
                                    _StatChip(
                                        label: 'Son ziyaret',
                                        value: _date.format(c.lastVisit!)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if ((c.notes ?? '').trim().isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Notlar',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text(c.notes!.trim()),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────── Client edit dialog ───────────

class ClientEditDialog extends StatefulWidget {
  const ClientEditDialog({super.key, this.existing});
  final SlnClientDetail? existing;

  static Future<bool?> show(BuildContext context, {SlnClientDetail? existing}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ClientEditDialog(existing: existing),
    );
  }

  @override
  State<ClientEditDialog> createState() => _ClientEditDialogState();
}

class _ClientEditDialogState extends State<ClientEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _notes;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.fullName ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final dto = SlnClientCreate(
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        notes: _notes.text.trim(),
      );
      final api = context.read<SalonApiClient>();
      if (widget.existing != null) {
        await api.updateClient(widget.existing!.id, dto,
            isFavorite: widget.existing!.isFavorite);
      } else {
        await api.createClient(dto);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = dioErrorMessage(e);
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.existing == null ? 'Yeni müşteri' : 'Müşteri düzenle'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Ad Soyad'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefon'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-posta'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Notlar', alignLabelWithHint: true),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: scheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed:
                _saving ? null : () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç')),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save),
          label: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
        ),
      ],
    );
  }
}
