import 'package:callcenter_salonuser_mobil/models/sln_membership.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MembershipsPage extends StatelessWidget {
  const MembershipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Üyelikler'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Planlar'),
            Tab(text: 'Aboneler'),
          ]),
        ),
        body: const ResponsiveCenter(
          child: TabBarView(children: [_PlansTab(), _ClientMembershipsTab()]),
        ),
      ),
    );
  }
}

// ─────────── Plans tab ───────────

class _PlansTab extends StatefulWidget {
  const _PlansTab();
  @override
  State<_PlansTab> createState() => _PlansTabState();
}

class _PlansTabState extends State<_PlansTab> {
  static final _money =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

  bool _loading = true;
  String? _error;
  List<SlnMembershipPlan> _plans = const [];

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
      final list = await context.read<SalonApiClient>().getMembershipPlans();
      if (!mounted) return;
      setState(() {
        _plans = list;
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

  Future<void> _new() async {
    final saved = await PlanEditDialog.show(context);
    if (saved == true) _load();
  }

  Future<void> _edit(SlnMembershipPlan p) async {
    final saved = await PlanEditDialog.show(context, existing: p);
    if (saved == true) _load();
  }

  Future<void> _delete(SlnMembershipPlan p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Planı sil'),
        content: Text('"${p.name}" planı silinsin mi? Aktif üyeler varsa backend reddedebilir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<SalonApiClient>().deleteMembershipPlan(p.id);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(padding: const EdgeInsets.all(20), children: [Text(_error!)])
                  : _plans.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(40),
                          children: [
                            Icon(Icons.workspace_premium_outlined,
                                size: 56, color: scheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(
                              'Henüz üyelik planı yok.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                          itemCount: _plans.length,
                          separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final p = _plans[i];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: scheme.primaryContainer,
                                  child: const Icon(Icons.workspace_premium_outlined,
                                      size: 18),
                                ),
                                title: Text(p.name),
                                subtitle: Text(
                                  '${_money.format(p.price)} · ${p.durationDays} gün · '
                                  '%${p.discountPercent} indirim · ${p.activeMembers} üye',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _edit(p);
                                    if (v == 'del') _delete(p);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                    PopupMenuItem(
                                        value: 'del',
                                        child: Text('Sil', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _new,
            icon: const Icon(Icons.add),
            label: const Text('Yeni plan'),
          ),
        ),
      ],
    );
  }
}

// ─────────── Client memberships tab ───────────

class _ClientMembershipsTab extends StatefulWidget {
  const _ClientMembershipsTab();
  @override
  State<_ClientMembershipsTab> createState() => _ClientMembershipsTabState();
}

class _ClientMembershipsTabState extends State<_ClientMembershipsTab> {
  static final _money =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
  static final _date = DateFormat('d MMM y', 'tr_TR');

  bool _loading = true;
  String? _error;
  List<SlnClientMembership> _items = const [];

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
      final list = await context.read<SalonApiClient>().getClientMemberships();
      if (!mounted) return;
      setState(() {
        _items = list;
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

  Future<void> _action(SlnClientMembership m, Future<void> Function() fn,
      String successMsg) async {
    try {
      await fn();
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(padding: const EdgeInsets.all(20), children: [Text(_error!)])
              : _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(40),
                      children: [
                        Icon(Icons.people_outline,
                            size: 56, color: scheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          'Aktif üyelik yok.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      itemCount: _items.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final m = _items[i];
                        Color statusBg;
                        Color statusFg;
                        if (m.isActive) {
                          statusBg = const Color(0xFFD1FAE5);
                          statusFg = const Color(0xFF065F46);
                        } else if (m.isFrozen) {
                          statusBg = const Color(0xFFFEF3C7);
                          statusFg = const Color(0xFF92400E);
                        } else {
                          statusBg = scheme.errorContainer;
                          statusFg = scheme.onErrorContainer;
                        }
                        final api = context.read<SalonApiClient>();
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(m.clientName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(m.statusLabel,
                                          style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: statusFg)),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '${m.planName} · %${m.discountPercent} · ödeme ${_money.format(m.paidAmount)}',
                                    style: TextStyle(
                                        fontSize: 12, color: scheme.onSurfaceVariant),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Başlangıç ${_date.format(m.startDate)}'
                                    '${m.endDate != null ? ' · Bitiş ${_date.format(m.endDate!)}' : ''}',
                                    style: TextStyle(
                                        fontSize: 12, color: scheme.onSurfaceVariant),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    if (m.isActive)
                                      OutlinedButton.icon(
                                        onPressed: () => _action(m,
                                            () => api.freezeClientMembership(m.id),
                                            'Üyelik donduruldu.'),
                                        icon: const Icon(Icons.pause, size: 16),
                                        label: const Text('Dondur'),
                                      ),
                                    if (m.isFrozen)
                                      FilledButton.icon(
                                        onPressed: () => _action(m,
                                            () => api.reactivateClientMembership(m.id),
                                            'Üyelik aktifleştirildi.'),
                                        icon: const Icon(Icons.play_arrow, size: 16),
                                        label: const Text('Aktifleştir'),
                                      ),
                                    if (m.isActive || m.isFrozen)
                                      OutlinedButton.icon(
                                        onPressed: () => _action(m,
                                            () => api.cancelClientMembership(m.id),
                                            'Üyelik iptal edildi.'),
                                        icon: const Icon(Icons.close, size: 16),
                                        label: const Text('İptal'),
                                        style: OutlinedButton.styleFrom(
                                            foregroundColor: scheme.error,
                                            side: BorderSide(
                                                color: scheme.error
                                                    .withValues(alpha: 0.5))),
                                      ),
                                  ],
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

// ─────────── Plan edit dialog ───────────

class PlanEditDialog extends StatefulWidget {
  const PlanEditDialog({super.key, this.existing});
  final SlnMembershipPlan? existing;

  static Future<bool?> show(BuildContext context, {SlnMembershipPlan? existing}) {
    return showDialog<bool>(
        context: context, builder: (_) => PlanEditDialog(existing: existing));
  }

  @override
  State<PlanEditDialog> createState() => _PlanEditDialogState();
}

class _PlanEditDialogState extends State<PlanEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _days;
  late final TextEditingController _price;
  late final TextEditingController _discount;
  late bool _priority;
  late bool _isActive;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _days = TextEditingController(text: '${e?.durationDays ?? 30}');
    _price = TextEditingController(text: e?.price.toStringAsFixed(0) ?? '0');
    _discount = TextEditingController(text: '${e?.discountPercent ?? 0}');
    _priority = e?.priorityBooking ?? false;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _days.dispose();
    _price.dispose();
    _discount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'İsim zorunlu');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final dto = SlnMembershipPlanCreate(
        name: _name.text.trim(),
        description: _description.text.trim(),
        durationDays: int.tryParse(_days.text.trim()) ?? 30,
        price: double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0,
        discountPercent: int.tryParse(_discount.text.trim()) ?? 0,
        priorityBooking: _priority,
        isActive: _isActive,
      );
      final api = context.read<SalonApiClient>();
      if (widget.existing == null) {
        await api.createMembershipPlan(dto);
      } else {
        await api.updateMembershipPlan(widget.existing!.id, dto);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = dioErrorMessage(e);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.existing == null ? 'Yeni plan' : 'Planı düzenle'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'İsim')),
              const SizedBox(height: 8),
              TextField(
                  controller: _description,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Açıklama')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                        controller: _days,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Süre (gün)')),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Fiyat ₺')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: _discount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'İndirim %')),
              SwitchListTile(
                  value: _priority,
                  onChanged: (v) => setState(() => _priority = v),
                  title: const Text('Öncelikli randevu'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact),
              SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Aktif'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact),
              if (_error != null) Text(_error!, style: TextStyle(color: scheme.error)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Vazgeç')),
        FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet')),
      ],
    );
  }
}
