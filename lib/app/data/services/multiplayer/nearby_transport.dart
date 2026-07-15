import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nearby_connections/nearby_connections.dart';

import 'multiplayer_transport.dart';

/// Real [MultiplayerTransport] backed by Google Nearby Connections.
///
/// Uses `P2P_POINT_TO_POINT` (highest bandwidth 1:1). All plugin callbacks are
/// funnelled into a single broadcast [events] stream so the service can run a
/// plain state machine over them.
class NearbyTransport implements MultiplayerTransport {
  final Nearby _nearby = Nearby();
  final StreamController<TransportEvent> _controller =
      StreamController<TransportEvent>.broadcast();

  static const Strategy _strategy = Strategy.P2P_POINT_TO_POINT;

  @override
  Stream<TransportEvent> get events => _controller.stream;

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    _controller.add(
      ConnectionInitiatedEvent(
        id,
        info.endpointName,
        info.isIncomingConnection,
      ),
    );
  }

  void _onConnectionResult(String id, Status status) {
    _controller.add(ConnectionResultEvent(id, status == Status.CONNECTED));
  }

  void _onDisconnected(String id) => _controller.add(DisconnectedEvent(id));

  @override
  Future<bool> startAdvertising(String name, {required String serviceId}) {
    return _nearby.startAdvertising(
      name,
      _strategy,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
      serviceId: serviceId,
    );
  }

  @override
  Future<bool> startDiscovery(String name, {required String serviceId}) {
    return _nearby.startDiscovery(
      name,
      _strategy,
      onEndpointFound: (id, endpointName, sid) =>
          _controller.add(EndpointFoundEvent(id, endpointName, sid)),
      onEndpointLost: (id) {
        if (id != null) _controller.add(EndpointLostEvent(id));
      },
      serviceId: serviceId,
    );
  }

  @override
  Future<bool> requestConnection(String name, String endpointId) async {
    try {
      return await _nearby.requestConnection(
        name,
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } on PlatformException catch (e) {
      // 8003 = STATUS_ALREADY_CONNECTED_TO_ENDPOINT: a connection to this
      // endpoint already exists, so surface it as a successful result instead
      // of throwing and leaving the state machine stuck on "connecting".
      final msg = e.message ?? '';
      if (msg.contains('ALREADY_CONNECTED') || msg.contains('8003')) {
        _controller.add(ConnectionResultEvent(endpointId, true));
        return true;
      }
      _controller.add(ConnectionResultEvent(endpointId, false));
      return false;
    }
  }

  @override
  Future<bool> acceptConnection(String endpointId) {
    return _nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved: (id, payload) {
        final bytes = payload.bytes;
        if (payload.type == PayloadType.BYTES && bytes != null) {
          _controller.add(PayloadReceivedEvent(id, bytes));
        }
      },
    );
  }

  @override
  Future<bool> rejectConnection(String endpointId) =>
      _nearby.rejectConnection(endpointId);

  @override
  Future<void> sendBytes(String endpointId, Uint8List bytes) =>
      _nearby.sendBytesPayload(endpointId, bytes);

  @override
  Future<void> disconnect(String endpointId) =>
      _nearby.disconnectFromEndpoint(endpointId);

  @override
  Future<void> stopAdvertising() => _nearby.stopAdvertising();

  @override
  Future<void> stopDiscovery() => _nearby.stopDiscovery();

  @override
  Future<void> stopAll() => _nearby.stopAllEndpoints();

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
