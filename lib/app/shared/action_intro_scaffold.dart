import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 액션 게임 인트로 화면의 공통 스캐폴드. 4개 게임이 동일한 골격을 공유하므로
/// 한 곳에서 레이아웃·간격·타이포를 통제한다. 게임별 차이는 [ActionIntroSpec]
/// 으로 주입한다. 각 게임 view는 이 위젯을 감싸는 얇은 GetView 래퍼.
///
/// 본 단계에서는 [onStart]가 호출되면 snackbar로 "준비 중" 안내만 띄우는
/// 사용 패턴을 권장한다(실제 게임 로직은 후속 단계에서 추가).
class ActionIntroScaffold extends StatelessWidget {
  const ActionIntroScaffold({
    super.key,
    required this.spec,
    required this.onStart,
  });

  final ActionIntroSpec spec;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          spec.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroCard(spec: spec),
            const SizedBox(height: 16),
            _HowToPlayCard(spec: spec),
            const SizedBox(height: 16),
            _ComingSoonNotice(accent: spec.accent),
            const SizedBox(height: 24),
            SizedBox(
              height: 68,
              child: FilledButton.icon(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: spec.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.play_arrow, size: 30),
                label: const Text(
                  '시작하기',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 게임별로 달라지는 스펙. 색상·아이콘·문구를 한 곳에 모아 인트로 화면 외에서도
/// 동일한 정체성으로 재사용할 수 있게 한다.
class ActionIntroSpec {
  const ActionIntroSpec({
    required this.title,
    required this.tagline,
    required this.icon,
    required this.bg,
    required this.accent,
    required this.fg,
    required this.howToPlay,
  });

  /// "몬스터 처치" 같은 게임 이름. AppBar / Hero에 표시.
  final String title;
  /// 짧은 부제 ("연산으로 공격!").
  final String tagline;
  /// 게임을 대표하는 아이콘.
  final IconData icon;
  /// Hero 카드의 배경.
  final Color bg;
  /// 강조색(시작 버튼 / 아이콘 등).
  final Color accent;
  /// Hero 본문/타이틀 위에 사용하는 진한 글자색.
  final Color fg;
  /// 게임 방법 설명 — 6~9세 기준 한 줄에 하나의 동작이 잘리지 않게 짧게.
  final List<String> howToPlay;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.spec});

  final ActionIntroSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: spec.accent.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: Icon(spec.icon, size: 48, color: spec.accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: spec.fg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  spec.tagline,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: spec.fg.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowToPlayCard extends StatelessWidget {
  const _HowToPlayCard({required this.spec});

  final ActionIntroSpec spec;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: spec.accent, size: 22),
              const SizedBox(width: 6),
              const Text(
                '이렇게 즐겨요',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < spec.howToPlay.length; i++) ...[
            _Step(index: i + 1, text: spec.howToPlay[i], accent: spec.accent),
            if (i != spec.howToPlay.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.text,
    required this.accent,
  });

  final int index;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.35),
            ),
          ),
        ),
      ],
    );
  }
}

class _ComingSoonNotice extends StatelessWidget {
  const _ComingSoonNotice({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.construction, color: accent, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '게임 모드는 곧 만나요. 화면 미리보기에요!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 인트로 화면에서 [ActionIntroScaffold.onStart]가 호출됐을 때 보일 표준
/// snackbar. 4개 게임 모두 동일 표현을 쓰도록 헬퍼로 묶는다.
void showComingSoonSnackbar(String gameTitle) {
  Get.snackbar(
    '준비 중',
    '$gameTitle 게임은 곧 만나요!',
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 2),
  );
}
