import 'package:callcenter_salonuser_mobil/models/portal_personnel.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Personel listesi (read-only). CRUD bu app'te yok — yetkili owner web
/// panelinden ekler. Mobilde sadece kim çalışıyor görünür.
class PersonnelPage extends StatefulWidget {
  const PersonnelPage({super.key});

  @override
  State<PersonnelPage> createState() => _PersonnelPageState();
}

class _PersonnelPageState extends State<PersonnelPage> {
  bool _loading = true;
  String? _error;
  List<PortalPersonnel> _people = const [];

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
      final list = await context.read<SalonApiClient>().getPersonnel();
      if (!mounted) return;
      setState(() {
        _people = list;
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Personel')),
      body: ResponsiveCenter(
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
                  : _people.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(40),
                          children: [
                            Icon(Icons.badge_outlined,
                                size: 56, color: scheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(
                              'Personel kaydı yok.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(12, 8, 12, 24),
                          itemCount: _people.length,
                          separatorBuilder: (ctx, idx) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final p = _people[i];
                            final photo = (p.photoUrl ?? '').trim();
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: scheme.primaryContainer,
                                  backgroundImage:
                                      photo.isNotEmpty ? NetworkImage(photo) : null,
                                  child: photo.isEmpty
                                      ? Text(
                                          p.fullName.isEmpty
                                              ? '?'
                                              : p.fullName.characters.first
                                                  .toUpperCase(),
                                          style: TextStyle(
                                              color: scheme.onPrimaryContainer,
                                              fontWeight: FontWeight.w700),
                                        )
                                      : null,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(p.fullName)),
                                    if (p.isLocked)
                                      const Icon(Icons.lock,
                                          size: 14, color: Color(0xFFB91C1C)),
                                    if (!p.isActive)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(Icons.pause_circle_outline,
                                            size: 14, color: Color(0xFF92400E)),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  [
                                    if (p.title.isNotEmpty) p.title,
                                    if ((p.customerRoleName ?? '').isNotEmpty)
                                      p.customerRoleName,
                                    if ((p.branchName ?? '').isNotEmpty)
                                      'Şube: ${p.branchName}',
                                  ].whereType<String>().join(' · '),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
