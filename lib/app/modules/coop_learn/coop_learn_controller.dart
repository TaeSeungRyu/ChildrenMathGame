import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/models/coop_message.dart';
import '../../data/models/coop_session_record.dart';
import '../../data/models/game_type.dart';
import '../../data/models/problem.dart';
import '../../data/models/problem_attempt.dart';
import '../../data/services/coop_record_service.dart';
import '../../data/services/multiplayer/coop_session.dart';
import '../../data/services/problem_generator.dart';
import '../../data/services/sfx_service.dart';

/// A one-shot emoji reaction sent by the parent (Mario-Party style pop).
class CoachReaction {
  const CoachReaction(this.emoji, this.id);
  final String emoji;
  final int id;
}

/// Child side of 부모와 함께하는 학습. The child solves normally; every problem
/// and keystroke is mirrored to the parent (`problem_state`), and each submit
/// sends an `attempt_result`. Incoming coaching (`set_difficulty`, `coach_emoji`,
/// pause/resume) is applied here. Problems are generated locally by the child,
/// per the design (child device is the source of truth for content).
class CoopLearnController extends GetxController with WidgetsBindingObserver {
  final SfxService _sfx = Get.find();
  final CoopRecordService _records = Get.find();
  final Random _rng = Random();

  static const int maxAnswerLength = 6;

  // A session yields at most one saved record per device.
  bool _saved = false;
  final List<ProblemAttempt> _attempts = [];
  // True only while paused *because* we backgrounded — so we auto-resume only
  // our own pause, never one the parent initiated.
  bool _bgPaused = false;

  late final CoopSession session;

  final RxString answer = ''.obs;
  final RxInt correctCount = 0.obs;
  final RxInt wrongCount = 0.obs;
  final RxInt index = 0.obs;
  final RxBool paused = false.obs;
  final RxBool partnerLeft = false.obs;

  /// Latest emoji reaction to animate on screen (null = none pending).
  final Rxn<CoachReaction> reaction = Rxn<CoachReaction>();
  int _lastEmojiId = -1;

  late final Rx<Problem> current;

  // Active difficulty; null gameType == 🎲 랜덤 (random op each problem).
  GameType? _gameType;
  int _level = 1;

  StreamSubscription<CoopMessage>? _msgSub;
  Timer? _stateDebounce;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void onInit() {
    super.onInit();
    session = (Get.arguments as Map)['session'] as CoopSession;
    _gameType = session.gameType;
    _level = session.level.value;
    _msgSub = session.messages.listen(_onMessage);
    WidgetsBinding.instance.addObserver(this);
    _stopwatch.start();
    current = _generate().obs;
    _sendProblemState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (partnerLeft.value) return;
    if (state == AppLifecycleState.resumed) {
      if (_bgPaused) {
        _bgPaused = false;
        paused.value = false;
        session.send(const SessionResumeMessage());
      }
    } else if (!paused.value) {
      // Backgrounded/inactive while active → pause and tell the partner.
      _bgPaused = true;
      paused.value = true;
      session.send(const SessionPauseMessage());
    }
  }

  Problem _generate() {
    final type = _gameType ?? _randomOp();
    return ProblemGenerator.generateOne(type: type, level: _level);
  }

  GameType _randomOp() => const [
        GameType.addition,
        GameType.subtraction,
        GameType.multiplication,
        GameType.division,
      ][_rng.nextInt(4)];

  // ───── input ─────
  void appendDigit(String d) {
    if (paused.value || partnerLeft.value) return;
    if (answer.value.length >= maxAnswerLength) return;
    answer.value += d;
    _sfx.click();
    _scheduleStateSend();
  }

  void deleteDigit() {
    if (paused.value || partnerLeft.value) return;
    if (answer.value.isEmpty) return;
    answer.value = answer.value.substring(0, answer.value.length - 1);
    _scheduleStateSend();
  }

  void submit() {
    if (paused.value || partnerLeft.value) return;
    if (answer.value.isEmpty) return;
    final userAnswer = int.tryParse(answer.value);
    final correct = userAnswer == current.value.answer;
    if (correct) {
      correctCount.value += 1;
      _sfx.correct();
    } else {
      wrongCount.value += 1;
      _sfx.wrong();
    }
    final p = current.value;
    _attempts.add(
      ProblemAttempt(
        operandA: p.operandA,
        operandB: p.operandB,
        type: p.type,
        correctAnswer: p.answer,
        userAnswer: userAnswer,
        status: correct ? AttemptStatus.correct : AttemptStatus.wrong,
      ),
    );
    session.send(
      AttemptResultMessage(
        index: index.value,
        correct: correct,
        correctAnswer: current.value.answer,
        userAnswer: userAnswer,
      ),
    );
    index.value += 1;
    answer.value = '';
    current.value = _generate();
    _sendProblemState();
  }

  // ───── mirroring ─────
  void _scheduleStateSend() {
    _stateDebounce?.cancel();
    _stateDebounce =
        Timer(const Duration(milliseconds: 200), _sendProblemState);
  }

  void _sendProblemState() {
    final p = current.value;
    session.send(
      ProblemStateMessage(
        index: index.value,
        operands: p.operands,
        op: p.type.symbol,
        typedAnswer: answer.value,
      ),
    );
  }

  // ───── incoming coaching ─────
  void _onMessage(CoopMessage m) {
    switch (m) {
      case SetDifficultyMessage(:final gameType, :final level):
        _gameType = gameType;
        if (level != null) _level = level;
        // Applies from the next generated problem (current one is untouched).
      case CoachEmojiMessage(:final emoji, :final id):
        if (id != _lastEmojiId) {
          _lastEmojiId = id;
          reaction.value = CoachReaction(emoji, id);
        }
      case SessionPauseMessage():
        paused.value = true;
      case SessionResumeMessage():
        paused.value = false;
      case ByeMessage():
        partnerLeft.value = true;
        _saveRecord();
      default:
        break;
    }
  }

  int get elapsedMs => _stopwatch.elapsedMilliseconds;

  void _saveRecord() {
    if (_saved) return;
    if (correctCount.value + wrongCount.value == 0) return;
    _saved = true;
    final partner = session.partner.value;
    _records.add(
      CoopSessionRecord(
        finishedAt: DateTime.now(),
        partnerName: partner?.name ?? '부모님',
        partnerAvatar: partner?.avatar ?? '👩‍👦',
        gameType: session.gameType,
        level: session.level.value,
        correct: correctCount.value,
        wrong: wrongCount.value,
        elapsedSeconds: elapsedMs ~/ 1000,
        attempts: List.of(_attempts),
      ),
    );
  }

  /// Child ends the session — saves its record, reports a summary, says bye.
  void endSession() {
    _saveRecord();
    session.send(
      SessionSummaryMessage(
        correct: correctCount.value,
        wrong: wrongCount.value,
        elapsedMs: elapsedMs,
      ),
    );
    session.send(const ByeMessage(reason: 'child_ended'));
    Get.back();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateDebounce?.cancel();
    _msgSub?.cancel();
    _stopwatch.stop();
    super.onClose();
  }
}
