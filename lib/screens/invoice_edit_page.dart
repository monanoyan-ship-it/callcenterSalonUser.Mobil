import 'package:callcenter_salonuser_mobil/models/invoice_models.dart';
import 'package:callcenter_salonuser_mobil/models/portal_personnel.dart';
import 'package:callcenter_salonuser_mobil/models/sln_client.dart';
import 'package:callcenter_salonuser_mobil/models/sln_service.dart';
import 'package:callcenter_salonuser_mobil/screens/invoice_detail_page.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Yeni adisyon olusturma. Musteri arama (autocomplete), hizmet kalemi ekle (kategori
/// drill-down), indirim/bahsis/notlar, odeme tipi sec, kaydet → InvoiceDetailPage.
/// Web Sales/Index.cshtml + Sales.js paralel.
class InvoiceEditPage extends StatefulWidget {
  const InvoiceEditPage({super.key});

  @override
  State<InvoiceEditPage> createState() => _InvoiceEditPageState();
}

class _InvoiceEditPageState extends State<InvoiceEditPage> {
  static final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  bool _bootstrapping = true;
  bool _saving = false;
  String? _error;

  List<SlnServiceCategory> _categories = const [];
  List<PortalPersonnel> _personnel = const [];

  SlnClient? _client;
  final _items = <_DraftItem>[];
  final _discountCtrl = TextEditingController(text: '0');
  final _tipCtrl = TextEditingController(text: '0');
  bool _includeTipInTotal = false;
  final _notesCtrl = TextEditingController();
  InvoicePaymentMethod _paymentMethod = InvoicePaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bootstrap();
    });
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _tipCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _bootstrapping = true;
      _error = null;
    });
    try {
      final api = context.read<SalonApiClient>();
      final cats = await api.getServiceCategories();
      final pers = await api.getPersonnel();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _personnel = pers;
        _bootstrapping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = dioErrorMessage(e);
        _bootstrapping = false;
      });
    }
  }

  double get _itemsSubtotal => _items.fold(0, (sum, i) {
        final lineGross = i.unitPrice * i.quantity;
        return sum + (lineGross - i.discountAmount);
      });

  double get _invoiceDiscount => double.tryParse(_discountCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _tip => double.tryParse(_tipCtrl.text.replaceAll(',', '.')) ?? 0;

  double get _net {
    final subtotalAfterDiscount = (_itemsSubtotal - _invoiceDiscount).clamp(0, double.infinity);
    return subtotalAfterDiscount + (_includeTipInTotal ? _tip : 0);
  }

  Future<void> _pickClient() async {
    final picked = await showModalBottomSheet<SlnClient>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ClientPickerSheet(),
    );
    if (picked != null && mounted) setState(() => _client = picked);
  }

  Future<void> _addItem() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Henuz hizmet tanimli degil.')),
      );
      return;
    }
    final draft = await showModalBottomSheet<_DraftItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemPickerSheet(
        categories: _categories,
        personnel: _personnel,
      ),
    );
    if (draft != null && mounted) setState(() => _items.add(draft));
  }

  Future<void> _save() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir kalem ekleyin.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final dto = SlnInvoiceCreate(
        slnClientId: _client?.id,
        paymentMethodId: _paymentMethod.id,
        discountAmount: _invoiceDiscount,
        tipAmount: _tip,
        includeTipInTotal: _includeTipInTotal,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        items: _items
            .map((i) => SlnInvoiceItemCreate(
                  serviceId: i.serviceId,
                  personnelId: i.personnelId,
                  quantity: i.quantity,
                  unitPrice: i.unitPrice,
                  discountAmount: i.discountAmount,
                ))
            .toList(),
      );
      final created = await context.read<SalonApiClient>().createInvoice(dto);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adisyon olusturuldu: #${created.invoiceNo}')),
      );
      Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute(
          builder: (_) => InvoiceDetailPage(invoiceId: created.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dioErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Adisyon')),
      body: ResponsiveCenter(child: _body()),
      bottomNavigationBar: _bootstrapping || _error != null ? null : _Footer(
        net: _money.format(_net),
        saving: _saving,
        onSave: _save,
      ),
    );
  }

  Widget _body() {
    if (_bootstrapping) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              const SizedBox(height: 12),
              FilledButton(onPressed: _bootstrap, child: const Text('Tekrar dene')),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(_client?.fullName ?? 'Musteri sec (opsiyonel)'),
            subtitle: (_client?.phone != null && _client!.phone!.isNotEmpty)
                ? Text(_client!.phone!)
                : null,
            trailing: _client == null
                ? const Icon(Icons.add)
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _client = null),
                  ),
            onTap: _pickClient,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text('Kalemler', style: Theme.of(context).textTheme.titleSmall),
            ),
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Hizmet ekle'),
            ),
          ],
        ),
        if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Henuz kalem yok.'),
          ),
        for (var i = 0; i < _items.length; i++)
          Card(
            child: ListTile(
              title: Text(_items[i].serviceName),
              subtitle: Text(
                '${_items[i].quantity.toStringAsFixed(_items[i].quantity == _items[i].quantity.truncate() ? 0 : 2)} × ${_money.format(_items[i].unitPrice)}'
                '${_items[i].discountAmount > 0 ? ' (- ${_money.format(_items[i].discountAmount)})' : ''}'
                '${_items[i].personnelName != null ? '\n${_items[i].personnelName}' : ''}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => _items.removeAt(i)),
              ),
              isThreeLine: _items[i].personnelName != null,
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _discountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Adisyon indirimi (TL)',
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _tipCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Bahsis (TL)',
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Bahsisi topla'),
              value: _includeTipInTotal,
              onChanged: (v) => setState(() => _includeTipInTotal = v),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        DropdownButtonFormField<InvoicePaymentMethod>(
          initialValue: _paymentMethod,
          decoration: const InputDecoration(
            labelText: 'Odeme tipi',
            isDense: true,
          ),
          items: [
            for (final m in InvoicePaymentMethod.values)
              DropdownMenuItem(value: m, child: Text(m.label)),
          ],
          onChanged: (v) => setState(() => _paymentMethod = v ?? InvoicePaymentMethod.cash),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notlar',
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _row('Ara toplam', _money.format(_itemsSubtotal)),
                if (_invoiceDiscount > 0)
                  _row('Indirim', '- ${_money.format(_invoiceDiscount)}'),
                if (_includeTipInTotal && _tip > 0)
                  _row('Bahsis', _money.format(_tip)),
                const Divider(),
                _row('Net toplam', _money.format(_net), bold: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ]),
    );
  }
}

