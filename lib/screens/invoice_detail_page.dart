import 'package:callcenter_salonuser_mobil/models/invoice_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// `GET /api/sln-finance/invoices/{id}` detay + iptal aksiyonu.
class InvoiceDetailPage extends StatefulWidget {
  const InvoiceDetailPage({super.key, required this.invoiceId});

  final int invoiceId;

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  static final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  static final _dateTime = DateFormat('d MMMM y, HH:mm', 'tr_TR');

  bool _loading = true;
  bool _cancelling = false;
  String? _error;
  SlnInvoice? _invoice;

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
      final inv = await context.read<SalonApiClient>().fetchInvoice(widget.invoiceId);
      if (!mounted) return;
      setState(() {
        _invoice = inv;
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

  Future<void> _cancelInvoice() async {
    final inv = _invoice;
    if (inv == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adisyonu iptal et'),
        content: Text(
            '#${inv.invoiceNo} numarali adisyonu iptal etmek istiyor musunuz? Bu islem geri alinamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgec'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Iptal et'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await context.read<SalonApiClient>().cancelInvoice(inv.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adisyon iptal edildi.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dioErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_invoice == null ? 'Adisyon' : '#${_invoice!.invoiceNo}'),
        actions: [
          if (_invoice != null && _invoice!.isOpen)
            IconButton(
              tooltip: 'Adisyonu iptal et',
              onPressed: _cancelling ? null : _cancelInvoice,
              icon: const Icon(Icons.cancel_outlined),
            ),
        ],
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
    final inv = _invoice;
    if (inv == null) return const Center(child: Text('Adisyon bulunamadi.'));
    final scheme = Theme.of(context).colorScheme;
    final subtotal = inv.totalAmount;
    final discount = inv.discountAmount;
    final tip = inv.tipAmount;
    final net = inv.netAmount;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(invoice: inv, dateFmt: _dateTime),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kalemler',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (inv.items.isEmpty)
                    Text('Kalem yok',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  for (final it in inv.items) _ItemRow(item: it, money: _money),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryRow(label: 'Ara toplam', value: _money.format(subtotal)),
                  if (discount > 0)
                    _SummaryRow(
                      label: 'Indirim',
                      value: '- ${_money.format(discount)}',
                      valueColor: scheme.error,
                    ),
                  if (tip > 0)
                    _SummaryRow(label: 'Bahsis', value: _money.format(tip)),
                  const Divider(),
                  _SummaryRow(
                    label: 'Net toplam',
                    value: _money.format(net),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          if (inv.isOpen) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Odeme akisi (P8.5) yakinda.')),
                );
              },
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Tahsilat al'),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.invoice, required this.dateFmt});

  final SlnInvoice invoice;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String label;
    Color bg;
    Color fg;
    switch (invoice.statusId) {
      case 1:
        label = 'Acik';
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
      case 2:
        label = 'Odendi';
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        break;
      case 3:
        label = 'Iptal';
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        break;
      case 4:
        label = 'Iade';
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
        break;
      default:
        label = '?';
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${invoice.invoiceNo}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(dateFmt.format(invoice.invoiceDate)),
            if (invoice.clientName != null && invoice.clientName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.person_outline, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(invoice.clientName!)),
              ]),
            ],
            if (invoice.personnelName != null && invoice.personnelName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.badge_outlined, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(invoice.personnelName!)),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.money});

  final SlnInvoiceItem item;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.w500)),
                if (item.personnelName != null && item.personnelName!.isNotEmpty)
                  Text(item.personnelName!,
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                Text(
                  '${item.quantity.toStringAsFixed(item.quantity == item.quantity.truncate() ? 0 : 2)} × ${money.format(item.unitPrice)}'
                      '${item.discountAmount > 0 ? ' (- ${money.format(item.discountAmount)})' : ''}',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(money.format(item.lineTotal),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: valueColor,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
