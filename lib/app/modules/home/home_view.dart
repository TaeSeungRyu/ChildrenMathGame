import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/profile_service.dart';
import '../../data/services/sfx_service.dart';
import '../../routes/app_routes.dart';
import 'home_controller.dart';
import 'tabs/games_tab.dart';
import 'tabs/learn_tab.dart';
import 'tabs/records_tab.dart';

/// Home is now a 3-tab container (학습 / 게임 / 기록). The AppBar stays shared
/// across tabs so the editable name, tutorial entry, and mute toggle remain
/// available everywhere. Body switches via `IndexedStack` so each tab keeps
/// its scroll position and rebuild cost when the user toggles between them.
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
      body: Obx(
        () => IndexedStack(
          index: controller.tabIndex.value,
          children: const [LearnTab(), GamesTab(), RecordsTab()],
        ),
      ),
      bottomNavigationBar: const _HomeNavBar(),
    );
  }
}

/// 앱 톤(크림 + 스카이블루 AppBar)과 어울리도록 색을 입힌 NavigationBar.
///
/// - 배경: 따뜻한 베이지(`#F5E6CA`) — 학습 탭의 _SpecialTile과 동일 톤이라
///   앱의 "secondary surface"로 일관된다.
/// - 선택 인디케이터: 스카이블루(`#4FC3F7`) — AppBar 배경과 동일하므로
///   "현재 탭이 상단 AppBar의 정체성과 연결돼 있다"는 시각 단서가 된다.
/// - 선택 아이콘: 흰색(스카이블루 인디케이터 위에서 가독성 ↑).
/// - 선택 라벨: 진한 다크브라운(`#3E2723`, AppBar 타이틀과 동일).
/// - 비선택: 시에나브라운(`#6D4C41`)의 70% 알파.
/// - 상단에 얇은 베이지 디바이더를 두어 크림 스캐폴드와 분리.
class _HomeNavBar extends GetView<HomeController> {
  const _HomeNavBar();

  static const _bg = Color(0xFFF5E6CA);
  static const _indicator = Color(0xFF4FC3F7);
  static const _selectedLabel = Color(0xFF3E2723);
  static const _muted = Color(0xFF6D4C41);
  static const _divider = Color(0xFFE6DAB8);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _divider, width: 1)),
      ),
      child: Obx(
        () => NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: _bg,
            indicatorColor: _indicator,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected ? Colors.white : _muted.withValues(alpha: 0.70),
                size: 26,
              );
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected
                    ? _selectedLabel
                    : _muted.withValues(alpha: 0.75),
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: controller.tabIndex.value,
            onDestinationSelected: controller.setTab,
            // Shorter than the 80dp default. Combined with the trimmed
            // banner/card/section sizes in learn_tab.dart, this keeps the 학습
            // 탭 본문이 Galaxy S25 클래스(세로 ~780dp logical, body ~600dp)에서
            // 스크롤 없이 들어맞도록 한다.
            height: 68,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: '학습',
              ),
              NavigationDestination(
                icon: Icon(Icons.sports_esports_outlined),
                selectedIcon: Icon(Icons.sports_esports),
                label: '게임',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: '기록',
              ),
            ],
          ),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$name 히어로!',
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
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final profile = Get.find<ProfileService>();
    _controller = TextEditingController(text: profile.name.value);
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
