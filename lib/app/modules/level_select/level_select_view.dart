import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import 'level_select_controller.dart';

class LevelSelectView extends GetView<LevelSelectController> {
  const LevelSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${controller.type.label} - 난이도 선택',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewPadding.bottom + 16,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 120,
              child: Lottie.asset(
                'assets/lottie/level_banner.json',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            const _ModeToggle(),
            const SizedBox(height: 16),
            ...List.generate(5, (i) {
              final level = i + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: FilledButton(
                    onPressed: () => controller.selectLevel(level),
                    child: Text(
                      '레벨 $level  (${_levelLabel(level)})',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _levelLabel(int level) {
    switch (level) {
      case 1:
        return '1자리수';
      case 2:
        return '2자리수+1자리수';
      case 3:
        return '2자리수+2자리수';
      case 4:
        return '3자리수+2자리수';
      case 5:
        return '3자리수+3자리수';
      default:
        return '';
    }
  }
}

class _ModeToggle extends GetView<LevelSelectController> {
  const _ModeToggle();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mode = controller.mode.value;
      // 4 tiles in a Row, each stacking icon-above-label vertically. This
      // avoids the SegmentedButton's horizontal squeeze that wrapped "타임
      // 어택" on narrow screens; each tile only needs ~50dp width for the
      // icon and text to coexist.
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ModeTile(
                  icon: Icons.timer,
                  label: '도전',
                  selected: mode == LevelSelectMode.challenge,
                  onTap: () => controller.setMode(LevelSelectMode.challenge),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ModeTile(
                  icon: Icons.flash_on,
                  label: '타임어택',
                  selected: mode == LevelSelectMode.timeAttack,
                  onTap: () => controller.setMode(LevelSelectMode.timeAttack),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ModeTile(
                  icon: Icons.all_inclusive,
                  label: '연속',
                  selected: mode == LevelSelectMode.endless,
                  onTap: () => controller.setMode(LevelSelectMode.endless),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ModeTile(
                  icon: Icons.spa,
                  label: '연습',
                  selected: mode == LevelSelectMode.practice,
                  onTap: () => controller.setMode(LevelSelectMode.practice),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _modeHint(mode),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      );
    });
  }

  String _modeHint(LevelSelectMode mode) {
    switch (mode) {
      case LevelSelectMode.challenge:
        return '180초 안에 10문제!';
      case LevelSelectMode.timeAttack:
        return '60초 동안 최대한 많이!';
      case LevelSelectMode.endless:
        return '틀릴 때까지! 몇 문제 연속 맞힐 수 있을까?';
      case LevelSelectMode.practice:
        return '시간 제한 없이 풀어요 (기록 미저장)';
    }
  }
}

// Stacked icon+label tile used in the mode picker Row. Selected state uses
// the primary fill; unselected uses a low-contrast outline so the focused
// option is unambiguous even on small screens.
class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: fg),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
