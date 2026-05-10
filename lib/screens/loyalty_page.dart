import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({super.key});

  @override
  State<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends State<LoyaltyPage> {
  static final _money =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _config = {};
  List<Map<String, dynamic>> _clients = const [];

  final _pointsPerTL = TextEditingController(text: '1');
  final _pointValue = TextEditingController(text: '0.1');
  final _minRedeem = TextEditingController(text: '100');
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _pointsPerTL.dispose();
    _pointValue.dispose();
    _minRedeem.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<SalonApiClient>();
      final results = await Future.wait([
        api.getLoyaltyConfig(),
        api.getLoyaltyClients().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _config = results[0] as Map<String, dynamic>;
        _clients = results[1] as List<Map<String, dynamic>>;
        _pointsPerTL.text = ((_config['pointsPerTL'] as num?) ?? 1).toString();
        _pointValue.text = ((_config['pointValue'] as num?) ?? 0.1).toString();
        _minRedeem.text =
            ((_config['minRedeemPoints'] as num?) ?? 100).toString();
        _isActive = _config['isActive'] as bool? ?? true;
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<SalonApiClient>().saveLoyaltyConfig({
        'pointsPerTL':
            double.tryParse(_pointsPerTL.text.trim().replaceAll(',', '.')) ?? 1,
        'pointValue':
            double.tryParse(_pointValue.text.trim().replaceAll(',', '.')) ??
                0.1,
        'minRedeemPoints': int.tryParse(_minRedeem.text.trim()) ?? 100,
        'isActive': _isActive,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sadakat ayarları kaydedildi.')),
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sadakat')),
      body: ResponsiveCenter(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(
                      padding: const EdgeInsets.all(20),
                      children: [Text(_error!, textAlign: TextAlign.center)],
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
                                const Text('Sadakat ayarları',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _pointsPerTL,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                      labelText: 'Puan / TL'),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _pointValue,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                      labelText: 'Bir puanın değeri (₺)'),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _minRedeem,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: 'Min. kullanım puanı'),
                                ),
                                SwitchListTile(
                                  value: _isActive,
                                  onChanged: (v) =>
                                      setState(() => _isActive = v),
                                  title: const Text('Aktif'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                FilledButton.icon(
                                  onPressed: _saving ? null : _save,
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.save),
                                  label: Text(
                                      _saving ? 'Kaydediliyor…' : 'Kaydet'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Müşteri puanları',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        if (_clients.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Henüz puan kazanan müşteri yok.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: scheme.onSurfaceVariant),
                              ),
                            ),
                          )
                        else
                          for (final c in _clients.take(50))
                            Card(
                              child: ListTile(
                                dense: true,
                                title: Text(
                                    (c['clientName'] ?? c['fullName'] ?? '?')
                                        .toString()),
                                subtitle: Text(
                                  '${c['currentPoints'] ?? c['points'] ?? 0} puan'
                                  '${c['currentValue'] != null ? ' · ${_money.format((c['currentValue'] as num?)?.toDouble() ?? 0)}' : ''}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                      ],
                    ),
        ),
      ),
    );
  }
}
