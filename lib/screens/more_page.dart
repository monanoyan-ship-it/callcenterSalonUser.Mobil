import 'package:callcenter_salonuser_mobil/screens/branches_page.dart';
import 'package:callcenter_salonuser_mobil/screens/clients_page.dart';
import 'package:callcenter_salonuser_mobil/screens/memberships_page.dart';
import 'package:callcenter_salonuser_mobil/screens/payment_info_page.dart';
import 'package:callcenter_salonuser_mobil/screens/personnel_page.dart';
import 'package:callcenter_salonuser_mobil/screens/reviews_page.dart';
import 'package:callcenter_salonuser_mobil/screens/services_page.dart';
import 'package:callcenter_salonuser_mobil/screens/settings_page.dart';
import 'package:callcenter_salonuser_mobil/state/session_state.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "Daha fazla" sekmesi — açılan modüller tıklanabilir, kalanlar kilitli.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    final scheme = Theme.of(context).colorScheme;
    final modules = <_Module>[
      _Module(
        icon: Icons.people_outline,
        label: 'Müşteriler',
        builder: (_) => const ClientsPage(),
      ),
      _Module(
        icon: Icons.list_alt,
        label: 'Hizmetler',
        builder: (_) => const ServicesPage(),
      ),
      _Module(
        icon: Icons.badge_outlined,
        label: 'Personel',
        builder: (_) => const PersonnelPage(),
      ),
      _Module(
        icon: Icons.workspace_premium_outlined,
        label: 'Üyelikler',
        builder: (_) => const MembershipsPage(),
      ),
      _Module(
        icon: Icons.reviews_outlined,
        label: 'Yorumlar',
        builder: (_) => const ReviewsPage(),
      ),
      _Module(
        icon: Icons.settings_outlined,
        label: 'Salon ayarları',
        builder: (_) => const SettingsPage(),
      ),
      _Module(
        icon: Icons.storefront_outlined,
        label: 'Şubeler',
        builder: (_) => const BranchesPage(),
      ),
      _Module(
        icon: Icons.account_balance_outlined,
        label: 'Ödeme bilgileri (IBAN)',
        builder: (_) => const PaymentInfoPage(),
      ),
      const _Module(
        icon: Icons.bar_chart,
        label: 'Raporlar',
        phase: 'Phase 6',
      ),
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
            for (final m in modules)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      m.icon,
                      color: m.builder == null
                          ? scheme.onSurfaceVariant
                          : scheme.primary,
                    ),
                    title: Text(m.label),
                    subtitle: m.builder == null
                        ? Text(
                            'Yakında · ${m.phase}',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: scheme.onSurfaceVariant),
                          )
                        : null,
                    trailing: m.builder == null
                        ? const Icon(Icons.lock_clock,
                            size: 18, color: Colors.black26)
                        : const Icon(Icons.chevron_right),
                    enabled: m.builder != null,
                    onTap: m.builder == null
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(builder: m.builder!),
                            ),
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
  const _Module({
    required this.icon,
    required this.label,
    this.builder,
    this.phase = '',
  });
  final IconData icon;
  final String label;
  final WidgetBuilder? builder;
  final String phase;
}
