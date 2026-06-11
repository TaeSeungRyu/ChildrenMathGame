import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/action_concept.dart';
import '../home_controller.dart';

/// 게임 탭 — "연산 히어로"의 액션 게임 4종. 각 타일은 인트로 화면으로 라우팅.
/// 본 단계에서는 실제 플레이 로직 없이 셸만 작성된 상태이며, NEW 배지로
/// "곧 열려요" 상태를 표시한다.
class GamesTab extends GetView<HomeController> {
  const GamesTab({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              // childAspectRatio < 1.0 → 세로가 더 길게. 2x2 그리드가 본문
              // 잔여 높이를 꽉 채우면서 6~9세 손가락에 충분히 큰 탭 영역.
              childAspectRatio: 0.85,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _GameModeTile(
                  spec: _GameSpec.monster,
                  onTap: () =>
                      controller.openActionSelect(ActionConcept.monster),
                ),
                _GameModeTile(
                  spec: _GameSpec.balloon,
                  onTap: () =>
                      controller.openActionSelect(ActionConcept.balloon),
                ),
                _GameModeTile(
                  spec: _GameSpec.tower,
                  onTap: () => controller.openActionSelect(ActionConcept.tower),
                ),
                _GameModeTile(
                  spec: _GameSpec.mole,
                  onTap: () => controller.openActionSelect(ActionConcept.mole),
                ),
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
    required this.title,
    required this.tagline,
    required this.icon,
    required this.bg,
    required this.accent,
    required this.fg,
  });

  final String title;
  final String tagline;
  final IconData icon;
  final Color bg;
  final Color accent;
  final Color fg;

  static const monster = _GameSpec(
    title: '몬스터 처치',
    tagline: '연산으로 공격!',
    icon: Icons.shield,
    bg: Color(0xFFCE93D8),
    accent: Color(0xFF4A148C),
    fg: Color(0xFF4A148C),
  );

  static const balloon = _GameSpec(
    title: '풍선 터뜨리기',
    tagline: '같은 답을 골라요',
    icon: Icons.celebration,
    bg: Color(0xFFFFE082),
    accent: Color(0xFFE65100),
    fg: Color(0xFF5D4037),
  );

  static const tower = _GameSpec(
    title: '타워 디펜스',
    tagline: '성을 지켜라!',
    icon: Icons.castle,
    bg: Color(0xFF80DEEA),
    accent: Color(0xFF006064),
    fg: Color(0xFF004D40),
  );

  static const mole = _GameSpec(
    title: '두더지 잡기',
    tagline: '빠르게 답을 입력!',
    icon: Icons.gps_fixed,
    bg: Color(0xFFC5E1A5),
    accent: Color(0xFF33691E),
    fg: Color(0xFF1B5E20),
  );
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
        child: Stack(
          children: [
            Padding(
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
            // 우상단 NEW 배지 — 모든 게임이 신규 단계이므로 일괄 부착.
            // 구현 완료 후 spec.released 같은 필드로 켜고 끌 수 있게 확장.
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
