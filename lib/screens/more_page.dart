import 'package:callcenter_salonuser_mobil/state/session_state.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "Daha fazla" sekmesi — Phase 3+'ta açılacak modüller için placeholder.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    final scheme = Theme.of(context).colorScheme;
    final modules = const [
      _Module(icon: Icons.people_outline, label: 'Müşteriler', phase: 'Phase 3'),
      _Module(icon: Icons.badge_outlined, label: 'Personel', phase: 'Phase 3'),
      _Module(icon: Icons.list_alt, label: 'Hizmetler', phase: 'Phase 3'),
      _Module(icon: Icons.workspace_premium_outlined, label: 'Üyelikler', phase: 'Phase 4'),
      _Module(icon: Icons.reviews_outlined, label: 'Yorumlar', phase: 'Phase 4'),
      _Module(icon: Icons.settings_outlined, label: 'Salon ayarları', phase: 'Phase 5'),
      _Module(icon: Icons.account_balance_outlined, label: 'Ödeme bilgileri (IBAN)', phase: 'Phase 5'),
      _Module(icon: Icons.bar_chart, label: 'Raporlar', phase: 'Phase 6'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(session.user?.fullName ?? 'Daha fazla'),
        actions: [
          IconButton(
            tooltip: 'Çıkış',
            icon: const Icon(Icons.logout),
            onPressed: () => session.signOut(),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salon yönetim modülleri',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sırayla devreye girecek modüller. Her biri tamamlandığında bu listeden açılır.',
                      style: TextStyle(
                          fontSize: 12.5, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final m in modules)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: Icon(m.icon, color: scheme.onSurfaceVariant),
                    title: Text(m.label),
                    subtitle: Text(
                      'Yakında · ${m.phase}',
                      style: TextStyle(
                          fontSize: 11.5, color: scheme.onSurfaceVariant),
                    ),
                    trailing: const Icon(Icons.lock_clock,
                        size: 18, color: Colors.black26),
                    enabled: false,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Module {
  const _Module({required this.icon, required this.label, required this.phase});
  final IconData icon;
  final String label;
  final String phase;
}
