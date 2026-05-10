import 'package:callcenter_salonuser_mobil/models/sln_review.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  static final _date = DateFormat('d MMM y', 'tr_TR');

  int? _statusFilter = ReviewStatuses.pending;
  bool _loading = true;
  String? _error;
  List<SlnReview> _reviews = const [];
  SlnReviewStats? _stats;

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
      final results = await Future.wait([
        api.getReviews(statusId: _statusFilter),
        api.getReviewStats().then<SlnReviewStats?>((v) => v).catchError((_) => null),
      ]);
      if (!mounted) return;
      setState(() {
        _reviews = results[0] as List<SlnReview>;
        _stats = results[1] as SlnReviewStats?;
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

  Future<void> _approve(SlnReview r) => _setStatus(r, ReviewStatuses.approved);
  Future<void> _reject(SlnReview r) => _setStatus(r, ReviewStatuses.rejected);

  Future<void> _setStatus(SlnReview r, int targetStatus) async {
    try {
      await context
          .read<SalonApiClient>()
          .updateReviewStatus(id: r.id, statusId: targetStatus);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _delete(SlnReview r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yorumu sil'),
        content: const Text('Yorum kalıcı olarak silinecek. Devam edilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<SalonApiClient>().deleteReview(r.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Yorumlar')),
      body: ResponsiveCenter(
        child: Column(
          children: [
            if (_stats != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    _StatChip(
                        label: 'Toplam', value: '${_stats!.totalReviews}'),
                    const SizedBox(width: 6),
                    _StatChip(
                        label: 'Bekliyor',
                        value: '${_stats!.pendingCount}',
                        color: const Color(0xFFFEF3C7),
                        fg: const Color(0xFF92400E)),
                    const SizedBox(width: 6),
                    _StatChip(
                        label: 'Onaylı',
                        value: '${_stats!.approvedCount}',
                        color: const Color(0xFFD1FAE5),
                        fg: const Color(0xFF065F46)),
                    const SizedBox(width: 6),
                    _StatChip(
                        label: 'Ortalama',
                        value: _stats!.averageRating.toStringAsFixed(1)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _Filter('Bekleyen', _statusFilter == ReviewStatuses.pending,
                        () => setState(() {
                              _statusFilter = ReviewStatuses.pending;
                              _load();
                            })),
                    const SizedBox(width: 6),
                    _Filter('Onaylı', _statusFilter == ReviewStatuses.approved,
                        () => setState(() {
                              _statusFilter = ReviewStatuses.approved;
                              _load();
                            })),
                    const SizedBox(width: 6),
                    _Filter('Reddedilen', _statusFilter == ReviewStatuses.rejected,
                        () => setState(() {
                              _statusFilter = ReviewStatuses.rejected;
                              _load();
                            })),
                    const SizedBox(width: 6),
                    _Filter('Tümü', _statusFilter == null,
                        () => setState(() {
                              _statusFilter = null;
                              _load();
                            })),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? ListView(
                            padding: const EdgeInsets.all(20),
                            children: [Text(_error!, textAlign: TextAlign.center)],
                          )
                        : _reviews.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(40),
                                children: [
                                  Icon(Icons.reviews_outlined,
                                      size: 56, color: scheme.onSurfaceVariant),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Bu filtrede yorum yok.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(12, 8, 12, 24),
                                itemCount: _reviews.length,
                                separatorBuilder: (ctx, idx) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final r = _reviews[i];
                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  (r.clientName ?? '').isEmpty
                                                      ? 'Misafir'
                                                      : r.clientName!,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: List.generate(5, (j) {
                                                  return Icon(
                                                    j < r.rating
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    size: 14,
                                                    color:
                                                        const Color(0xFFF59E0B),
                                                  );
                                                }),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              _date.format(r.createdAt),
                                              style: TextStyle(
                                                  fontSize: 11.5,
                                                  color:
                                                      scheme.onSurfaceVariant),
                                            ),
                                          ),
                                          if ((r.comment ?? '').isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              r.comment!,
                                              style: const TextStyle(
                                                  fontSize: 13.5, height: 1.4),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              if (r.isPending) ...[
                                                FilledButton.icon(
                                                  onPressed: () => _approve(r),
                                                  icon: const Icon(Icons.check, size: 16),
                                                  label: const Text('Onayla'),
                                                  style: FilledButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8),
                                                      visualDensity:
                                                          VisualDensity.compact),
                                                ),
                                                const SizedBox(width: 8),
                                                OutlinedButton.icon(
                                                  onPressed: () => _reject(r),
                                                  icon: const Icon(Icons.close, size: 16),
                                                  label: const Text('Reddet'),
                                                  style: OutlinedButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8),
                                                      visualDensity:
                                                          VisualDensity.compact),
                                                ),
                                              ] else ...[
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: r.isApproved
                                                        ? const Color(
                                                            0xFFD1FAE5)
                                                        : scheme.errorContainer,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                  ),
                                                  child: Text(
                                                    r.statusLabel,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: r.isApproved
                                                          ? const Color(
                                                              0xFF065F46)
                                                          : scheme
                                                              .onErrorContainer,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              const Spacer(),
                                              IconButton(
                                                tooltip: 'Sil',
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 18),
                                                onPressed: () => _delete(r),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.color,
    this.fg,
  });
  final String label;
  final String value;
  final Color? color;
  final Color? fg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.surfaceContainerHighest;
    final foreground = fg ?? scheme.onSurface;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(6)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: foreground)),
            Text(label,
                style: TextStyle(fontSize: 10.5, color: foreground.withValues(alpha: 0.85))),
          ],
        ),
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primaryContainer,
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
