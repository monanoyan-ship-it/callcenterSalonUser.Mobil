import 'package:callcenter_salonuser_mobil/screens/before_after_page.dart';
import 'package:callcenter_salonuser_mobil/screens/branches_page.dart';
import 'package:callcenter_salonuser_mobil/screens/campaigns_page.dart';
import 'package:callcenter_salonuser_mobil/screens/cash_page.dart';
import 'package:callcenter_salonuser_mobil/screens/clients_page.dart';
import 'package:callcenter_salonuser_mobil/screens/consent_forms_page.dart';
import 'package:callcenter_salonuser_mobil/screens/email_campaigns_page.dart';
import 'package:callcenter_salonuser_mobil/screens/expenses_page.dart';
import 'package:callcenter_salonuser_mobil/screens/gift_cards_page.dart';
import 'package:callcenter_salonuser_mobil/screens/invoices_list_page.dart';
import 'package:callcenter_salonuser_mobil/screens/loyalty_page.dart';
import 'package:callcenter_salonuser_mobil/screens/memberships_page.dart';
import 'package:callcenter_salonuser_mobil/screens/modules_page.dart';
import 'package:callcenter_salonuser_mobil/screens/noshow_policy_page.dart';
import 'package:callcenter_salonuser_mobil/screens/packages_page.dart';
import 'package:callcenter_salonuser_mobil/screens/payment_info_page.dart';
import 'package:callcenter_salonuser_mobil/screens/personnel_page.dart';
import 'package:callcenter_salonuser_mobil/screens/personnel_prices_page.dart';
import 'package:callcenter_salonuser_mobil/screens/products_page.dart';
import 'package:callcenter_salonuser_mobil/screens/recipes_page.dart';
import 'package:callcenter_salonuser_mobil/screens/reports_page.dart';
import 'package:callcenter_salonuser_mobil/screens/reviews_page.dart';
import 'package:callcenter_salonuser_mobil/screens/services_page.dart';
import 'package:callcenter_salonuser_mobil/screens/settings_page.dart';
import 'package:callcenter_salonuser_mobil/screens/suppliers_page.dart';
import 'package:callcenter_salonuser_mobil/screens/waitlist_page.dart';
import 'package:callcenter_salonuser_mobil/screens/winback_page.dart';
import 'package:callcenter_salonuser_mobil/state/session_state.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "Daha fazla" sekmesi — tüm modül sayfalarına gidiş.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    final scheme = Theme.of(context).colorScheme;
    final modules = <_Module>[
      _Module(
        icon: Icons.receipt_long_outlined,
        label: 'Adisyonlar',
        builder: (_) => const InvoicesListPage(),
      ),
      _Module(
        icon: Icons.point_of_sale,
        label: 'Kasa',
        builder: (_) => const CashPage(),
      ),
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
        icon: Icons.inventory_2_outlined,
        label: 'Ürünler',
        builder: (_) => const ProductsPage(),
      ),
      _Module(
        icon: Icons.local_shipping_outlined,
        label: 'Tedarikçiler',
        builder: (_) => const SuppliersPage(),
      ),
      _Module(
        icon: Icons.menu_book_outlined,
        label: 'Reçeteler',
        builder: (_) => const RecipesPage(),
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
        icon: Icons.card_giftcard,
        label: 'Hediye Kartları',
        builder: (_) => const GiftCardsPage(),
      ),
      _Module(
        icon: Icons.campaign_outlined,
        label: 'SMS Kampanyaları',
        builder: (_) => const CampaignsPage(),
      ),
      _Module(
        icon: Icons.alternate_email,
        label: 'Email Kampanyaları',
        builder: (_) => const EmailCampaignsPage(),
      ),
      _Module(
        icon: Icons.refresh,
        label: 'Winback (Kayıp müşteri)',
        builder: (_) => const WinbackPage(),
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
      _Module(
        icon: Icons.bar_chart,
        label: 'Raporlar',
        builder: (_) => const ReportsPage(),
      ),
      _Module(
        icon: Icons.loyalty_outlined,
        label: 'Sadakat',
        builder: (_) => const LoyaltyPage(),
      ),
      // ─── Phase 11: Operasyon Domain ───
      _Module(
        icon: Icons.payments_outlined,
        label: 'Giderler',
        builder: (_) => const ExpensesPage(),
      ),
      _Module(
        icon: Icons.event_available,
        label: 'Bekleme Listesi',
        builder: (_) => const WaitlistPage(),
      ),
      _Module(
        icon: Icons.compare,
        label: 'Öncesi/Sonrası',
        builder: (_) => const BeforeAfterPage(),
      ),
      _Module(
        icon: Icons.assignment_outlined,
        label: 'Onam Formları',
        builder: (_) => const ConsentFormsPage(),
      ),
      _Module(
        icon: Icons.gavel,
        label: 'Gelmeme Politikası',
        builder: (_) => const NoShowPolicyPage(),
      ),
      _Module(
        icon: Icons.collections_bookmark_outlined,
        label: 'Paketler',
        builder: (_) => const PackagesPage(),
      ),
      _Module(
        icon: Icons.attach_money,
        label: 'Personel Fiyat Override',
        builder: (_) => const PersonnelPricesPage(),
      ),
      _Module(
        icon: Icons.extension_outlined,
        label: 'Modüller (satın alma)',
        builder: (_) => const ModulesPage(),
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
                    leading: Icon(m.icon, color: scheme.primary),
                    title: Text(m.label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: m.builder),
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
  const _Module({required this.icon, required this.label, required this.builder});
  final IconData icon;
  final String label;
  final WidgetBuilder builder;
}
