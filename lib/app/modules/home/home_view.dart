import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../data/models/daily_mission.dart';
import '../../data/models/game_type.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/sfx_service.dart';
import '../../shared/weakness.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final name = Get.find<ProfileService>().name.value;
          return Text(
            '$name의 게임',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          );
        }),
        centerTitle: true,
        actions: const [_NameEditButton(), _MuteToggle()],
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
            _DailyMissionCard(
              missions: controller.missions,
              completed: controller.missionsCompleted,
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
                      icon: const Icon(Icons.emoji_events, size: 15),
                      label: const Text(
                        '도장',
                        style: TextStyle(fontSize: 15),
                      ),
                      onPressed: controller.openBadges,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.shuffle, size: 15),
                      label: const Text(
                        '혼합',
                        style: TextStyle(fontSize: 15),
                      ),
                      onPressed: controller.openMixed,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.grid_view, size: 15),
                      label: const Text(
                        '구구',
                        style: TextStyle(fontSize: 15),
                      ),
                      onPressed: controller.openTimesTable,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.bar_chart, size: 15),
                      label: const Text(
                        '기록',
                        style: TextStyle(fontSize: 15),
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

class _NameEditButton extends StatelessWidget {
  const _NameEditButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: '이름 바꾸기',
      icon: const Icon(Icons.person, size: 28),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => const _NameEditDialog(),
      ),
    );
  }
}

class _NameEditDialog extends StatefulWidget {
  const _NameEditDialog();

  @override
  State<_NameEditDialog> createState() => _NameEditDialogState();
}

class _NameEditDialogState extends State<_NameEditDialog> {
  // Owning the controller in a State (rather than the calling closure) lets
  // Flutter dispose it only after the TextField is fully torn down, avoiding
  // the InheritedElement `_dependents.isEmpty` assertion that fires when a
  // controller is disposed before its listeners have unregistered.
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final profile = Get.find<ProfileService>();
    _controller = TextEditingController(text: profile.name.value);
    // Pre-select so typing replaces the current value in one shot.
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    Get.find<ProfileService>().setName(_controller.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('이름 바꾸기'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: ProfileService.maxNameLength,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          hintText: '이름을 입력하세요',
          counterText: '',
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소', style: TextStyle(fontSize: 16)),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('저장', style: TextStyle(fontSize: 16)),
        ),
      ],
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

class _DailyMissionCard extends StatelessWidget {
  const _DailyMissionCard({required this.missions, required this.completed});

  final List<DailyMissionStatus> missions;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allDone = completed == missions.length && missions.isNotEmpty;
    return Card(
      color: allDone ? scheme.primary : scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  allDone ? Icons.celebration : Icons.flag,
                  size: 20,
                  color: allDone
                      ? scheme.onPrimary
                      : scheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  allDone ? '오늘의 미션 완료!' : '오늘의 미션',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: allDone
                        ? scheme.onPrimary
                        : scheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 18,
                      color: allDone
                          ? const Color(0xFFFFD54F)
                          : scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$completed / ${missions.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: allDone
                            ? scheme.onPrimary
                            : scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < missions.length; i++) ...[
              _MissionRow(status: missions[i], onPrimary: allDone),
              if (i != missions.length - 1) const SizedBox(height: 2),
            ],
          ],
        ),
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.status, required this.onPrimary});

  final DailyMissionStatus status;
  // True when parent card uses the primary (filled) background — text needs
  // onPrimary instead of onPrimaryContainer for contrast.
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = onPrimary ? scheme.onPrimary : scheme.onPrimaryContainer;
    final muted = base.withValues(alpha: 0.75);
    final done = status.isComplete;
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: done ? const Color(0xFF66BB6A) : muted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            status.mission.description,
            style: TextStyle(
              fontSize: 13,
              fontWeight: done ? FontWeight.w600 : FontWeight.normal,
              color: base,
              decoration: done ? TextDecoration.lineThrough : null,
              decorationColor: muted,
            ),
          ),
        ),
        Text(
          '${status.progressClamped} / ${status.mission.target}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
        ),
      ],
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
                  fontSize: 52,
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
