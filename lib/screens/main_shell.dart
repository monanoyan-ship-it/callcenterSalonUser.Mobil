import 'package:callcenter_salonuser_mobil/screens/appointments_list_page.dart';
import 'package:callcenter_salonuser_mobil/screens/dashboard_page.dart';
import 'package:callcenter_salonuser_mobil/screens/login_page.dart';
import 'package:callcenter_salonuser_mobil/screens/more_page.dart';
import 'package:callcenter_salonuser_mobil/state/session_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Login durumunu yönetir + 3 sekmeli BottomNav (Dashboard / Randevular /
/// Daha fazla). IndexedStack ile sekme state'i korunur (Dashboard kaydırması
/// kaybolmaz). Her sayfa kendi AppBar/Scaffold'unu açar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    if (!session.isLoggedIn) return const LoginPage();

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardPage(),
          AppointmentsListPage(),
          MorePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Anasayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Randevular',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Daha fazla',
          ),
        ],
      ),
    );
  }
}
