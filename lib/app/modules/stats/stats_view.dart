import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../data/models/game_type.dart';
import '../../shared/date_format.dart';
import '../../shared/weakness.dart';
import 'stats_controller.dart';

class StatsView extends GetView<StatsController> {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '통계',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: controller.overall.gamesPlayed == 0
          ? _EmptyState(bottomInset: bottomInset)
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
              children: [
                _OverviewCard(stats: controller.overall),
                const SizedBox(height: 24),
                const _SectionTitle('연산별'),
                const SizedBox(height: 8),
                for (final type in GameType.values) ...[
                  _TypeCard(type: type, stats: controller.byType[type]!),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
                const _SectionTitle('레벨별 정답률'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final l in StatsController.levels) ...[
                          _LevelRow(level: l, stats: controller.byLevel[l]!),
                          if (l != StatsController.levels.last)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionTitle('약점 분석 (연산 × 레벨)'),
                const SizedBox(height: 8),
                _WeaknessGrid(weakness: controller.weakness),
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 160,
              child: Lottie.asset(
                'assets/lottie/empty_state.json',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 통계를 보여줄 기록이 없어요',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.stats});

  final StatsAggregate stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _Metric(label: '게임', value: '${stats.gamesPlayed}'),
                _Metric(
                  label: '전체 정답률',
                  value: '${(stats.accuracy * 100).round()}%',
                ),
                _Metric(
                  label: '총 플레이',
                  value: formatElapsedSeconds(stats.totalSeconds),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.type, required this.stats});

  final GameType type;
  final StatsAggregate stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final played = stats.gamesPlayed > 0;
    final accuracy = stats.accuracy;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                type.symbol,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          type.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        played ? '${(accuracy * 100).round()}%' : '-',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: played ? accuracy : 0,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        _accuracyColor(accuracy, played),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    played
                        ? '${stats.gamesPlayed}게임 · 평균 '
                              '${formatElapsedSeconds(stats.averageSeconds)}'
                        : '아직 플레이 기록 없음',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.level, required this.stats});

  final int level;
  final StatsAggregate stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final played = stats.gamesPlayed > 0;
    final accuracy = stats.accuracy;
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            '레벨 $level',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: played ? accuracy : 0,
              minHeight: 10,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                _accuracyColor(accuracy, played),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 64,
          child: Text(
            played
                ? '${(accuracy * 100).round()}%  (${stats.gamesPlayed})'
                : '-',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

Color _accuracyColor(double accuracy, bool played) {
  if (!played) return Colors.grey.shade400;
  if (accuracy >= 0.8) return Colors.green;
  if (accuracy >= 0.5) return Colors.orange;
  return Colors.red;
}

class _WeaknessGrid extends StatelessWidget {
  const _WeaknessGrid({required this.weakness});

  final WeaknessAnalysis weakness;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 40),
                for (final l in StatsController.levels)
                  Expanded(
                    child: Center(
                      child: Text(
                        'L$l',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (final type in GameType.values) ...[
              _WeaknessRow(type: type, weakness: weakness),
              if (type != GameType.values.last) const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeaknessRow extends StatelessWidget {
  const _WeaknessRow({required this.type, required this.weakness});

  final GameType type;
  final WeaknessAnalysis weakness;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            type.symbol,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (final l in StatsController.levels)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _WeaknessCell(bucket: weakness.bucketFor(type, l)),
            ),
          ),
      ],
    );
  }
}

class _WeaknessCell extends StatelessWidget {
  const _WeaknessCell({required this.bucket});

  final WeaknessBucket? bucket;

  @override
  Widget build(BuildContext context) {
    final b = bucket;
    final played = b != null && b.attemptsCount > 0;
    final color = _accuracyColor(b?.accuracy ?? 0, played);
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: played ? 0.9 : 0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        played ? '${(b.accuracy * 100).round()}%' : '-',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: played ? Colors.white : Colors.grey.shade600,
        ),
      ),
    );
  }
}
