import 'dart:async';

import 'package:get/get.dart';

import '../../data/models/action_concept.dart';
import '../../data/models/game_type.dart';
import '../../data/models/problem.dart';
import '../../data/services/action_score_service.dart';
import '../../data/services/problem_generator.dart';
import '../../data/services/sfx_service.dart';

/// 3×3 수학 빙고.
///
/// 현재 식의 답과 같은 칸을 골라 표시하고, 가로·세로·대각선 한 줄을
/// 완성하면 승리한다. 같은 답이 여러 칸이면 원하는 칸을 고를 수 있어
/// 어린이도 빙고 줄을 직접 계획할 수 있다.
class BingoGameController extends GetxController {
  static const ActionConcept concept = ActionConcept.bingo;
  static const int boardSize = 9;
  static const int maxHp = 3;
  static const int totalSeconds = 90;
  static const int revealCorrectMs = 500;
  static const int revealWrongMs = 650;

  static const List<List<int>> winningLines = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  final SfxService _sfx = Get.find();
  final ActionScoreService _scores = Get.find();

  late final GameType? gameType;
  late final int digitsA;
  late final int digitsB;

  final RxList<Problem> boardProblems = <Problem>[].obs;
  final RxList<Problem> questionOrder = <Problem>[].obs;
  final RxSet<int> marked = <int>{}.obs;
  final RxInt questionIndex = 0.obs;
  final RxInt hp = maxHp.obs;
  final RxInt elapsed = 0.obs;
  final RxInt selectedCell = (-1).obs;
  final RxBool lastCorrect = false.obs;
  final RxBool isGameOver = false.obs;
  final RxBool isWin = false.obs;
  final RxBool isNewBest = false.obs;
  final RxInt finalScore = 0.obs;

  Timer? _secondTimer;
  Timer? _revealTimer;
  bool _locked = false;
  bool _reported = false;

  int get remainingSeconds =>
      (totalSeconds - elapsed.value).clamp(0, totalSeconds);
  Problem get current => questionOrder[questionIndex.value];
  int get markedCount => marked.length;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      gameType = args['gameType'] as GameType?;
      digitsA = (args['digitsA'] as int?) ?? 1;
      digitsB = (args['digitsB'] as int?) ?? 1;
    } else {
      gameType = GameType.addition;
      digitsA = 1;
      digitsB = 1;
    }
    _newBoard();
    _startTimer();
  }

  void _newBoard() {
    final problems = List.generate(
      boardSize,
      (_) => ProblemGenerator.generateOneForDigits(
        type: gameType,
        digitsA: digitsA,
        digitsB: digitsB,
      ),
    );
    boardProblems.assignAll(problems);
    questionOrder.assignAll(List<Problem>.of(problems)..shuffle());
    marked.clear();
    questionIndex.value = 0;
    selectedCell.value = -1;
  }

  bool isWinningSet(Set<int> cells) =>
      winningLines.any((line) => line.every(cells.contains));

  void selectCell(int index) {
    if (isGameOver.value || _locked || marked.contains(index)) return;
    if (index < 0 || index >= boardProblems.length) return;

    _locked = true;
    selectedCell.value = index;
    final correct = boardProblems[index].answer == current.answer;
    lastCorrect.value = correct;

    if (correct) {
      marked.add(index);
      _sfx.correct();
      if (isWinningSet(marked)) {
        _revealTimer = Timer(
          const Duration(milliseconds: revealCorrectMs),
          () => _finish(won: true),
        );
        return;
      }
      _revealTimer = Timer(
        const Duration(milliseconds: revealCorrectMs),
        _advanceQuestion,
      );
    } else {
      hp.value -= 1;
      _sfx.wrong();
      if (hp.value <= 0) {
        hp.value = 0;
        _revealTimer = Timer(
          const Duration(milliseconds: revealWrongMs),
          () => _finish(won: false),
        );
        return;
      }
      _revealTimer = Timer(const Duration(milliseconds: revealWrongMs), () {
        selectedCell.value = -1;
        _locked = false;
      });
    }
  }

  void _advanceQuestion() {
    selectedCell.value = -1;
    if (questionIndex.value + 1 >= questionOrder.length) {
      _finish(won: false);
      return;
    }
    questionIndex.value += 1;
    _locked = false;
  }

  int _scoreFor(bool won) {
    final base = markedCount * 100;
    if (!won) return base;
    return base + remainingSeconds * 10 + hp.value * 100;
  }

  void _startTimer() {
    _secondTimer?.cancel();
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isGameOver.value) return;
      elapsed.value += 1;
      if (elapsed.value >= totalSeconds) _finish(won: false);
    });
  }

  void _finish({required bool won}) {
    if (isGameOver.value) return;
    _locked = true;
    isWin.value = won;
    isGameOver.value = true;
    finalScore.value = _scoreFor(won);
    _secondTimer?.cancel();
    _secondTimer = null;
    _revealTimer?.cancel();
    _revealTimer = null;
    _sfx.finish();
    if (!_reported) {
      _reported = true;
      _scores
          .report(concept, finalScore.value)
          .then((value) => isNewBest.value = value);
    }
  }

  void restart() {
    _secondTimer?.cancel();
    _revealTimer?.cancel();
    hp.value = maxHp;
    elapsed.value = 0;
    isGameOver.value = false;
    isWin.value = false;
    isNewBest.value = false;
    finalScore.value = 0;
    lastCorrect.value = false;
    _locked = false;
    _reported = false;
    _newBoard();
    _startTimer();
  }

  void exitToHome() => Get.back();

  @override
  void onClose() {
    _secondTimer?.cancel();
    _revealTimer?.cancel();
    super.onClose();
  }
}
