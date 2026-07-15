import 'dart:typed_data';

/// Thin abstraction over the underlying P2P plugin (Nearby Connections).
///
/// The connection state machine lives in `MultiplayerService`, which talks only
/// to this interface — never to the plugin directly. That keeps the state
/// machine unit-testable with a fake transport (no radios, no platform
/// channels) and lets the coop + versus modes share one implementation.
///
/// All lifecycle notifications arrive as [TransportEvent]s on [events].
abstract interface class MultiplayerTransport {
  Stream<TransportEvent> get events;

  Future<bool> startAdvertising(String name, {required String serviceId});
  Future<bool> startDiscovery(String name, {required String serviceId});
  Future<void> stopAdvertising();
  Future<void> stopDiscovery();

  /// Guest side: ask a discovered [endpointId] to connect.
  Future<bool> requestConnection(String name, String endpointId);

  /// Accept an initiated connection (both sides call this after `initiated`).
  Future<bool> acceptConnection(String endpointId);
  Future<bool> rejectConnection(String endpointId);

  Future<void> sendBytes(String endpointId, Uint8List bytes);
  Future<void> disconnect(String endpointId);

  /// Stop advertising/discovery and drop all endpoints.
  Future<void> stopAll();

  Future<void> dispose();
}

/// Events surfaced by a [MultiplayerTransport].
sealed class TransportEvent {
  const TransportEvent();
}

class EndpointFoundEvent extends TransportEvent {
  const EndpointFoundEvent(this.endpointId, this.name, this.serviceId);
  final String endpointId;
  final String name;
  final String serviceId;
}

class EndpointLostEvent extends TransportEvent {
  const EndpointLostEvent(this.endpointId);
  final String endpointId;
}

class ConnectionInitiatedEvent extends TransportEvent {
  const ConnectionInitiatedEvent(
    this.endpointId,
    this.endpointName,
    this.isIncoming,
  );
  final String endpointId;
  final String endpointName;

  /// True when the remote side initiated (host receiving a guest request).
  final bool isIncoming;
}

class ConnectionResultEvent extends TransportEvent {
  const ConnectionResultEvent(this.endpointId, this.success);
  final String endpointId;
  final bool success;
}

class DisconnectedEvent extends TransportEvent {
  const DisconnectedEvent(this.endpointId);
  final String endpointId;
}

class PayloadReceivedEvent extends TransportEvent {
  const PayloadReceivedEvent(this.endpointId, this.bytes);
  final String endpointId;
  final Uint8List bytes;
}
