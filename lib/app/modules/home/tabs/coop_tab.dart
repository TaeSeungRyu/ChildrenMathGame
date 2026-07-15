import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home_controller.dart';

/// 함께 탭 — "부모와 함께하는 학습" 허브. 두 개의 메뉴: 연결하기 / 기록보기.
/// 실제 연결/기록 화면은 후속 단계에서 연결한다(현재는 안내).
class CoopTab extends GetView<HomeController> {
  const CoopTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            icon: Icons.family_restroom,
            title: '부모와 함께하는 학습',
          ),
          const SizedBox(height: 4),
          Text(
            '두 기기를 가까이 두고 연결하면, 부모님이 옆에서 함께 도와줄 수 있어요.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          _CoopCard(
            icon: Icons.wifi_tethering,
            iconBg: const Color(0xFF42A5F5),
            title: '연결하기',
            subtitle: '방을 만들거나 참여해서 함께 시작해요',
            onTap: controller.openCoopLobby,
          ),
          const SizedBox(height: 10),
          _CoopCard(
            icon: Icons.history,
            iconBg: const Color(0xFF26A69A),
            title: '기록보기',
            subtitle: '함께 학습한 기록을 살펴봐요',
            onTap: controller.openCoopRecords,
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

class _CoopCard extends StatelessWidget {
  const _CoopCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
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
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
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
                child: Icon(icon, color: Colors.white, size: 28),
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
