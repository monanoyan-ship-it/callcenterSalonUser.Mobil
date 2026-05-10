import 'package:callcenter_salonuser_mobil/models/marketing_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// `GET /api/sln-gift-cards` — hediye kart liste / yeni / deactivate.
class GiftCardsPage extends StatefulWidget {
  const GiftCardsPage({super.key});

  @override
  State<GiftCardsPage> createState() => _GiftCardsPageState();
}

class _GiftCardsPageState extends State<GiftCardsPage> {
  static final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  static final _dateFmt = DateFormat('d MMM y', 'tr_TR');

  bool _loading = true;
  String? _error;
  List<SlnGiftCard> _cards = const [];
  String _query = '';
  int _statusFilter = 0; // 0=Hepsi, 1=Aktif kullanilabilir, 2=Pasif/biten

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
      final list = await context.read<SalonApiClient>().fetchGiftCards();
      if (!mounted) return;
      setState(() { _cards = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = dioErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _create() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _GiftCardCreateSheet(),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _deactivate(SlnGiftCard c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hediye karti pasiflestir'),
        content: Text('${c.code} kodlu kart pasiflestirilsin mi? Bu islem geri alinamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgec')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Pasiflestir'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<SalonApiClient>().deactivateGiftCard(c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Karti pasiflestirildi.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
    }
  }

  List<SlnGiftCard> get _filtered {
    final q = _query.trim().toLowerCase();
    return _cards.where((c) {
      if (_statusFilter == 1 && (!c.isActive || c.isExpired || c.isUsedUp)) return false;
      if (_statusFilter == 2 && (c.isActive && !c.isExpired && !c.isUsedUp)) return false;
      if (q.isEmpty) return true;
      return c.code.toLowerCase().contains(q) ||
          (c.recipientName?.toLowerCase().contains(q) ?? false) ||
          (c.recipientPhone?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hediye Kartlari'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Yeni kart'),
      ),
      body: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Kod, alici adi/telefon ara...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip('Hepsi', _statusFilter == 0, () => setState(() => _statusFilter = 0)),
                  _chip('Kullanilabilir', _statusFilter == 1, () => setState(() => _statusFilter = 1)),
                  _chip('Pasif/biten', _statusFilter == 2, () => setState(() => _statusFilter = 2)),
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

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
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
    final items = _filtered;
    if (items.isEmpty) {
      return const Center(child: Text('Hediye karti yok.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final c = items[i];
          final scheme = Theme.of(context).colorScheme;
          final usable = c.isActive && !c.isExpired && !c.isUsedUp;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.card_giftcard, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(c.code,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    IconButton(
                      tooltip: 'Kodu kopyala',
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: c.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kod kopyalandi.')),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    Text(_money.format(c.remainingBalance),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: usable ? const Color(0xFF065F46) : scheme.onSurfaceVariant)),
                    Text('/ ${_money.format(c.originalAmount)}',
                        style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
                    if (!c.isActive)
                      const Chip(label: Text('Pasif', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
                    if (c.isExpired)
                      Chip(
                        label: const Text('Suresi doldu', style: TextStyle(fontSize: 10)),
                        backgroundColor: scheme.errorContainer,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (c.isUsedUp)
                      const Chip(label: Text('Bitti', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
                  ]),
                  const SizedBox(height: 4),
                  if (c.recipientName != null && c.recipientName!.isNotEmpty)
                    Text('Alici: ${c.recipientName}${c.recipientPhone != null ? ' · ${c.recipientPhone}' : ''}',
                        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                  if (c.message != null && c.message!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('"${c.message}"',
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                    ),
                  if (c.expiresAt != null)
                    Text('Son kullanim: ${_dateFmt.format(c.expiresAt!)}',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  if (c.isActive)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _deactivate(c),
                        icon: Icon(Icons.cancel_outlined, size: 18, color: scheme.error),
                        label: Text('Pasiflestir', style: TextStyle(color: scheme.error)),
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

class _GiftCardCreateSheet extends StatefulWidget {
  const _GiftCardCreateSheet();

  @override
  State<_GiftCardCreateSheet> createState() => _GiftCardCreateSheetState();
}

class _GiftCardCreateSheetState extends State<_GiftCardCreateSheet> {
  final _amountCtrl = TextEditingController();
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _senderCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  int _paymentMethodId = 1;
  DateTime? _expiresAt;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _senderCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );
    if (d != null && mounted) setState(() => _expiresAt = d);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tutar girin.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final dto = SlnGiftCardCreate(
        amount: amount,
        paymentMethodId: _paymentMethodId,
        recipientName: _recipientNameCtrl.text.trim().isEmpty ? null : _recipientNameCtrl.text.trim(),
        recipientPhone: _recipientPhoneCtrl.text.trim().isEmpty ? null : _recipientPhoneCtrl.text.trim(),
        senderName: _senderCtrl.text.trim().isEmpty ? null : _senderCtrl.text.trim(),
        message: _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
        expiresAt: _expiresAt,
      );
      final created = await context.read<SalonApiClient>().createGiftCard(dto);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hediye karti olusturuldu: ${created.code}')),
      );
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
              Text('Yeni hediye karti', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Tutar (TL) *'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _paymentMethodId,
                decoration: const InputDecoration(labelText: 'Odeme tipi'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Nakit')),
                  DropdownMenuItem(value: 2, child: Text('Kredi Karti')),
                  DropdownMenuItem(value: 3, child: Text('Havale/EFT')),
                ],
                onChanged: (v) => setState(() => _paymentMethodId = v ?? 1),
              ),
              const SizedBox(height: 8),
              TextField(controller: _recipientNameCtrl, decoration: const InputDecoration(labelText: 'Alici adi')),
              const SizedBox(height: 8),
              TextField(
                controller: _recipientPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Alici telefon'),
              ),
              const SizedBox(height: 8),
              TextField(controller: _senderCtrl, decoration: const InputDecoration(labelText: 'Gonderen')),
              const SizedBox(height: 8),
              TextField(controller: _messageCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Mesaj')),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(_expiresAt == null
                    ? 'Son kullanim tarihi yok'
                    : 'Son kullanim: ${DateFormat('d MMM y', 'tr_TR').format(_expiresAt!)}'),
                trailing: Wrap(spacing: 4, children: [
                  if (_expiresAt != null)
                    IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _expiresAt = null)),
                  IconButton(icon: const Icon(Icons.edit_calendar), onPressed: _pickExpiry),
                ]),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: const Text('Olustur'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
