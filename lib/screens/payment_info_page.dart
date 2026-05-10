import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// iyzico Pazaryeri sub-merchant onboarding (PS.5). Owner-only.
class PaymentInfoPage extends StatefulWidget {
  const PaymentInfoPage({super.key});

  @override
  State<PaymentInfoPage> createState() => _PaymentInfoPageState();
}

class _PaymentInfoPageState extends State<PaymentInfoPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic> _info = {};

  /// PERSONAL / PRIVATE_COMPANY / LIMITED_OR_JOINT_STOCK_COMPANY
  String _type = 'PERSONAL';
  final _iban = TextEditingController();
  final _contactName = TextEditingController();
  final _contactSurname = TextEditingController();
  final _identityNumber = TextEditingController();
  final _legalCompanyTitle = TextEditingController();
  final _taxOffice = TextEditingController();
  final _taxNumber = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _iban.dispose();
    _contactName.dispose();
    _contactSurname.dispose();
    _identityNumber.dispose();
    _legalCompanyTitle.dispose();
    _taxOffice.dispose();
    _taxNumber.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await context.read<SalonApiClient>().getPaymentInfo();
      if (!mounted) return;
      setState(() {
        _info = info;
        _type = (info['subMerchantType'] as String?) ?? 'PERSONAL';
        _iban.text = (info['iban'] as String?) ?? '';
        _contactName.text = (info['contactName'] as String?) ?? '';
        _contactSurname.text = (info['contactSurname'] as String?) ?? '';
        _identityNumber.text = (info['identityNumber'] as String?) ?? '';
        _legalCompanyTitle.text = (info['legalCompanyTitle'] as String?) ?? '';
        _taxOffice.text = (info['taxOffice'] as String?) ?? '';
        _taxNumber.text = (info['taxNumber'] as String?) ?? '';
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

  Future<void> _submit() async {
    if (_iban.text.trim().length < 26) {
      setState(() => _error = 'Geçerli bir TR IBAN girin (TR + 24 hane).');
      return;
    }
    if (_contactName.text.trim().isEmpty || _contactSurname.text.trim().isEmpty) {
      setState(() => _error = 'Yetkili ad ve soyad zorunlu.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<SalonApiClient>().submitSubMerchant({
        'subMerchantType': _type,
        'iban': _iban.text.trim(),
        'contactName': _contactName.text.trim(),
        'contactSurname': _contactSurname.text.trim(),
        if (_type == 'PERSONAL') 'identityNumber': _identityNumber.text.trim(),
        if (_type != 'PERSONAL') ...{
          'legalCompanyTitle': _legalCompanyTitle.text.trim(),
          'taxOffice': _taxOffice.text.trim(),
          'taxNumber': _taxNumber.text.trim(),
        },
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onboarding başvurusu gönderildi.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = dioErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ({String label, Color bg, Color fg}) get _statusInfo {
    final s = (_info['onboardingStatus'] as num?)?.toInt() ?? 0;
    switch (s) {
      case 0:
        return (label: 'Henüz başlatılmadı', bg: const Color(0xFFE5E7EB), fg: const Color(0xFF374151));
      case 1:
        return (label: 'Onay bekliyor', bg: const Color(0xFFFEF3C7), fg: const Color(0xFF92400E));
      case 2:
        return (label: 'Onaylandı', bg: const Color(0xFFD1FAE5), fg: const Color(0xFF065F46));
      case 3:
        return (label: 'Reddedildi', bg: const Color(0xFFFEE2E2), fg: const Color(0xFF991B1B));
      default:
        return (label: 'Bilinmiyor', bg: const Color(0xFFE5E7EB), fg: const Color(0xFF374151));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = _statusInfo;
    final commission = (_info['commissionPercent'] as num?)?.toDouble() ?? 5.0;
    final withholding = (_info['withholdingPercent'] as num?)?.toDouble() ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme Bilgileri')),
      body: ResponsiveCenter(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Text('Onboarding durumu',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: status.bg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(status.label,
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: status.fg)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            'Komisyon: %${commission.toStringAsFixed(1)} · Stopaj: %${withholding.toStringAsFixed(1)}',
                            style: TextStyle(
                                fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                          if ((_info['onboardingError'] as String?)?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              _info['onboardingError'] as String,
                              style: TextStyle(
                                  fontSize: 12, color: scheme.error),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hesap tipi',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: _type,
                            items: const [
                              DropdownMenuItem(
                                  value: 'PERSONAL', child: Text('Bireysel')),
                              DropdownMenuItem(
                                  value: 'PRIVATE_COMPANY',
                                  child: Text('Şahıs şirketi')),
                              DropdownMenuItem(
                                  value: 'LIMITED_OR_JOINT_STOCK_COMPANY',
                                  child: Text('Limited / A.Ş.')),
                            ],
                            onChanged: (v) => setState(() => _type = v ?? _type),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _iban,
                            decoration: const InputDecoration(
                                labelText: 'IBAN (TR…)'),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _contactName,
                                  decoration:
                                      const InputDecoration(labelText: 'Yetkili ad'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _contactSurname,
                                  decoration: const InputDecoration(
                                      labelText: 'Yetkili soyad'),
                                ),
                              ),
                            ],
                          ),
                          if (_type == 'PERSONAL') ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: _identityNumber,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'TCKN (11 hane)'),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: _legalCompanyTitle,
                              decoration: const InputDecoration(
                                  labelText: 'Ticari ünvan'),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _taxOffice,
                                    decoration: const InputDecoration(
                                        labelText: 'Vergi dairesi'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _taxNumber,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                        labelText: 'Vergi numarası'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!, style: TextStyle(color: scheme.error)),
                          ],
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _saving ? null : _submit,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.send),
                            label: Text(_saving
                                ? 'Gönderiliyor…'
                                : 'Onboarding başvurusunu gönder'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Onaylandığında müşteri ödemeleri doğrudan IBAN\'ınıza yatırılacak; platform sadece komisyonu alır.',
                            style: TextStyle(
                                fontSize: 11, color: scheme.onSurfaceVariant),
                          ),
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
