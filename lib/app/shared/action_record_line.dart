import 'package:flutter/material.dart';

/// Small line shown inside an action mini-game's game-over overlay: either a
/// celebratory "새 기록!" banner when this run beat the stored best, or a plain
/// "최고 기록 N점" reminder otherwise. Keeps all six overlays visually
/// consistent from one place.
class ActionRecordLine extends StatelessWidget {
  const ActionRecordLine({
    super.key,
    required this.best,
    required this.isNewBest,
  });

  /// The stored best score for this concept (already includes this run).
  final int best;

  /// True when this run set a new record.
  final bool isNewBest;

  @override
  Widget build(BuildContext context) {
    if (isNewBest) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '🎉 새 기록 달성!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
      );
    }
    return Text(
      '🏆 최고 기록 $best점',
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8D6E63),
      ),
    );
  }
}
