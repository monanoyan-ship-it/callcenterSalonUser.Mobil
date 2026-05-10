import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Şube listesi (read-only). CRUD ileride; şu an mevcut şubeler görüntülenir.
class BranchesPage extends StatefulWidget {
  const BranchesPage({super.key});

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _branches = const [];

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
      final list = await context.read<SalonApiClient>().getBranches();
      if (!mounted) return;
      setState(() {
        _branches = list;
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
      appBar: AppBar(title: const Text('Şubeler')),
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
                  : _branches.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(40),
                          children: [
                            Icon(Icons.storefront_outlined,
                                size: 56, color: scheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(
                              'Şube kaydı yok.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(12, 12, 12, 24),
                          itemCount: _branches.length,
                          separatorBuilder: (ctx, idx) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final b = _branches[i];
                            final loc = [
                              if ((b['district'] as String?)?.isNotEmpty == true) b['district'],
                              if ((b['city'] as String?)?.isNotEmpty == true) b['city'],
                            ].whereType<String>().join(', ');
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: scheme.primaryContainer,
                                  child: Icon(
                                    b['isHeadquarter'] == true
                                        ? Icons.home_work_outlined
                                        : Icons.storefront_outlined,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                        child:
                                            Text(b['name'] as String? ?? '')),
                                    if (b['isHeadquarter'] == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: scheme.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'Merkez',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  scheme.onPrimaryContainer),
                                        ),
                                      ),
                                    if (b['isActive'] == false)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(Icons.pause_circle_outline,
                                            size: 14,
                                            color: Color(0xFF92400E)),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  [
                                    if (loc.isNotEmpty) loc,
                                    if ((b['phone'] as String?)?.isNotEmpty ==
                                        true)
                                      b['phone'] as String,
                                  ].join(' · '),
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
