import 'package:callcenter_salonuser_mobil/screens/dashboard_page.dart';
import 'package:callcenter_salonuser_mobil/screens/login_page.dart';
import 'package:callcenter_salonuser_mobil/state/session_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Login durumuna göre Dashboard veya LoginPage. P2.6 BottomNav ile
/// Dashboard / Randevular / Daha fazla sekmelerine genişleyecek.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    if (!session.isLoggedIn) return const LoginPage();
    return const DashboardPage();
  }
}
