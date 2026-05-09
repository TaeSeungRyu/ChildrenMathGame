import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/achievement_badge.dart';
import 'badges_controller.dart';

class BadgesView extends GetView<BadgesController> {
  const BadgesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '도장판',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewPadding.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryCard(
              unlocked: controller.unlockedCount,
              total: controller.totalCount,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: controller.badges.length,
                itemBuilder: (context, i) =>
                    _BadgeTile(status: controller.badges[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.unlocked, required this.total});

  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : unlocked / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '획득한 도장',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '$unlocked / $total',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.status});

  final BadgeStatus status;

  @override
  Widget build(BuildContext context) {
    final unlocked = status.unlocked;
    final badge = status.badge;
    final tileColor = unlocked ? badge.color.withValues(alpha: 0.12) : Colors.grey.shade200;
    final borderColor = unlocked ? badge.color : Colors.grey.shade400;
    final iconColor = unlocked ? badge.color : Colors.grey.shade500;
    final titleColor = unlocked ? Colors.black87 : Colors.grey.shade600;
    final descColor = unlocked ? Colors.black54 : Colors.grey.shade500;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: unlocked ? 2 : 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _BadgeIcon(badge: badge, color: iconColor, locked: !unlocked),
          const SizedBox(height: 8),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: descColor),
          ),
          if (!unlocked && status.hasProgress) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: status.progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(badge.color),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${status.current} / ${status.target}',
              style: TextStyle(fontSize: 11, color: descColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({
    required this.badge,
    required this.color,
    required this.locked,
  });

  final AchievementBadge badge;
  final Color color;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: locked ? Colors.grey.shade300 : color.withValues(alpha: 0.18),
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: badge.glyph != null
          ? Text(
              badge.glyph!,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            )
          : Icon(badge.icon, size: 32, color: color),
    );
  }
}
