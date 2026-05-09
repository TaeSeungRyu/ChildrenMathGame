import 'package:flutter/material.dart';

import '../data/models/achievement_badge.dart';
import '../data/models/game_record.dart';
import '../data/models/game_type.dart';

const _firstGame = AchievementBadge(
  id: 'first_game',
  title: '첫 도전',
  description: '게임을 1번 완료',
  icon: Icons.flag,
  color: Color(0xFF26A69A),
);
const _firstPerfect = AchievementBadge(
  id: 'first_perfect',
  title: '첫 만점',
  description: '한 게임 모두 정답',
  icon: Icons.star,
  color: Color(0xFFFFB300),
);
const _correct50 = AchievementBadge(
  id: 'correct_50',
  title: '꾸준한 풀이',
  description: '누적 정답 50개',
  icon: Icons.school,
  color: Color(0xFF42A5F5),
);
const _correct100 = AchievementBadge(
  id: 'correct_100',
  title: '백문백답',
  description: '누적 정답 100개',
  icon: Icons.auto_stories,
  color: Color(0xFF5C6BC0),
);
const _correct300 = AchievementBadge(
  id: 'correct_300',
  title: '수학 박사',
  description: '누적 정답 300개',
  icon: Icons.psychology,
  color: Color(0xFF7E57C2),
);
const _streak3 = AchievementBadge(
  id: 'streak_3',
  title: '3일 연속',
  description: '3일 연속 플레이',
  icon: Icons.local_fire_department,
  color: Color(0xFFFF7043),
);
const _streak7 = AchievementBadge(
  id: 'streak_7',
  title: '7일 연속',
  description: '7일 연속 플레이',
  icon: Icons.whatshot,
  color: Color(0xFFEF5350),
);
const _streak30 = AchievementBadge(
  id: 'streak_30',
  title: '30일 연속',
  description: '30일 연속 플레이',
  icon: Icons.bolt,
  color: Color(0xFFD81B60),
);
const _addMaster = AchievementBadge(
  id: 'add_master',
  title: '덧셈 마스터',
  description: '덧셈 레벨 5 만점',
  glyph: '+',
  color: Color(0xFF66BB6A),
);
const _subMaster = AchievementBadge(
  id: 'sub_master',
  title: '뺄셈 마스터',
  description: '뺄셈 레벨 5 만점',
  glyph: '−',
  color: Color(0xFF29B6F6),
);
const _mulMaster = AchievementBadge(
  id: 'mul_master',
  title: '곱셈 마스터',
  description: '곱셈 레벨 5 만점',
  glyph: '×',
  color: Color(0xFFAB47BC),
);
const _divMaster = AchievementBadge(
  id: 'div_master',
  title: '나눗셈 마스터',
  description: '나눗셈 레벨 5 만점',
  glyph: '÷',
  color: Color(0xFFEC407A),
);
const _perfect5 = AchievementBadge(
  id: 'perfect_5',
  title: '만점 5회',
  description: '만점 게임 5회',
  icon: Icons.workspace_premium,
  color: Color(0xFFFFA726),
);
const _perfect20 = AchievementBadge(
  id: 'perfect_20',
  title: '만점 20회',
  description: '만점 게임 20회',
  icon: Icons.military_tech,
  color: Color(0xFFFF8F00),
);
const _allOpsPerfect = AchievementBadge(
  id: 'all_ops_perfect',
  title: '사칙연산 정복',
  description: '4가지 연산 모두 만점',
  icon: Icons.emoji_events,
  color: Color(0xFFFFC107),
);

const allBadges = <AchievementBadge>[
  _firstGame,
  _firstPerfect,
  _correct50,
  _correct100,
  _correct300,
  _streak3,
  _streak7,
  _streak30,
  _addMaster,
  _subMaster,
  _mulMaster,
  _divMaster,
  _perfect5,
  _perfect20,
  _allOpsPerfect,
];

bool _isPerfect(GameRecord r) =>
    r.totalCount > 0 && r.correctCount == r.totalCount;

List<BadgeStatus> evaluateBadges(
  List<GameRecord> records, {
  required int maxStreak,
}) {
  final totalCorrect = records.fold<int>(0, (s, r) => s + r.correctCount);
  final perfectCount = records.where(_isPerfect).length;
  final perfectOps = <GameType>{
    for (final r in records)
      if (_isPerfect(r)) r.type,
  };
  bool hasMasterFor(GameType t) => records.any(
    (r) => r.type == t && r.level == 5 && _isPerfect(r),
  );

  return [
    BadgeStatus.simple(badge: _firstGame, unlocked: records.isNotEmpty),
    BadgeStatus.simple(badge: _firstPerfect, unlocked: perfectCount >= 1),
    BadgeStatus.progress(
      badge: _correct50,
      current: totalCorrect,
      target: 50,
    ),
    BadgeStatus.progress(
      badge: _correct100,
      current: totalCorrect,
      target: 100,
    ),
    BadgeStatus.progress(
      badge: _correct300,
      current: totalCorrect,
      target: 300,
    ),
    BadgeStatus.progress(badge: _streak3, current: maxStreak, target: 3),
    BadgeStatus.progress(badge: _streak7, current: maxStreak, target: 7),
    BadgeStatus.progress(badge: _streak30, current: maxStreak, target: 30),
    BadgeStatus.simple(
      badge: _addMaster,
      unlocked: hasMasterFor(GameType.addition),
    ),
    BadgeStatus.simple(
      badge: _subMaster,
      unlocked: hasMasterFor(GameType.subtraction),
    ),
    BadgeStatus.simple(
      badge: _mulMaster,
      unlocked: hasMasterFor(GameType.multiplication),
    ),
    BadgeStatus.simple(
      badge: _divMaster,
      unlocked: hasMasterFor(GameType.division),
    ),
    BadgeStatus.progress(
      badge: _perfect5,
      current: perfectCount,
      target: 5,
    ),
    BadgeStatus.progress(
      badge: _perfect20,
      current: perfectCount,
      target: 20,
    ),
    BadgeStatus.simple(
      badge: _allOpsPerfect,
      unlocked: perfectOps.length == GameType.values.length,
    ),
  ];
}
