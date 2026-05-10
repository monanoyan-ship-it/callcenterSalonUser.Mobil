import 'package:callcenter_salonuser_mobil/models/appointment_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/state/session_state.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/appointment_tile.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Login sonrası anasayfa. Bugünün özetini ve ilk 5 randevuyu gösterir.
/// Tüm randevular için Randevular sekmesi (P2.6 sonrası).
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static final _hour = DateFormat('HH:mm', 'tr_TR');
  static final _today = DateFormat.yMMMMEEEEd('tr_TR');

  bool _loading = true;
  String? _error;
  List<Appointment> _appointments = const [];

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
      final api = context.read<SalonApiClient>();
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      final list = await api.getAppointments(from: start, to: end);
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (!mounted) return;
      setState(() {
        _appointments = list;
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

  Map<String, int> get _stats {
    int planned = 0, confirmed = 0, completed = 0, cancelled = 0;
    for (final a in _appointments) {
      if (a.isPlanned) {
        planned++;
      } else if (a.isConfirmed) {
        confirmed++;
      } else if (a.isCompleted) {
        completed++;
      } else if (a.isCancelled) {
        cancelled++;
      }
    }
    return {
      'total': _appointments.length,
      'planned': planned,
      'confirmed': confirmed,
      'completed': completed,
      'cancelled': cancelled,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = context.watch<SessionState>();
    final user = session.user;
    return Scaffold(
      appBar: AppBar(
        title: Text(user?.fullName ?? 'Salon'),
        actions: [
          IconButton(
            tooltip: 'Çıkış',
            icon: const Icon(Icons.logout),
            onPressed: () => session.signOut(),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                _today.format(DateTime.now()),
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _ErrorCard(message: _error!, onRetry: _load)
              else ...[
                _StatsRow(stats: _stats),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Bugünün randevuları',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${_appointments.length} kayıt',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_appointments.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Bugün için randevu yok.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  )
                else ...[
                  for (final a in _appointments.take(5)) ...[
                    AppointmentTile(appointment: a, hourFmt: _hour),
                    const SizedBox(height: 8),
                  ],
                  if (_appointments.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${_appointments.length - 5} daha · Randevular sekmesinde tümünü görün',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final Map<String, int> stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget chip(String label, int n, Color bg, Color fg) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text('$n',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700, color: fg)),
                Text(label,
                    style: TextStyle(fontSize: 11, color: fg, height: 1.2),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
    return Row(
      children: [
        chip('Toplam', stats['total'] ?? 0, scheme.primaryContainer, scheme.onPrimaryContainer),
        const SizedBox(width: 6),
        chip('Planlandı', stats['planned'] ?? 0, const Color(0xFFE0E7FF), const Color(0xFF1E40AF)),
        const SizedBox(width: 6),
        chip('Onaylandı', stats['confirmed'] ?? 0, const Color(0xFFD1FAE5), const Color(0xFF065F46)),
        const SizedBox(width: 6),
        chip('Tamamlandı', stats['completed'] ?? 0, scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        chip('İptal', stats['cancelled'] ?? 0, scheme.errorContainer, scheme.onErrorContainer),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 36, color: scheme.error),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}
