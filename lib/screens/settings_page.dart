import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Salon profili + sayfa görünürlük ayarları. Owner-only (`/api/sln-profile`
/// `[RequireSalonOwner]`).
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic> _profile = {};

  final _description = TextEditingController();
  final _website = TextEditingController();
  final _instagram = TextEditingController();
  final _facebook = TextEditingController();
  bool _isPublished = true;

  // Page settings (show* flags)
  bool _showServices = true;
  bool _showMemberships = true;
  bool _showBooking = true;
  bool _showHours = true;
  bool _showContact = true;
  bool _showBanners = true;
  bool _showTeam = true;
  bool _showReviews = true;
  bool _showMap = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _description.dispose();
    _website.dispose();
    _instagram.dispose();
    _facebook.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await context.read<SalonApiClient>().getSalonProfile();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _description.text = (p['description'] as String?) ?? '';
        _website.text = (p['website'] as String?) ?? '';
        _instagram.text = (p['instagramHandle'] as String?) ?? '';
        _facebook.text = (p['facebookUrl'] as String?) ?? '';
        _isPublished = p['isPublished'] as bool? ?? true;
        _showServices = p['showServices'] as bool? ?? true;
        _showMemberships = p['showMemberships'] as bool? ?? true;
        _showBooking = p['showBooking'] as bool? ?? true;
        _showHours = p['showHours'] as bool? ?? true;
        _showContact = p['showContact'] as bool? ?? true;
        _showBanners = p['showBanners'] as bool? ?? true;
        _showTeam = p['showTeam'] as bool? ?? true;
        _showReviews = p['showReviews'] as bool? ?? true;
        _showMap = p['showMap'] as bool? ?? true;
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
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = context.read<SalonApiClient>();
      await api.saveSalonProfile(
        description: _description.text.trim(),
        website: _website.text.trim(),
        instagramHandle: _instagram.text.trim(),
        facebookUrl: _facebook.text.trim(),
        isPublished: _isPublished,
      );
      await api.savePageSettings({
        'showServices': _showServices,
        'showMemberships': _showMemberships,
        'showBooking': _showBooking,
        'showHours': _showHours,
        'showContact': _showContact,
        'showBanners': _showBanners,
        'showTeam': _showTeam,
        'showReviews': _showReviews,
        'showMap': _showMap,
        'sectionOrderJson': _profile['sectionOrderJson'],
        'bannersJson': _profile['bannersJson'],
        'logoUrl': _profile['logoUrl'],
        'coverImageUrl': _profile['coverImageUrl'],
        'faviconUrl': _profile['faviconUrl'],
        'galleryImagesJson': _profile['galleryImagesJson'],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedildi.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = dioErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon Ayarları'),
        actions: [
          if (!_loading)
            IconButton(
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              tooltip: 'Kaydet',
              onPressed: _saving ? null : _save,
            ),
        ],
      ),
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
                          const Text('Profil',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _description,
                            minLines: 2,
                            maxLines: 5,
                            decoration: const InputDecoration(
                                labelText: 'Açıklama',
                                alignLabelWithHint: true),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _website,
                            keyboardType: TextInputType.url,
                            decoration:
                                const InputDecoration(labelText: 'Website'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _instagram,
                            decoration: const InputDecoration(
                                labelText: 'Instagram (@kullanici)'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _facebook,
                            keyboardType: TextInputType.url,
                            decoration:
                                const InputDecoration(labelText: 'Facebook URL'),
                          ),
                          SwitchListTile(
                            value: _isPublished,
                            onChanged: (v) => setState(() => _isPublished = v),
                            title: const Text('Profil yayında'),
                            contentPadding: EdgeInsets.zero,
                          ),
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
                          const Text('Sayfa görünürlüğü',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            'Profil sayfasında müşteriye gösterilecek bölümler.',
                            style: TextStyle(
                                fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                          _flag('Hizmetler', _showServices, (v) => _showServices = v),
                          _flag('Üyelikler', _showMemberships, (v) => _showMemberships = v),
                          _flag('Online randevu', _showBooking, (v) => _showBooking = v),
                          _flag('Çalışma saatleri', _showHours, (v) => _showHours = v),
                          _flag('İletişim', _showContact, (v) => _showContact = v),
                          _flag('Banners', _showBanners, (v) => _showBanners = v),
                          _flag('Ekip', _showTeam, (v) => _showTeam = v),
                          _flag('Yorumlar', _showReviews, (v) => _showReviews = v),
                          _flag('Harita', _showMap, (v) => _showMap = v),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _flag(String label, bool value, void Function(bool) setter) {
    return SwitchListTile(
      value: value,
      onChanged: (v) => setState(() => setter(v)),
      title: Text(label),
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
