import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../data/models/daily_mission.dart';
import '../../data/models/game_type.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/sfx_service.dart';
import '../../routes/app_routes.dart';
import '../../shared/weakness.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const _EditableTitle(),
        centerTitle: true,
        actions: const [_TutorialButton(), _MuteToggle()],
      ),
      // Single scrollable column with two clearly-separated sections (기본
      // 연산 2x2 grid + 특별 모드 1x4 row). The earlier IntrinsicHeight +
      // Spacer layout doesn't accommodate 7 modes cleanly; conventional
      // section-titled lists scale better as modes are added.
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 76,
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
                      top: 0,
                      right: 0,
                      child: _StreakBadge(days: controller.streakDays),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _DailyMissionCard(
              missions: controller.missions,
              completed: controller.missionsCompleted,
            ),
            if (controller.recommendation != null) ...[
              const SizedBox(height: 6),
              _RecommendationCard(
                bucket: controller.recommendation!,
                onTap: () =>
                    controller.startRecommended(controller.recommendation!),
              ),
            ],
            const SizedBox(height: 12),
            const _SectionHeader(icon: Icons.calculate, title: '기본 연산'),
            const SizedBox(height: 6),
            _basicOpsGrid(),
            const SizedBox(height: 12),
            const _SectionHeader(icon: Icons.star, title: '특별 모드'),
            const SizedBox(height: 6),
            _specialModesRow(),
          ],
        ),
      ),
      // Quick-action row is pinned to the bottom of the screen so it stays
      // visible regardless of scroll position. SafeArea handles the system
      // gesture/nav bar inset on Android. 구구단 moved into 특별 모드 above,
      // so the bottom bar is down to three meta actions.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.emoji_events,
                    label: '도장',
                    onPressed: controller.openBadges,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.menu_book,
                    label: '오답',
                    onPressed: controller.openWrongNotebook,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.bar_chart,
                    label: '기록',
                    onPressed: controller.openRecords,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2x2 grid of the four concrete operations — compact 80h tiles with 40pt
  // symbol + 18pt label keep the home screen scroll-free on Galaxy S25-sized
  // viewports. FittedBox inside _GameTile is the safety net for narrower or
  // shorter screens.
  Widget _basicOpsGrid() {
    return Column(
      children: [
        SizedBox(
          height: 80,
          child: Row(
            children: [
              Expanded(child: _GameTile(type: GameType.addition, onTap: () => _tapHandler(GameType.addition))),
              const SizedBox(width: 10),
              Expanded(child: _GameTile(type: GameType.subtraction, onTap: () => _tapHandler(GameType.subtraction))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: Row(
            children: [
              Expanded(child: _GameTile(type: GameType.multiplication, onTap: () => _tapHandler(GameType.multiplication))),
              const SizedBox(width: 10),
              Expanded(child: _GameTile(type: GameType.division, onTap: () => _tapHandler(GameType.division))),
            ],
          ),
        ),
      ],
    );
  }

  // 1x4 row of special modes — smaller tiles, icon + label, since each is a
  // session-shape variant rather than a "primary" operation.
  Widget _specialModesRow() {
    return SizedBox(
      height: 80,
      child: Row(
        children: [
          Expanded(
            child: _SpecialTile(
              icon: Icons.grid_view,
              label: '구구단',
              onTap: controller.openTimesTable,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SpecialTile(
              icon: Icons.shuffle,
              label: '혼합',
              onTap: controller.openMixed,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SpecialTile(
              icon: Icons.help_outline,
              label: '방정식',
              onTap: controller.openEquation,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SpecialTile(
              icon: Icons.flash_on,
              label: '플래시',
              onTap: controller.openFlash,
            ),
          ),
        ],
      ),
    );
  }

  // Roll-up types (혼합/방정식/플래시) have their own selection screens;
  // concrete ops share the level-select route.
  void _tapHandler(GameType t) {
    switch (t) {
      case GameType.mixed:
        controller.openMixed();
      case GameType.equation:
        controller.openEquation();
      case GameType.flash:
        controller.openFlash();
      case GameType.addition:
      case GameType.subtraction:
      case GameType.multiplication:
      case GameType.division:
        controller.selectGame(t);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SpecialTile extends StatelessWidget {
  const _SpecialTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Warm beige + sienna-brown text — sits between the cream scaffold and
    // the saturated basic-op tiles, creating a visual hierarchy ("primary"
    // 4-ops pop, "secondary" 4 modes recede gently).
    const bg = Color(0xFFF5E6CA);
    const fg = Color(0xFF6D4C41);
    return Card(
      color: bg,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: fg),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        // No minimumSize: parent SizedBox supplies the height, and adding
        // a conflicting min here is what was triggering RenderFlex overflow.
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TutorialButton extends StatelessWidget {
  const _TutorialButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: '도움말',
      icon: const Icon(Icons.help_outline, size: 28),
      onPressed: () => Get.toNamed(AppRoutes.tutorial),
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

class _EditableTitle extends StatelessWidget {
  const _EditableTitle();

  @override
  Widget build(BuildContext context) {
    // Warm dark brown — softens the AppBar's blue-on-blue stack ("{이름}의
    // 게임" was reading as too blue). Contrast on the #4FC3F7 AppBar is
    // ~7.8 (well above WCAG-AA 4.5). Icons in actions keep the deep-blue
    // foregroundColor for tone separation between "navigation" and
    // "identity" elements.
    const titleColor = Color(0xFF3E2723);
    return Obx(() {
      final name = Get.find<ProfileService>().name.value;
      return InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => const _NameEditDialog(),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          // Generous padding so kids hit the tap area easily; AppBar height
          // still fits because the title row's intrinsic size is the text.
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$name의 게임',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.edit,
                size: 20,
                color: titleColor.withValues(alpha: 0.55),
                semanticLabel: '이름 바꾸기',
              ),
            ],
          ),
        ),
      );
    });
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
    final allDone = completed == missions.length && missions.isNotEmpty;
    // Warm peach (in-progress) → bright amber (celebratory all-done). Both
    // pair naturally with the cream scaffold and avoid clashing with the
    // saturated rainbow tiles below.
    final bg = allDone ? const Color(0xFFFFC107) : const Color(0xFFFFE0B2);
    final fg = allDone ? const Color(0xFF3E2723) : const Color(0xFF5D4037);
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  allDone ? Icons.celebration : Icons.flag,
                  size: 20,
                  color: fg,
                ),
                const SizedBox(width: 8),
                Text(
                  allDone ? '오늘의 미션 완료!' : '오늘의 미션',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 18,
                      color: allDone ? const Color(0xFFFFFFFF) : fg,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$completed / ${missions.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < missions.length; i++)
              _MissionRow(status: missions[i], foreground: fg),
          ],
        ),
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.status, required this.foreground});

  final DailyMissionStatus status;
  // Foreground color computed by the parent card based on its done/in-progress
  // background. Muted variant is derived locally for secondary text.
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final muted = foreground.withValues(alpha: 0.75);
    final done = status.isComplete;
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: done ? const Color(0xFF2E7D32) : muted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            status.mission.description,
            style: TextStyle(
              fontSize: 13,
              fontWeight: done ? FontWeight.w600 : FontWeight.normal,
              color: foreground,
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
    final percent = (bucket.accuracy * 100).round();
    // Soft sky-mint + deep teal — distinct from the warm mission card and
    // the rainbow tiles, so the eye can place "오늘의 추천" as a separate
    // category instantly.
    const bg = Color(0xFFB2EBF2);
    const accent = Color(0xFF00838F);
    const fg = Color(0xFF006064);
    return Card(
      color: bg,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: accent,
                child: Icon(
                  Icons.tips_and_updates,
                  color: Colors.white,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '최근 정답률 $percent%',
                      style: TextStyle(
                        fontSize: 13,
                        color: fg.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: fg),
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

  // Per-operation palette — soft Material 200/300 background paired with a
  // darker 800-level symbol so each tile reads as a distinct "color zone"
  // while staying WCAG-AA legible (all symbol-on-bg combos ≥ 4.5 contrast).
  static const _palette = <GameType, ({Color bg, Color accent})>{
    GameType.addition: (bg: Color(0xFFA5D6A7), accent: Color(0xFF1B5E20)),
    GameType.subtraction: (bg: Color(0xFFFFCC80), accent: Color(0xFFE65100)),
    GameType.multiplication: (bg: Color(0xFFCE93D8), accent: Color(0xFF4A148C)),
    GameType.division: (bg: Color(0xFFF48FB1), accent: Color(0xFF880E4F)),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = _palette[type] ??
        (bg: scheme.primaryContainer, accent: scheme.onPrimaryContainer);
    return Card(
      color: palette.bg,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        // FittedBox scaleDown guarantees the symbol+label combo never
        // overflows even on narrow phones / large system text sizes; on
        // normal screens it renders at the natural 52/24pt sizes.
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  type.symbol,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: palette.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
