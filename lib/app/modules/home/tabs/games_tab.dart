import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/action_concept.dart';
import '../home_controller.dart';

/// 게임 탭 — "연산 히어로"의 액션 게임 7종. 각 타일은 공통 진입 선택 화면으로
/// 라우팅한 뒤 컨셉별 본편으로 넘어간다. 7종 모두 플레이 가능.
class GamesTab extends GetView<HomeController> {
  const GamesTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 2열 그리드는 짝수 개일 때만 깔끔하게 떨어진다. 홀수면 마지막 한 종을
    // 그리드에서 빼서 아래에 가로형 카드로 눕혀, 빈 칸이 생기지 않게 한다.
    const specs = _GameSpec.all;
    final even = specs.length.isEven;
    final gridSpecs = even ? specs : specs.sublist(0, specs.length - 1);
    final tailSpec = even ? null : specs.last;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _IntroBanner(),
          const SizedBox(height: 12),
          const _SectionHeader(
            icon: Icons.sports_esports,
            title: '게임 모드',
          ),
          const SizedBox(height: 8),
          Expanded(
            // 타일이 3행 + 꼬리 카드라 작은 화면에선 본문 높이를 넘길 수 있어
            // 스크롤을 허용한다. 그리드 자체는 shrinkWrap 으로 자기 높이만 쓰고
            // 스크롤은 바깥 리스트가 담당한다.
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  // childAspectRatio < 1.0 → 세로가 더 길게. 6~9세 손가락에
                  // 충분히 큰 탭 영역.
                  childAspectRatio: 0.85,
                  children: [
                    for (final spec in gridSpecs)
                      _GameModeTile(
                        spec: spec,
                        onTap: () => controller.openActionSelect(spec.concept),
                      ),
                  ],
                ),
                if (tailSpec != null) ...[
                  const SizedBox(height: 12),
                  _WideGameModeTile(
                    spec: tailSpec,
                    onTap: () => controller.openActionSelect(tailSpec.concept),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "히어로의 모험이 시작돼요" 한 줄 설명 카드. 학습 탭의 미션 카드 위치와
/// 비슷한 시각 무게로 탭 진입 시 분위기를 잡아 준다.
class _IntroBanner extends StatelessWidget {
  const _IntroBanner();

  @override
  Widget build(BuildContext context) {
    // 보라→파랑 그라데이션. "히어로" 정체성에 맞춰 어두운 파랑 톤으로 통일.
    const start = Color(0xFF5C6BC0);
    const end = Color(0xFF3949AB);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [start, end],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: end.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '히어로의 모험',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '연산을 풀어 세상을 구해요!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
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

/// 게임 한 종을 표현할 자료. 색상·아이콘·설명을 한 곳에 묶어 두면
/// 인트로 화면에서도 동일 스펙을 재활용할 수 있어 일관성이 유지된다.
class _GameSpec {
  const _GameSpec({
    required this.concept,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.bg,
    required this.accent,
    required this.fg,
  });

  final ActionConcept concept;
  final String title;
  final String tagline;
  final IconData icon;
  final Color bg;
  final Color accent;
  final Color fg;

  /// 타일에 깔리는 순서. 새 게임은 뒤에 붙인다.
  static const all = [monster, balloon, tower, mole, ladder, fishing, balance];

  static const monster = _GameSpec(
    concept: ActionConcept.monster,
    title: '몬스터 처치',
    tagline: '연산으로 공격!',
    icon: Icons.shield,
    bg: Color(0xFFCE93D8),
    accent: Color(0xFF4A148C),
    fg: Color(0xFF4A148C),
  );

  static const balloon = _GameSpec(
    concept: ActionConcept.balloon,
    title: '풍선 터뜨리기',
    tagline: '같은 답을 골라요',
    icon: Icons.celebration,
    bg: Color(0xFFFFE082),
    accent: Color(0xFFE65100),
    fg: Color(0xFF5D4037),
  );

  static const tower = _GameSpec(
    concept: ActionConcept.tower,
    title: '타워 디펜스',
    tagline: '성을 지켜라!',
    icon: Icons.castle,
    bg: Color(0xFF80DEEA),
    accent: Color(0xFF006064),
    fg: Color(0xFF004D40),
  );

  static const mole = _GameSpec(
    concept: ActionConcept.mole,
    title: '두더지 잡기',
    tagline: '빠르게 답을 입력!',
    icon: Icons.gps_fixed,
    bg: Color(0xFFC5E1A5),
    accent: Color(0xFF33691E),
    fg: Color(0xFF1B5E20),
  );

  static const ladder = _GameSpec(
    concept: ActionConcept.ladder,
    title: '숫자 사다리',
    tagline: '정답 칸을 밟아요',
    icon: Icons.stairs,
    bg: Color(0xFFFFCC80),
    accent: Color(0xFFE65100),
    fg: Color(0xFF5D4037),
  );

  static const fishing = _GameSpec(
    concept: ActionConcept.fishing,
    title: '물고기 잡기',
    tagline: '정답을 낚아요',
    icon: Icons.set_meal,
    bg: Color(0xFFB3E5FC),
    accent: Color(0xFF00838F),
    fg: Color(0xFF01579B),
  );

  static const balance = _GameSpec(
    concept: ActionConcept.balance,
    title: '저울 맞추기',
    tagline: '어느 쪽이 클까?',
    icon: Icons.balance,
    bg: Color(0xFFF8BBD0),
    accent: Color(0xFFAD1457),
    fg: Color(0xFF880E4F),
  );
}

/// 2열 그리드에서 짝이 안 맞는 마지막 한 종을 위한 가로형 타일. 그리드 타일과
/// 같은 색·아이콘을 쓰되 아이콘을 왼쪽에 두고 눕혀서, 빈 칸 대신 "한 줄 더"로
/// 읽히게 한다.
class _WideGameModeTile extends StatelessWidget {
  const _WideGameModeTile({required this.spec, required this.onTap});

  final _GameSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: spec.bg,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: Icon(spec.icon, size: 34, color: spec.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      spec.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: spec.fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spec.tagline,
                      style: TextStyle(
                        fontSize: 12,
                        color: spec.fg.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: spec.fg.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameModeTile extends StatelessWidget {
  const _GameModeTile({required this.spec, required this.onTap});

  final _GameSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: spec.bg,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      spec.icon,
                      size: 40,
                      color: spec.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                spec.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: spec.fg,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                spec.tagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: spec.fg.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
