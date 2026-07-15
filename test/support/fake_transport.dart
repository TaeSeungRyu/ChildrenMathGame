import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:children_math_game/app/data/services/multiplayer/multiplayer_transport.dart';

/// In-memory [MultiplayerTransport] for tests: drive [TransportEvent]s with
/// [emit] and inspect what the service sent via [calls] / [sent].
class FakeTransport implements MultiplayerTransport {
  final _controller = StreamController<TransportEvent>.broadcast();
  final List<String> calls = [];
  final List<Uint8List> sent = [];
  bool advertiseResult = true;
  bool discoveryResult = true;
  bool requestResult = true;

  void emit(TransportEvent e) => _controller.add(e);

  /// Convenience: the raw UTF-8 payloads the service sent, decoded to strings.
  List<String> get sentStrings => sent.map(utf8.decode).toList();

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
