import 'dart:async';

import 'package:get/get.dart';

import '../../models/coop_message.dart';
import '../../models/coop_role.dart';
import '../../models/game_type.dart';
import 'multiplayer_service.dart';

enum CoopPhase { handshaking, ready, running, paused, ended }

class PartnerInfo {
  const PartnerInfo(this.name, this.avatar, this.role);
  final String name;
  final String avatar;
  final CoopRole role;
}

/// Protocol layer for a 부모와 함께하는 학습 session, sitting on top of the
/// generic [MultiplayerService] (which only moves raw strings). Handles the
/// hello handshake, then the host pushing session config + start. All decoded
/// messages are re-published on [messages] so the learn/coach screens can react
/// to the ones they care about (problem_state, attempt_result, coach_emoji, …).
///
/// Host vs guest is inherited from [MultiplayerService.isHost] (who opened the
/// room). Role (parent/child) is orthogonal and chosen in the lobby.
class CoopSession {
  CoopSession({
    required this.mp,
    required this.selfName,
    required this.selfAvatar,
    required this.role,
    this.gameType,
    int level = 1,
  }) : level = level.obs;

  final MultiplayerService mp;
  final String selfName;
  final String selfAvatar;
  final CoopRole role;

  /// null == 🎲 랜덤. Host seeds it from the lobby; guest receives it via config.
  GameType? gameType;
  final RxInt level;

  final Rx<CoopPhase> phase = CoopPhase.handshaking.obs;
  final Rxn<PartnerInfo> partner = Rxn<PartnerInfo>();

  final StreamController<CoopMessage> _messages =
      StreamController<CoopMessage>.broadcast();

  /// Every decoded incoming message (after internal phase handling).
  Stream<CoopMessage> get messages => _messages.stream;

  StreamSubscription<String>? _sub;
  Worker? _stateWorker;
  bool _sentHello = false;
  bool _gotHello = false;
  bool _configDone = false;

  bool get isHost => mp.isHost;

  void start() {
    _sub = mp.incoming.listen(_onRaw);
    // An ungraceful drop (radio out of range, app killed) surfaces as a
    // transport disconnect rather than a `bye`. Treat it like a partner-left so
    // the screens react uniformly.
    _stateWorker = ever<MultiplayerState>(mp.state, (s) {
      if (s == MultiplayerState.disconnected && phase.value != CoopPhase.ended) {
        phase.value = CoopPhase.ended;
        _messages.add(const ByeMessage(reason: 'connection_lost'));
      }
    });
    _sendHello();
  }

  void _sendHello() {
    send(HelloMessage(name: selfName, avatar: selfAvatar, role: role));
    _sentHello = true;
    _advance();
  }

  void _onRaw(String raw) {
    final msg = CoopMessage.decode(raw);
    switch (msg) {
      case HelloMessage(:final name, :final avatar, :final role):
        partner.value = PartnerInfo(name, avatar, role);
        _gotHello = true;
        _advance();
      case SessionConfigMessage(:final gameType, :final level):
        this.gameType = gameType;
        this.level.value = level;
        _configDone = true;
        _advance();
      case SessionStartMessage():
        phase.value = CoopPhase.running;
      case SessionPauseMessage():
        if (phase.value == CoopPhase.running) phase.value = CoopPhase.paused;
      case SessionResumeMessage():
        if (phase.value == CoopPhase.paused) phase.value = CoopPhase.running;
      case ByeMessage():
        phase.value = CoopPhase.ended;
      default:
        break;
    }
    _messages.add(msg);
  }

  void _advance() {
    if (!(_sentHello && _gotHello)) return;
    if (isHost) {
      if (!_configDone) {
        send(SessionConfigMessage(gameType: gameType, level: level.value));
        _configDone = true;
      }
      if (phase.value == CoopPhase.handshaking) phase.value = CoopPhase.ready;
    } else if (_configDone && phase.value == CoopPhase.handshaking) {
      // Guest is ready only once it knows what to study.
      phase.value = CoopPhase.ready;
    }
  }

  /// Host: begin the session on both devices.
  void startSession() {
    if (!isHost) return;
    send(const SessionStartMessage());
    phase.value = CoopPhase.running;
    mp.markInSession();
  }

  void send(CoopMessage m) => unawaited(mp.sendMessage(m.encode()));

  void dispose() {
    _sub?.cancel();
    _stateWorker?.dispose();
    unawaited(_messages.close());
  }
}
