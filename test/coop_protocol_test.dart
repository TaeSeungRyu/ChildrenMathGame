import 'dart:convert';
import 'dart:typed_data';

import 'package:children_math_game/app/data/models/coop_message.dart';
import 'package:children_math_game/app/data/models/coop_role.dart';
import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/services/multiplayer/coop_session.dart';
import 'package:children_math_game/app/data/services/multiplayer/multiplayer_service.dart';
import 'package:children_math_game/app/data/services/multiplayer/multiplayer_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_transport.dart';

Future<void> _flush() => Future<void>.delayed(Duration.zero);

PayloadReceivedEvent _incoming(CoopMessage m) =>
    PayloadReceivedEvent('peer', Uint8List.fromList(utf8.encode(m.encode())));

List<CoopMessage> _sent(FakeTransport fake) =>
    fake.sentStrings.map(CoopMessage.decode).toList();

void main() {
  group('CoopMessage serialization', () {
    T roundTrip<T extends CoopMessage>(CoopMessage m) {
      final decoded = CoopMessage.decode(m.encode());
      expect(decoded, isA<T>());
      return decoded as T;
    }

    test('hello round-trips role/name/avatar', () {
      final m = roundTrip<HelloMessage>(const HelloMessage(
        name: '민준',
        avatar: '🦊',
        role: CoopRole.child,
      ));
      expect(m.name, '민준');
      expect(m.avatar, '🦊');
      expect(m.role, CoopRole.child);
    });

    test('session_config carries gameType + level, null gameType = random', () {
      final m = roundTrip<SessionConfigMessage>(
        const SessionConfigMessage(gameType: GameType.multiplication, level: 4),
      );
      expect(m.gameType, GameType.multiplication);
      expect(m.level, 4);

      final r = roundTrip<SessionConfigMessage>(
        const SessionConfigMessage(gameType: null, level: 2),
      );
      expect(r.gameType, isNull);
      expect(r.level, 2);
    });

    test('problem_state + attempt_result round-trip', () {
      final ps = roundTrip<ProblemStateMessage>(const ProblemStateMessage(
        index: 2,
        operands: [12, 7],
        op: '+',
        typedAnswer: '1',
      ));
      expect(ps.operands, [12, 7]);
      expect(ps.typedAnswer, '1');

      final ar = roundTrip<AttemptResultMessage>(const AttemptResultMessage(
        index: 2,
        correct: false,
        correctAnswer: 19,
        userAnswer: 18,
      ));
      expect(ar.correct, isFalse);
      expect(ar.correctAnswer, 19);
      expect(ar.userAnswer, 18);
    });

    test('coach_emoji round-trips emoji + id', () {
      final m = roundTrip<CoachEmojiMessage>(
        const CoachEmojiMessage(emoji: '🎉', id: 42),
      );
      expect(m.emoji, '🎉');
      expect(m.id, 42);
    });

    test('unknown type decodes to UnknownMessage (forward compatible)', () {
      final decoded = CoopMessage.decode('{"type":"from_future"}');
      expect(decoded, isA<UnknownMessage>());
      expect(decoded.type, 'from_future');
    });
  });

  group('CoopSession handshake', () {
    late FakeTransport fake;
    late MultiplayerService mp;

    setUp(() async {
      fake = FakeTransport();
      mp = MultiplayerService(transport: fake);
      await mp.init();
    });

    tearDown(() => mp.onClose());

    Future<void> connectAsHost() async {
      await mp.startHosting('엄마');
      fake.emit(const ConnectionResultEvent('e1', true));
      await _flush();
    }

    Future<void> connectAsGuest() async {
      await mp.startJoining('아이');
      fake.emit(const ConnectionResultEvent('h1', true));
      await _flush();
    }

    test('host: hello → partner hello → config sent → ready → start', () async {
      await connectAsHost();
      final s = CoopSession(
        mp: mp,
        selfName: '엄마',
        selfAvatar: '🦸',
        role: CoopRole.parent,
        gameType: GameType.addition,
        level: 3,
      );
      s.start();
      await _flush();

      expect(s.phase.value, CoopPhase.handshaking);
      expect(_sent(fake).whereType<HelloMessage>(), isNotEmpty);

      fake.emit(_incoming(const HelloMessage(
        name: '아이',
        avatar: '🧒',
        role: CoopRole.child,
      )));
      await _flush();

      expect(s.partner.value?.name, '아이');
      expect(s.phase.value, CoopPhase.ready);
      final cfg = _sent(fake).whereType<SessionConfigMessage>().last;
      expect(cfg.gameType, GameType.addition);
      expect(cfg.level, 3);

      s.startSession();
      await _flush();
      expect(_sent(fake).whereType<SessionStartMessage>(), isNotEmpty);
      expect(s.phase.value, CoopPhase.running);
      expect(mp.state.value, MultiplayerState.inSession);

      s.dispose();
    });

    test('guest: stays handshaking until config, then ready, then running',
        () async {
      await connectAsGuest();
      final s = CoopSession(
        mp: mp,
        selfName: '아이',
        selfAvatar: '🧒',
        role: CoopRole.child,
      );
      s.start();
      await _flush();

      // Partner hello alone is not enough for the guest.
      fake.emit(_incoming(const HelloMessage(
        name: '엄마',
        avatar: '🦸',
        role: CoopRole.parent,
      )));
      await _flush();
      expect(s.phase.value, CoopPhase.handshaking);

      // Config tells the guest what to study → ready.
      fake.emit(_incoming(
        const SessionConfigMessage(gameType: GameType.multiplication, level: 2),
      ));
      await _flush();
      expect(s.gameType, GameType.multiplication);
      expect(s.level.value, 2);
      expect(s.phase.value, CoopPhase.ready);

      // Guest does not drive start.
      s.startSession();
      await _flush();
      expect(_sent(fake).whereType<SessionStartMessage>(), isEmpty);

      // Host's start arrives → running.
      fake.emit(_incoming(const SessionStartMessage()));
      await _flush();
      expect(s.phase.value, CoopPhase.running);

      s.dispose();
    });

    test('bye ends the session', () async {
      await connectAsHost();
      final s = CoopSession(
        mp: mp,
        selfName: '엄마',
        selfAvatar: '🦸',
        role: CoopRole.parent,
      );
      s.start();
      await _flush();
      fake.emit(_incoming(const ByeMessage(reason: 'left')));
      await _flush();
      expect(s.phase.value, CoopPhase.ended);
      s.dispose();
    });

    test('ungraceful transport disconnect ends the session', () async {
      await connectAsHost();
      final s = CoopSession(
        mp: mp,
        selfName: '엄마',
        selfAvatar: '🦸',
        role: CoopRole.parent,
      );
      s.start();
      await _flush();

      final byeReceived =
          s.messages.firstWhere((m) => m is ByeMessage);
      fake.emit(const DisconnectedEvent('e1'));
      await _flush();

      expect(s.phase.value, CoopPhase.ended);
      expect(await byeReceived, isA<ByeMessage>());
      s.dispose();
    });
  });
}
