import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home_controller.dart';

/// 기록 탭 — 도장 / 오답 / 결과 / 통계 / 복습 5개 메타 허브. 기존 하단
/// quick-action 행(도장·오답·기록)을 카드 형태로 승격하고, 통계·복습을
/// 추가해 학습 메타 도구를 한 화면에 모았다.
class RecordsTab extends GetView<HomeController> {
  const RecordsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            icon: Icons.bar_chart,
            title: '학습 기록 & 도구',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              children: [
                _MetaCard(
                  icon: Icons.emoji_events,
                  iconBg: const Color(0xFFFFB300),
                  iconFg: Colors.white,
                  title: '도장판',
                  subtitle: '모은 도장과 뱃지를 확인해요',
                  onTap: controller.openBadges,
                ),
                const SizedBox(height: 10),
                _MetaCard(
                  icon: Icons.menu_book,
                  iconBg: const Color(0xFFEF5350),
                  iconFg: Colors.white,
                  title: '오답 노트',
                  subtitle: '틀린 문제를 다시 풀어요',
                  onTap: controller.openWrongNotebook,
                ),
                const SizedBox(height: 10),
                _MetaCard(
                  icon: Icons.history,
                  iconBg: const Color(0xFF42A5F5),
                  iconFg: Colors.white,
                  title: '결과 보기',
                  subtitle: '지난 게임 기록을 살펴봐요',
                  onTap: controller.openRecords,
                ),
                const SizedBox(height: 10),
                _MetaCard(
                  icon: Icons.insights,
                  iconBg: const Color(0xFF26A69A),
                  iconFg: Colors.white,
                  title: '학습 통계',
                  subtitle: '정답률과 약점을 한눈에',
                  onTap: controller.openStats,
                ),
                const SizedBox(height: 10),
                _MetaCard(
                  icon: Icons.replay,
                  iconBg: const Color(0xFF8E24AA),
                  iconFg: Colors.white,
                  title: '복습하기',
                  subtitle: '추천 받은 문제로 다시 도전',
                  onTap: controller.openReview,
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

class _MetaCard extends StatelessWidget {
  const _MetaCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surface,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconBg.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconFg, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
