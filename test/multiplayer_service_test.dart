import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:children_math_game/app/data/services/multiplayer/multiplayer_service.dart';
import 'package:children_math_game/app/data/services/multiplayer/multiplayer_transport.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory transport that lets tests drive [TransportEvent]s and inspect the
/// calls the service made — no radios, no platform channels.
class FakeTransport implements MultiplayerTransport {
  final _controller = StreamController<TransportEvent>.broadcast();
  final List<String> calls = [];
  final List<Uint8List> sent = [];
  bool advertiseResult = true;
  bool discoveryResult = true;
  bool requestResult = true;

  void emit(TransportEvent e) => _controller.add(e);

  @override
  Stream<TransportEvent> get events => _controller.stream;

  @override
  Future<bool> startAdvertising(String name, {required String serviceId}) async {
    calls.add('advertise:$name');
    return advertiseResult;
  }

  @override
  Future<bool> startDiscovery(String name, {required String serviceId}) async {
    calls.add('discover:$name');
    return discoveryResult;
  }

  @override
  Future<void> stopAdvertising() async => calls.add('stopAdvertising');

  @override
  Future<void> stopDiscovery() async => calls.add('stopDiscovery');

  @override
  Future<bool> requestConnection(String name, String endpointId) async {
    calls.add('request:$endpointId');
    return requestResult;
  }

  @override
  Future<bool> acceptConnection(String endpointId) async {
    calls.add('accept:$endpointId');
    return true;
  }

  @override
  Future<bool> rejectConnection(String endpointId) async {
    calls.add('reject:$endpointId');
    return true;
  }

  @override
  Future<void> sendBytes(String endpointId, Uint8List bytes) async =>
      sent.add(bytes);

  @override
  Future<void> disconnect(String endpointId) async =>
      calls.add('disconnect:$endpointId');

  @override
  Future<void> stopAll() async => calls.add('stopAll');

  @override
  Future<void> dispose() async => _controller.close();
}

// Lets stream listeners run (broadcast delivery + timers).
Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeTransport fake;
  late MultiplayerService svc;

  setUp(() async {
    fake = FakeTransport();
    svc = MultiplayerService(transport: fake);
    await svc.init();
  });

  tearDown(() {
    svc.onClose();
  });

  test('starts idle', () {
    expect(svc.state.value, MultiplayerState.idle);
    expect(svc.isConnected, isFalse);
  });

  test('startHosting advertises and enters advertising', () async {
    await svc.startHosting('엄마');
    expect(svc.state.value, MultiplayerState.advertising);
    expect(svc.isHost, isTrue);
    expect(fake.calls, contains('advertise:엄마'));
  });

  test('advertise failure → error', () async {
    fake.advertiseResult = false;
    await svc.startHosting('엄마');
    expect(svc.state.value, MultiplayerState.error);
  });

  test('host handshake: initiated auto-accepts, result connects', () async {
    await svc.startHosting('엄마');

    fake.emit(const ConnectionInitiatedEvent('e1', '아이', true));
    await _flush();
    expect(svc.state.value, MultiplayerState.connecting);
    expect(fake.calls, contains('accept:e1'));

    fake.emit(const ConnectionResultEvent('e1', true));
    await _flush();
    expect(svc.state.value, MultiplayerState.connected);
    expect(svc.connectedEndpointId, 'e1');
    // Radios stop once paired.
    expect(fake.calls, contains('stopAdvertising'));
  });

  test('guest flow: discover → found → connect → connected', () async {
    await svc.startJoining('아이');
    expect(svc.state.value, MultiplayerState.discovering);

    fake.emit(const EndpointFoundEvent('host1', '엄마', 'svc'));
    await _flush();
    expect(svc.peers.length, 1);
    expect(svc.peers.first.name, '엄마');

    await svc.connectTo('host1');
    expect(svc.state.value, MultiplayerState.connecting);
    expect(fake.calls, contains('request:host1'));

    fake.emit(const ConnectionResultEvent('host1', true));
    await _flush();
    expect(svc.state.value, MultiplayerState.connected);
    expect(svc.connectedEndpointId, 'host1');
  });

  test('endpoint lost removes the peer', () async {
    await svc.startJoining('아이');
    fake.emit(const EndpointFoundEvent('h1', '엄마', 'svc'));
    await _flush();
    expect(svc.peers.length, 1);
    fake.emit(const EndpointLostEvent('h1'));
    await _flush();
    expect(svc.peers, isEmpty);
  });

  test('connection failure before connect → error', () async {
    await svc.startJoining('아이');
    await svc.connectTo('h1');
    fake.emit(const ConnectionResultEvent('h1', false));
    await _flush();
    expect(svc.state.value, MultiplayerState.error);
  });

  test('sendMessage encodes UTF-8 to the connected endpoint', () async {
    await svc.startHosting('엄마');
    fake.emit(const ConnectionResultEvent('e1', true));
    await _flush();

    await svc.sendMessage('{"type":"hello"}');
    expect(fake.sent.length, 1);
    expect(utf8.decode(fake.sent.first), '{"type":"hello"}');
  });

  test('sendMessage is a no-op when not connected', () async {
    await svc.sendMessage('{"type":"hello"}');
    expect(fake.sent, isEmpty);
  });

  test('incoming payload is decoded onto the incoming stream', () async {
    await svc.startHosting('엄마');
    fake.emit(const ConnectionResultEvent('e1', true));
    await _flush();

    final received = svc.incoming.first;
    fake.emit(
      PayloadReceivedEvent('e1', Uint8List.fromList(utf8.encode('안녕'))),
    );
    expect(await received, '안녕');
  });

  test('markInSession only advances from connected', () async {
    svc.markInSession();
    expect(svc.state.value, MultiplayerState.idle); // no-op when not connected

    await svc.startHosting('엄마');
    fake.emit(const ConnectionResultEvent('e1', true));
    await _flush();
    svc.markInSession();
    expect(svc.state.value, MultiplayerState.inSession);
  });

  test('disconnect of the active endpoint → disconnected', () async {
    await svc.startHosting('엄마');
    fake.emit(const ConnectionResultEvent('e1', true));
    await _flush();

    fake.emit(const DisconnectedEvent('e1'));
    await _flush();
    expect(svc.state.value, MultiplayerState.disconnected);
    expect(svc.isConnected, isFalse);
  });

  test('explicit disconnect tears down and returns to idle', () async {
    await svc.startHosting('엄마');
    fake.emit(const ConnectionResultEvent('e1', true));
    await _flush();

    await svc.disconnect();
    expect(svc.state.value, MultiplayerState.idle);
    expect(fake.calls, contains('disconnect:e1'));
    expect(fake.calls, contains('stopAll'));
  });
}