class _DraftItem {
  _DraftItem({
    required this.serviceId,
    required this.serviceName,
    required this.unitPrice,
    this.quantity = 1,
    this.discountAmount = 0,
    this.personnelId,
    this.personnelName,
  });

  final int serviceId;
  final String serviceName;
  final double unitPrice;
  final double quantity;
  final double discountAmount;
  final int? personnelId;
  final String? personnelName;
}

class _Footer extends StatelessWidget {
  const _Footer({required this.net, required this.saving, required this.onSave});
  final String net;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Net toplam', style: Theme.of(context).textTheme.bodySmall),
              Text(net, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    height: 16, width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: const Text('Kaydet'),
          ),
        ]),
      ),
    );
  }
}

// ─────────── Client picker ───────────

class _ClientPickerSheet extends StatefulWidget {
  const _ClientPickerSheet();

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  final _searchCtrl = TextEditingController();
  bool _loading = false;
  List<SlnClient> _results = const [];

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final list = await context.read<SalonApiClient>().getClients(search: q);
      if (!mounted) return;
      setState(() {
        _results = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              const Expanded(child: Text('Musteri sec')),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ad veya telefon ara...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final c = _results[i];
                        return ListTile(
                          title: Text(c.fullName),
                          subtitle: Text(c.phone ?? ''),
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────── Item picker ───────────

class _ItemPickerSheet extends StatefulWidget {
  const _ItemPickerSheet({required this.categories, required this.personnel});
  final List<SlnServiceCategory> categories;
  final List<PortalPersonnel> personnel;

  @override
  State<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<_ItemPickerSheet> {
  static final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  SlnService? _service;
  PortalPersonnel? _personnelSelected;
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController(text: '0');
  final _discountCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  void _selectService(SlnService s) {
    setState(() {
      _service = s;
      _priceCtrl.text = s.price.toStringAsFixed(2);
    });
  }

  void _confirm() {
    final s = _service;
    if (s == null) return;
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 1;
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? s.price;
    final discount = double.tryParse(_discountCtrl.text.replaceAll(',', '.')) ?? 0;
    Navigator.pop(
      context,
      _DraftItem(
        serviceId: s.id,
        serviceName: s.name,
        unitPrice: price,
        quantity: qty,
        discountAmount: discount,
        personnelId: _personnelSelected?.id,
        personnelName: _personnelSelected?.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              const Expanded(child: Text('Hizmet ekle')),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            if (_service == null)
              Expanded(
                child: ListView(
                  children: [
                    for (final cat in widget.categories.where((c) => c.isActive))
                      ExpansionTile(
                        title: Text(cat.name),
                        children: [
                          for (final s in cat.services.where((s) => s.isActive))
                            ListTile(
                              title: Text(s.name),
                              subtitle: Text('${s.durationMinutes} dk'),
                              trailing: Text(_money.format(s.price)),
                              onTap: () => _selectService(s),
                            ),
                        ],
                      ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView(children: [
                  ListTile(
                    leading: const Icon(Icons.spa_outlined),
                    title: Text(_service!.name),
                    subtitle: Text(_service!.categoryName),
                    trailing: TextButton(
                      onPressed: () => setState(() => _service = null),
                      child: const Text('Degistir'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Adet'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Birim fiyat (TL)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _discountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Kalem indirimi (TL)'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PortalPersonnel?>(
                    initialValue: _personnelSelected,
                    decoration: const InputDecoration(labelText: 'Personel (opsiyonel)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— Yok —')),
                      for (final p in widget.personnel)
                        DropdownMenuItem(value: p, child: Text(p.title)),
                    ],
                    onChanged: (v) => setState(() => _personnelSelected = v),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _confirm,
                    icon: const Icon(Icons.check),
                    label: const Text('Ekle'),
                  ),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}
