import 'package:callcenter_salonuser_mobil/screens/login_page.dart';
import 'package:callcenter_salonuser_mobil/state/session_state.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// İlk sürümde MainShell sadece login durumunu yönetir + Phase 1 sonrası
/// dolacak gerçek modüller (Dashboard, Appointments, Clients, ...) için
/// placeholder.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    if (!session.isLoggedIn) return const LoginPage();
    return _StaffHomeStub(user: session.user!.fullName, role: session.user!.role);
  }
}

class _StaffHomeStub extends StatelessWidget {
  const _StaffHomeStub({required this.user, required this.role});
  final String user;
  final String role;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(user),
        actions: [
          IconButton(
            tooltip: 'Çıkış',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<SessionState>().signOut(),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: scheme.primary),
                        const SizedBox(width: 10),
                        const Text(
                          'Hoş geldiniz',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Rol: $role',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      'Salon yönetim modülleri (Dashboard, Randevular, Müşteriler, Personel, Hizmetler, Raporlar, Ayarlar) Phase 2 ile burada açılacak.',
                      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.4),
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
