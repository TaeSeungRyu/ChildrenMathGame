import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/models/coop_message.dart';
import '../../data/models/coop_session_record.dart';
import '../../data/models/game_type.dart';
import '../../data/services/coop_record_service.dart';
import '../../data/services/multiplayer/coop_session.dart';
import '../../data/services/sfx_service.dart';

/// One wrong answer, composed for the parent's "최근 오답" list.
class WrongEntry {
  const WrongEntry(this.expr, this.correctAnswer, this.userAnswer);
  final String expr;
  final int correctAnswer;
  final int? userAnswer;
}

/// Parent (coach) side of 부모와 함께하는 학습. Observes the child's live screen
/// (problem_state / attempt_result), and pushes coaching: difficulty changes
/// (set_difficulty), emoji reactions (coach_emoji), pause/resume.
class CoopCoachController extends GetxController with WidgetsBindingObserver {
  final SfxService _sfx = Get.find();
  final CoopRecordService _records = Get.find();
  final Stopwatch _stopwatch = Stopwatch()..start();
  bool _saved = false;
  bool _bgPaused = false;

  static const List<GameType?> opChoices = [
    GameType.addition,
    GameType.subtraction,
    GameType.multiplication,
    GameType.division,
    null,
  ];
  static const List<int> levelChoices = [1, 2, 3, 4, 5];
  static const List<String> emojiPalette = [
    '👍', '👏', '🎉', '❤️', '🔥', '😆', '💯', '⭐',
  ];
  static const int _maxRecentWrong = 5;

  late final CoopSession session;

  // Live mirror of the child's current problem.
  final RxList<int> operands = <int>[].obs;
  final RxString op = '+'.obs;
  final RxString typedAnswer = ''.obs;
  final RxInt problemIndex = 0.obs;
  final RxBool hasProblem = false.obs;

  final RxInt correctCount = 0.obs;
  final RxInt wrongCount = 0.obs;
  final RxList<WrongEntry> recentWrong = <WrongEntry>[].obs;

  final RxBool paused = false.obs;
  final RxBool ended = false.obs;
  final Rxn<SessionSummaryMessage> summary = Rxn<SessionSummaryMessage>();

  // Difficulty the parent is dialing in (mirrors what the child will use next).
  final Rxn<GameType> selectedOp = Rxn<GameType>();
  final RxInt selectedLevel = 1.obs;

  int _emojiId = 0;
  StreamSubscription<CoopMessage>? _sub;

  int get solvedTotal => correctCount.value + wrongCount.value;
  double get accuracy =>
      solvedTotal == 0 ? 0 : correctCount.value / solvedTotal;

  @override
  void onInit() {
    super.onInit();
    session = (Get.arguments as Map)['session'] as CoopSession;
    selectedOp.value = session.gameType;
    selectedLevel.value = session.level.value;
    _sub = session.messages.listen(_onMessage);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (ended.value) return;
    if (state == AppLifecycleState.resumed) {
      if (_bgPaused) {
        _bgPaused = false;
        paused.value = false;
        session.send(const SessionResumeMessage());
      }
    } else if (!paused.value) {
      _bgPaused = true;
      paused.value = true;
      session.send(const SessionPauseMessage());
    }
  }

  void _onMessage(CoopMessage m) {
    switch (m) {
      case ProblemStateMessage(
          :final operands,
          :final op,
          :final typedAnswer,
          :final index,
        ):
        this.operands.assignAll(operands);
        this.op.value = op;
        this.typedAnswer.value = typedAnswer;
        problemIndex.value = index;
        hasProblem.value = true;
      case AttemptResultMessage(
          :final correct,
          :final correctAnswer,
          :final userAnswer,
        ):
        if (correct) {
          correctCount.value += 1;
        } else {
          wrongCount.value += 1;
          recentWrong.insert(0, WrongEntry(_currentExpr(), correctAnswer, userAnswer));
          if (recentWrong.length > _maxRecentWrong) {
            recentWrong.removeLast();
          }
        }
      case SessionSummaryMessage():
        summary.value = m;
        ended.value = true;
        _saveRecord();
      case ByeMessage():
        ended.value = true;
        _saveRecord();
      default:
        break;
    }
  }

  void _saveRecord() {
    if (_saved) return;
    // Prefer the child's authoritative summary; fall back to what the parent
    // accumulated from attempt_results if the session ended without one.
    final s = summary.value;
    final correct = s?.correct ?? correctCount.value;
    final wrong = s?.wrong ?? wrongCount.value;
    if (correct + wrong == 0) return;
    _saved = true;
    final partner = session.partner.value;
    _records.add(
      CoopSessionRecord(
        finishedAt: DateTime.now(),
        partnerName: partner?.name ?? '아이',
        partnerAvatar: partner?.avatar ?? '🧒',
        gameType: session.gameType,
        level: session.level.value,
        correct: correct,
        wrong: wrong,
        elapsedSeconds:
            (s?.elapsedMs ?? _stopwatch.elapsedMilliseconds) ~/ 1000,
      ),
    );
  }

  String _currentExpr() {
    if (operands.isEmpty) return '';
    return operands.join(' ${op.value} ');
  }

  // ───── coaching controls ─────
  void setOp(GameType? o) {
    selectedOp.value = o;
    _pushDifficulty();
  }

  void setLevel(int level) {
    selectedLevel.value = level;
    _pushDifficulty();
  }

  void _pushDifficulty() {
    session.send(
      SetDifficultyMessage(
        gameType: selectedOp.value,
        level: selectedLevel.value,
      ),
    );
  }

  void sendEmoji(String emoji) {
    _emojiId += 1;
    session.send(CoachEmojiMessage(emoji: emoji, id: _emojiId));
    _sfx.click();
  }

  void togglePause() {
    paused.value = !paused.value;
    session.send(
      paused.value ? const SessionPauseMessage() : const SessionResumeMessage(),
    );
  }

  void endSession() {
    _saveRecord();
    session.send(const ByeMessage(reason: 'parent_ended'));
    Get.back();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _stopwatch.stop();
    super.onClose();
  }
}
