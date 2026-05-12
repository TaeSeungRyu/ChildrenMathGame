import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../data/models/game_type.dart';
import '../../data/services/sfx_service.dart';
import '../../shared/weakness.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '게임 선택',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: const [_MuteToggle()],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewPadding.bottom + 16,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 140,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Lottie.asset(
                      'assets/lottie/home_banner.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (controller.streakDays >= 1)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _StreakBadge(days: controller.streakDays),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (controller.recommendation != null) ...[
              _RecommendationCard(
                bucket: controller.recommendation!,
                onTap: () =>
                    controller.startRecommended(controller.recommendation!),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _tileRow(0, 1)),
                  const SizedBox(height: 16),
                  Expanded(child: _tileRow(2, 3)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.emoji_events),
                      label: const Text(
                        '도장판',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: controller.openBadges,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.grid_view),
                      label: const Text(
                        '구구단',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: controller.openTimesTable,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.bar_chart),
                      label: const Text(
                        '결과보기',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: controller.openRecords,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tileRow(int leftIdx, int rightIdx) {
    final left = GameType.values[leftIdx];
    final right = GameType.values[rightIdx];
    return Row(
      children: [
        Expanded(
          child: _GameTile(
            type: left,
            onTap: () => controller.selectGame(left),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _GameTile(
            type: right,
            onTap: () => controller.selectGame(right),
          ),
        ),
      ],
    );
  }
}

class _MuteToggle extends StatelessWidget {
  const _MuteToggle();

  @override
  Widget build(BuildContext context) {
    final sfx = Get.find<SfxService>();
    return Obx(
      () => IconButton(
        tooltip: sfx.isMuted.value ? '효과음 켜기' : '효과음 끄기',
        icon: Icon(
          sfx.isMuted.value ? Icons.volume_off : Icons.volume_up,
          size: 28,
        ),
        onPressed: sfx.toggleMute,
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A65), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 4),
          Text(
            '$days일 연속',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.bucket, required this.onTap});

  final WeaknessBucket bucket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (bucket.accuracy * 100).round();
    return Card(
      color: scheme.tertiaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.tertiary,
                child: Icon(
                  Icons.tips_and_updates,
                  color: scheme.onTertiary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘 ${bucket.type.label} 레벨 ${bucket.level} '
                      '연습 어때?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '최근 정답률 $percent%',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onTertiaryContainer.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: scheme.onTertiaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.type, required this.onTap});

  final GameType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                type.symbol,
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                type.label,
                style: TextStyle(
                  fontSize: 24,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
