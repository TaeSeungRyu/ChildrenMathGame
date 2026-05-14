import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'tutorial_controller.dart';

// To add / remove / edit a tutorial page, change this list. Everything else
// (PageView, dots, "다음" button label) adapts automatically.
const List<_TutorialPage> _pages = [
  _TutorialPage(
    icon: Icons.waving_hand,
    color: Color(0xFFFFA726),
    title: '환영해!',
    body:
        '함께 수학을 즐겁게 풀어보자.\n'
        '매일 조금씩 도전하면 실력이 쑥쑥 자랄 거야!',
  ),
  _TutorialPage(
    icon: Icons.calculate,
    color: Color(0xFF42A5F5),
    title: '연산을 골라봐',
    body:
        '덧셈, 뺄셈, 곱셈, 나눗셈.\n'
        '풀고 싶은 연산을 홈 화면에서 골라봐.',
  ),
  _TutorialPage(
    icon: Icons.timer,
    color: Color(0xFFEF5350),
    title: '3가지 모드',
    body:
        '도전 (180초 · 10문제) / 연습 (시간 없음) / 타임어택 (60초 무한).\n'
        '레벨 선택 화면에서 원하는 모드를 골라.',
  ),
  _TutorialPage(
    icon: Icons.local_fire_department,
    color: Color(0xFFFB8C00),
    title: '콤보와 도장',
    body:
        '정답을 연속으로 맞히면 콤보!\n'
        '많이 풀고 만점도 받으면 도장과 배지가 쌓여.',
  ),
  _TutorialPage(
    icon: Icons.insights,
    color: Color(0xFF66BB6A),
    title: '약점도 알려줄게',
    body:
        '내가 어떤 연산을 어려워하는지\n'
        '홈 화면에서 매일 추천해줄게.',
  ),
];

class TutorialView extends GetView<TutorialController> {
  const TutorialView({super.key});

  @override
  Widget build(BuildContext context) {
    // First-run: no back arrow, system back button intercepted. The only way
    // out is the "시작하기" button on the last page → finish() → home.
    return PopScope(
      canPop: !controller.isFirstRun,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '도움말',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          automaticallyImplyLeading: !controller.isFirstRun,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: controller.pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => controller.currentIndex.value = i,
                  itemBuilder: (_, i) => _PageBody(page: _pages[i]),
                ),
              ),
              const _DotsIndicator(),
              const SizedBox(height: 12),
              const _NavButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialPage {
  const _TutorialPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.page});

  final _TutorialPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 96, color: page.color),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends GetView<TutorialController> {
  const _DotsIndicator();

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = activeColor.withValues(alpha: 0.25);
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pages.length, (i) {
          final active = controller.currentIndex.value == i;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

class _NavButton extends GetView<TutorialController> {
  const _NavButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Obx(() {
          final isLast = controller.currentIndex.value >= _pages.length - 1;
          return FilledButton(
            onPressed: () {
              if (isLast) {
                controller.finish();
              } else {
                controller.pageController.nextPage(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              }
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text(isLast ? '시작하기' : '다음'),
          );
        }),
      ),
    );
  }
}
