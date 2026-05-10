import 'package:callcenter_salonuser_mobil/models/noshow_policy_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// `GET/POST /api/sln-noshow-policy` — gelmeme politikasi tek-record settings.
class NoShowPolicyPage extends StatefulWidget {
  const NoShowPolicyPage({super.key});

  @override
  State<NoShowPolicyPage> createState() => _NoShowPolicyPageState();
}

class _NoShowPolicyPageState extends State<NoShowPolicyPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool _requireDeposit = false;
  bool _isActive = true;
  final _depositCtrl = TextEditingController(text: '0');
  final _hoursCtrl = TextEditingController(text: '24');
  final _lateFeeCtrl = TextEditingController(text: '0');
  final _noShowFeeCtrl = TextEditingController(text: '0');
  final _blacklistCtrl = TextEditingController(text: '3');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _depositCtrl.dispose();
    _hoursCtrl.dispose();
    _lateFeeCtrl.dispose();
    _noShowFeeCtrl.dispose();
    _blacklistCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final p = await context.read<SalonApiClient>().fetchNoShowPolicy();
      if (!mounted) return;
      if (p != null) {
        _requireDeposit = p.requireDeposit;
        _isActive = p.isActive;
        _depositCtrl.text = p.depositAmount.toStringAsFixed(2);
        _hoursCtrl.text = p.freeCancellationHours.toString();
        _lateFeeCtrl.text = p.lateCancellationFee.toStringAsFixed(2);
        _noShowFeeCtrl.text = p.noShowFee.toStringAsFixed(2);
        _blacklistCtrl.text = p.blacklistThreshold.toString();
      }
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = dioErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<SalonApiClient>().upsertNoShowPolicy(NoShowPolicyUpdate(
            requireDeposit: _requireDeposit,
            depositAmount: double.tryParse(_depositCtrl.text.replaceAll(',', '.')) ?? 0,
            freeCancellationHours: int.tryParse(_hoursCtrl.text) ?? 24,
            lateCancellationFee: double.tryParse(_lateFeeCtrl.text.replaceAll(',', '.')) ?? 0,
            noShowFee: double.tryParse(_noShowFeeCtrl.text.replaceAll(',', '.')) ?? 0,
            blacklistThreshold: int.tryParse(_blacklistCtrl.text) ?? 3,
            isActive: _isActive,
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Politika kaydedildi.')),
      );
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
        title: const Text('Gelmeme Politikasi'),
        actions: [
          IconButton(
            tooltip: 'Kaydet',
            onPressed: _saving || _loading ? null : _save,
            icon: const Icon(Icons.save_outlined),
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Tekrar dene')),
          ]),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Politika aktif'),
          contentPadding: EdgeInsets.zero,
          value: _isActive,
          onChanged: (v) => setState(() => _isActive = v),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Depozito zorunlu'),
          subtitle: const Text('Online randevu rezervasyonunda depozito sorulur'),
          contentPadding: EdgeInsets.zero,
          value: _requireDeposit,
          onChanged: (v) => setState(() => _requireDeposit = v),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _depositCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Depozito tutari (TL)',
            helperText: 'Depozito zorunlu ise alinacak miktar',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _hoursCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Ucretsiz iptal saati',
            helperText: 'Randevudan kac saat once iptal edilirse ucret yok',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _lateFeeCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Gec iptal ucreti (TL)',
            helperText: 'Ucretsiz pencere disinda iptal kesintisi',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noShowFeeCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Gelmeme ucreti (TL)',
            helperText: 'Hic gelmeyen musteriden alinan ucret',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _blacklistCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Karaliste esigi (gelmeme sayisi)',
            helperText: 'Bu sayiya ulasinca musteri otomatik karalisteye alinir',
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: const Text('Kaydet'),
        ),
      ],
    );
  }
}
