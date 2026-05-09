import 'package:flutter/material.dart';

class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    this.icon,
    this.glyph,
  }) : assert(icon != null || glyph != null);

  final String id;
  final String title;
  final String description;
  final Color color;
  final IconData? icon;
  final String? glyph;
}

class BadgeStatus {
  const BadgeStatus({
    required this.badge,
    required this.unlocked,
    this.current,
    this.target,
  });

  factory BadgeStatus.simple({
    required AchievementBadge badge,
    required bool unlocked,
  }) {
    return BadgeStatus(badge: badge, unlocked: unlocked);
  }

  factory BadgeStatus.progress({
    required AchievementBadge badge,
    required int current,
    required int target,
  }) {
    return BadgeStatus(
      badge: badge,
      unlocked: current >= target,
      current: current,
      target: target,
    );
  }

  final AchievementBadge badge;
  final bool unlocked;
  final int? current;
  final int? target;

  bool get hasProgress => current != null && target != null;
  double get progress {
    if (!hasProgress || target! <= 0) return unlocked ? 1.0 : 0.0;
    return (current! / target!).clamp(0.0, 1.0);
  }
}
