import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/feedback.dart';
import '../../core/models/file_kind.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../auth/auth_state.dart';
import 'activity_tile.dart';
import 'file_thumbnail.dart';
import 'trash_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onOpenVault, this.onOpenActivity});

  final VoidCallback? onOpenVault;
  final VoidCallback? onOpenActivity;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<FileModel> _files = [];
  List<FileModel> _trash = [];
  List<OperationModel> _ops = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final results = await Future.wait([
        api.listFiles(status: 'active'),
        api.listFiles(status: 'trashed'),
        api.listOperations(limit: 80),
      ]);
      if (!mounted) return;
      setState(() {
        _files = results[0] as List<FileModel>;
        _trash = results[1] as List<FileModel>;
        _ops = results[2] as List<OperationModel>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
      showAppError(context, e);
    }
  }

  int get _bytes =>
      _files.fold<int>(0, (sum, f) => sum + (f.sizeBytes ?? 0));

  Map<FileKind, int> get _byKind {
    final map = <FileKind, int>{};
    for (final f in _files) {
      final k = kindOfFile(f);
      map[k] = (map[k] ?? 0) + 1;
    }
    return map;
  }

  List<int> get _week {
    final now = DateTime.now();
    final counts = List<int>.filled(7, 0);
    for (final op in _ops) {
      final dt = DateTime.tryParse(op.createdAt.replaceFirst(' ', 'T'));
      if (dt == null) continue;
      final day = DateTime(dt.year, dt.month, dt.day);
      final today = DateTime(now.year, now.month, now.day);
      final diff = today.difference(day).inDays;
      if (diff >= 0 && diff < 7) {
        counts[6 - diff] += 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    final date = _frenchDate(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.teal,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    Text(
                      'Bonjour${user?.name.isNotEmpty == true ? ', ${user!.name}' : ''}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(date, style: Theme.of(context).textTheme.bodyMedium),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      ErrorBanner(message: _error!, onRetry: _load),
                    ],
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, c) {
                        final cards = [
                          _Kpi(
                            label: 'Fichiers',
                            value: _files.length.toDouble(),
                            icon: Icons.folder_rounded,
                            caption: 'dans le coffre',
                            accent: const Color(0xFF3B82F6),
                          ),
                          _Kpi(
                            label: 'Volume',
                            value: _bytes.toDouble(),
                            icon: Icons.sd_storage_rounded,
                            caption: 'chiffré sur l’appareil',
                            asBytes: true,
                            accent: const Color(0xFF38BDF8),
                          ),
                          _Kpi(
                            label: 'Corbeille',
                            value: _trash.length.toDouble(),
                            icon: Icons.delete_outline_rounded,
                            caption: 'en attente',
                            accent: const Color(0xFF60A5FA),
                          ),
                          _Kpi(
                            label: 'Activité',
                            value: _ops.length.toDouble(),
                            icon: Icons.history_rounded,
                            caption: 'opérations récentes',
                            accent: const Color(0xFF1D4ED8),
                          ),
                        ];
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 12),
                                Expanded(child: cards[1]),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: cards[2]),
                                const SizedBox(width: 12),
                                Expanded(child: cards[3]),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, c) {
                        final charts = [
                          _ChartCard(
                            title: 'Répartition',
                            subtitle: 'Types de fichiers sauvegardés',
                            child: SizedBox(
                              height: 230,
                              child: _KindPie(counts: _byKind),
                            ),
                          ),
                          _ChartCard(
                            title: 'Activité · 7 jours',
                            subtitle: 'Histogramme des opérations',
                            child: SizedBox(
                              height: 230,
                              child: _WeekBars(counts: _week),
                            ),
                          ),
                        ];
                        if (c.maxWidth > 860) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: charts[0]),
                              const SizedBox(width: 12),
                              Expanded(child: charts[1]),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            charts[0],
                            const SizedBox(height: 12),
                            charts[1],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Historique d’activité',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onOpenActivity,
                          child: const Text('Tout voir'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_ops.isEmpty)
                      const SurfacePanel(
                        child: Text(
                          'Aucune activité pour le moment. Les sauvegardes, téléchargements et suppressions apparaîtront ici.',
                        ),
                      )
                    else
                      ..._ops.take(6).map(
                            (op) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ActivityTile(operation: op),
                            ),
                          ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Récents',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onOpenVault,
                          child: const Text('Voir le coffre'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_files.isEmpty)
                      const SurfacePanel(
                        child: Text(
                          'Aucune sauvegarde pour le moment. Ajoutez un fichier depuis le coffre.',
                        ),
                      )
                    else
                      SizedBox(
                        height: 168,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _files.length.clamp(0, 8),
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final f = _files[i];
                            return SizedBox(
                              width: 148,
                              child: SurfacePanel(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: FileThumbnail(file: f)),
                                    const SizedBox(height: 8),
                                    Text(
                                      f.logicalName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.ink,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    SurfacePanel(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TrashScreen()),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_rounded, color: AppColors.mint),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ouvrir la corbeille (${_trash.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: AppColors.slate),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

String _frenchDate(DateTime d) {
  const days = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.caption,
    required this.accent,
    this.asBytes = false,
  });

  final String label;
  final double value;
  final IconData icon;
  final String caption;
  final Color accent;
  final bool asBytes;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final shown = asBytes ? formatBytes(v.round()) : v.round().toString();
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.28),
                AppColors.panel.withValues(alpha: 0.96),
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accent, size: 20),
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                shown,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                    ),
              ),
              Text(caption, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _KindPie extends StatelessWidget {
  const _KindPie({required this.counts});

  final Map<FileKind, int> counts;

  static const _colors = [
    Color(0xFF3B82F6),
    Color(0xFF60A5FA),
    Color(0xFF1D4ED8),
    Color(0xFF38BDF8),
    Color(0xFF93C5FD),
    Color(0xFF1E40AF),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = counts.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'Ajoutez des fichiers pour voir le camembert.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 42,
              sectionsSpace: 3,
              startDegreeOffset: -90,
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    color: _colors[i % _colors.length],
                    radius: 58,
                    title: '${entries[i].value}',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 800),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < entries.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _colors[i % _colors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      kindLabel(entries[i].key),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.ink,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.counts});

  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final maxY = (counts.fold<int>(0, (a, b) => a > b ? a : b) + 1).toDouble();
    final labels = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      const names = ['lun', 'mar', 'mer', 'jeu', 'ven', 'sam', 'dim'];
      return names[d.weekday - 1];
    });
    final empty = counts.every((c) => c == 0);

    return BarChart(
      BarChartData(
        maxY: empty ? 4 : maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.line.withValues(alpha: 0.7),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labels[i],
                    style: TextStyle(color: AppColors.slate, fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < counts.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: empty ? 0.2 : counts[i].toDouble(),
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
                  ),
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 800),
    );
  }
}
