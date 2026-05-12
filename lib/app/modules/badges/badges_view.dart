import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/achievement_badge.dart';
import '../../data/models/custom_stamp.dart';
import 'badges_controller.dart';
import 'custom_stamp_editor.dart';

// `BadgesController.customStampStatuses` is the source of truth for tile
// state — earned/progress are derived there.

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
            Obx(
              () => _SummaryCard(
                unlocked: controller.unlockedCount,
                total: controller.totalCount,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final builtin = controller.badges;
                final customStatuses = controller.customStampStatuses;
                // +1 for the trailing "add" tile.
                final itemCount = builtin.length + customStatuses.length + 1;
                return GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, i) {
                    if (i < builtin.length) {
                      return _BadgeTile(status: builtin[i]);
                    }
                    final customIndex = i - builtin.length;
                    if (customIndex < customStatuses.length) {
                      final s = customStatuses[customIndex];
                      return _CustomStampTile(
                        status: s,
                        // Auto stamps can't be manually toggled — tap is no-op.
                        onTap: s.isAuto
                            ? null
                            : () => controller.toggleCustomEarned(s.stamp.id),
                        onEdit: () =>
                            _openEditor(context, existing: s.stamp),
                        onDelete: () => _confirmDelete(context, s.stamp),
                      );
                    }
                    return _AddStampTile(
                      onTap: () => _openEditor(context),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    CustomStamp? existing,
  }) async {
    final result = await showModalBottomSheet<CustomStampDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CustomStampEditor(initial: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await controller.addCustomStamp(
        title: result.title,
        emoji: result.emoji,
        colorValue: result.colorValue,
        condition: result.condition,
      );
    } else {
      await controller.updateCustomStamp(
        existing.copyWith(
          title: result.title,
          emoji: result.emoji,
          colorValue: result.colorValue,
          condition: result.condition,
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, CustomStamp stamp) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('도장 삭제'),
        content: Text("'${stamp.title}' 도장을 삭제할까요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.deleteCustomStamp(stamp.id);
    }
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
    final tileColor = unlocked
        ? badge.color.withValues(alpha: 0.12)
        : Colors.grey.shade200;
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

class _CustomStampTile extends StatelessWidget {
  const _CustomStampTile({
    required this.status,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomStampStatus status;
  // Null disables tap (used for auto stamps — they can't be toggled by hand).
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final stamp = status.stamp;
    final earned = status.earned;
    final color = Color(stamp.colorValue);
    final tileColor = earned
        ? color.withValues(alpha: 0.12)
        : Colors.grey.shade200;
    final borderColor = earned ? color : Colors.grey.shade400;
    final titleColor = earned ? Colors.black87 : Colors.grey.shade600;

    return InkWell(
      onTap: onTap,
      onLongPress: () => _showActionsSheet(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: earned ? 2 : 1),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: PopupMenuButton<String>(
                tooltip: '메뉴',
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('편집')),
                  PopupMenuItem(value: 'delete', child: Text('삭제')),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CustomStampIcon(
                    emoji: stamp.emoji,
                    color: color,
                    earned: earned,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stamp.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (status.isAuto)
                    _AutoStampFooter(status: status, color: color)
                  else
                    Text(
                      earned ? '받았어요!' : '눌러서 도장 받기',
                      style: TextStyle(
                        fontSize: 11,
                        color: earned ? color : Colors.grey.shade500,
                        fontWeight: earned ? FontWeight.w600 : null,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('편집'),
              onTap: () {
                Navigator.of(ctx).pop();
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                '삭제',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoStampFooter extends StatelessWidget {
  const _AutoStampFooter({required this.status, required this.color});

  final CustomStampStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final stamp = status.stamp;
    final earned = status.earned;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            stamp.condition!.describe(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: status.progressRatio,
            minHeight: 6,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          earned
              ? '받았어요! (${status.progress} / ${status.target})'
              : '${status.progress} / ${status.target}',
          style: TextStyle(
            fontSize: 11,
            color: earned ? color : Colors.grey.shade600,
            fontWeight: earned ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}

class _CustomStampIcon extends StatelessWidget {
  const _CustomStampIcon({
    required this.emoji,
    required this.color,
    required this.earned,
  });

  final String emoji;
  final Color color;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: earned ? color.withValues(alpha: 0.18) : Colors.grey.shade300,
        border: Border.all(
          color: earned ? color : Colors.grey.shade400,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      // Grayscale tint when unearned — emoji rendering pipeline doesn't let us
      // recolor directly, so use ColorFiltered with a saturation matrix.
      child: earned
          ? Text(emoji, style: const TextStyle(fontSize: 30))
          : ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0,      0,      0,      1, 0,
              ]),
              child: Text(emoji, style: const TextStyle(fontSize: 30)),
            ),
    );
  }
}

class _AddStampTile extends StatelessWidget {
  const _AddStampTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: DottedBorder(
        color: scheme.primary,
        radius: 12,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.add, size: 36, color: scheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                '새 도장 만들기',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal dashed border helper — avoids pulling a dependency. Paints a
/// rounded rect with a dashed stroke around the child.
class DottedBorder extends StatelessWidget {
  const DottedBorder({
    super.key,
    required this.child,
    required this.color,
    this.radius = 12,
  });

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    // Walk along the path and stroke 6px-on, 4px-off segments.
    const dashOn = 6.0;
    const dashOff = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dashOn;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance = end + dashOff;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
