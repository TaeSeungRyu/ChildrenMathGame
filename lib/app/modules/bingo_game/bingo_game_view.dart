import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/action_score_service.dart';
import '../../shared/action_record_line.dart';
import 'bingo_game_controller.dart';

class BingoGameView extends GetView<BingoGameController> {
  const BingoGameView({super.key});

  static const _accent = Color(0xFF00796B);
  static const _deep = Color(0xFF004D40);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '수학 빙고',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Obx(
                () => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < BingoGameController.maxHp; i++)
                      Icon(
                        i < controller.hp.value
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 20,
                        color: i < controller.hp.value
                            ? const Color(0xFFE53935)
                            : Colors.white54,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '${controller.remainingSeconds}초',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: controller.remainingSeconds <= 10
                            ? const Color(0xFFE53935)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  const _GuideCard(),
                  const SizedBox(height: 12),
                  Obx(
                    () => _QuestionCard(
                      question: controller.current.questionText,
                      progress: controller.markedCount,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(child: _BingoBoard(controller: controller)),
                  const SizedBox(height: 8),
                  Text(
                    '식의 답과 같은 숫자를 눌러요',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            if (!controller.isGameOver.value) return const SizedBox.shrink();
            return _ResultOverlay(
              won: controller.isWin.value,
              score: controller.finalScore.value,
              best: Get.find<ActionScoreService>().bestFor(
                BingoGameController.concept,
              ),
              isNewBest: controller.isNewBest.value,
              onRestart: controller.restart,
              onHome: controller.exitToHome,
            );
          }),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF80CBC4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.grid_view_rounded, color: BingoGameView._accent),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '가로·세로·대각선 한 줄을 완성해요!',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.progress});

  final String question;
  final int progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF26A69A), Color(0xFF00796B)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: BingoGameView._accent.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$question = ?',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$progress/9',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BingoBoard extends StatelessWidget {
  const _BingoBoard({required this.controller});

  final BingoGameController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Obx(() {
          // Read reactive state here: itemBuilder runs after Obx's tracking
          // scope, so reads inside it alone do not subscribe to updates.
          final problems = controller.boardProblems.toList();
          final markedCells = controller.marked.toSet();
          final selectedCell = controller.selectedCell.value;
          final lastCorrect = controller.lastCorrect.value;
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
            ),
            itemCount: problems.length,
            itemBuilder: (context, index) {
              final marked = markedCells.contains(index);
              final selected = selectedCell == index;
              final wrong = selected && !lastCorrect;
              return _BingoCell(
                answer: problems[index].answer,
                marked: marked,
                wrong: wrong,
                onTap: () => controller.selectCell(index),
              );
            },
          );
        }),
      ),
    );
  }
}

class _BingoCell extends StatelessWidget {
  const _BingoCell({
    required this.answer,
    required this.marked,
    required this.wrong,
    required this.onTap,
  });

  final int answer;
  final bool marked;
  final bool wrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = marked
        ? const Color(0xFF26A69A)
        : wrong
        ? const Color(0xFFEF5350)
        : Theme.of(context).colorScheme.surface;
    final border = marked
        ? const Color(0xFF00695C)
        : wrong
        ? const Color(0xFFC62828)
        : const Color(0xFF80CBC4);
    final fg = marked || wrong
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: marked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 3),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '$answer',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
                ),
              ),
              if (marked)
                const Positioned(
                  right: 7,
                  top: 7,
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.won,
    required this.score,
    required this.best,
    required this.isNewBest,
    required this.onRestart,
    required this.onHome,
  });

  final bool won;
  final int score;
  final int best;
  final bool isNewBest;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.58),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(won ? '🎉' : '💪', style: const TextStyle(fontSize: 58)),
              const SizedBox(height: 6),
              Text(
                won ? '빙고!' : '다시 도전!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: BingoGameView._deep,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$score점',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ActionRecordLine(best: best, isNewBest: isNewBest),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onHome,
                      icon: const Icon(Icons.home),
                      label: const Text('홈으로'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onRestart,
                      icon: const Icon(Icons.replay),
                      label: const Text('다시'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
