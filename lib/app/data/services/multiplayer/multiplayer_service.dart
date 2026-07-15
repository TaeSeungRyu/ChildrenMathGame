import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';

import 'multiplayer_transport.dart';

/// Connection lifecycle for the 1:1 P2P modes (부모와 함께하는 학습 / 대전).
///
/// Wraps a [MultiplayerTransport] and exposes a small state machine + a stream
/// of decoded (UTF-8) incoming messages. Message *content* (the coop/versus
/// protocol) is layered on top in later stages — this service only moves
/// strings and tracks connection state, so it stays shared between modes and
/// unit-testable with a fake transport.
enum MultiplayerState {
  idle,
  permissionDenied,
  advertising, // host waiting
  discovering, // guest searching
  connecting,
  connected,
  inSession,
  disconnected,
  error,
}

class DiscoveredPeer {
  const DiscoveredPeer(this.endpointId, this.name);
  final String endpointId;
  final String name;
}

class MultiplayerService extends GetxService {
  MultiplayerService({required this.transport, String? serviceId})
      : serviceId = serviceId ?? _defaultServiceId;

  // Must match on both devices for them to discover each other.
  static const _defaultServiceId = 'com.bubaum.yeonsanhero.p2p';

  final MultiplayerTransport transport;
  final String serviceId;

  final Rx<MultiplayerState> state = MultiplayerState.idle.obs;
  final RxList<DiscoveredPeer> peers = <DiscoveredPeer>[].obs;

  final StreamController<String> _incoming = StreamController<String>.broadcast();

  /// Decoded incoming protocol messages (JSON strings).
  Stream<String> get incoming => _incoming.stream;

  StreamSubscription<TransportEvent>? _sub;
  String? connectedEndpointId;
  String _displayName = '';
  bool _isHost = false;
  bool get isHost => _isHost;
  bool get isConnected => connectedEndpointId != null;

  Future<MultiplayerService> init() async {
    _sub = transport.events.listen(_onEvent);
    return this;
  }

  /// Host: start advertising and wait for a peer.
  Future<void> startHosting(String name) async {
    _displayName = name;
    _isHost = true;
    peers.clear();
    state.value = MultiplayerState.advertising;
    final ok = await transport.startAdvertising(name, serviceId: serviceId);
    if (!ok) state.value = MultiplayerState.error;
  }

  /// Guest: start discovering nearby hosts.
  Future<void> startJoining(String name) async {
    _displayName = name;
    _isHost = false;
    peers.clear();
    state.value = MultiplayerState.discovering;
    final ok = await transport.startDiscovery(name, serviceId: serviceId);
    if (!ok) state.value = MultiplayerState.error;
  }

  /// Guest: request a connection to a discovered peer.
  Future<void> connectTo(String endpointId) async {
    state.value = MultiplayerState.connecting;
    final ok = await transport.requestConnection(_displayName, endpointId);
    if (!ok) state.value = MultiplayerState.error;
  }

  /// Send one protocol message (already JSON-encoded) to the connected peer.
  Future<void> sendMessage(String json) async {
    final id = connectedEndpointId;
    if (id == null) return;
    await transport.sendBytes(id, Uint8List.fromList(utf8.encode(json)));
  }

  /// Called by the game layer once both sides are ready and playing.
  void markInSession() {
    if (state.value == MultiplayerState.connected) {
      state.value = MultiplayerState.inSession;
    }
  }

  Future<void> disconnect() async {
    final id = connectedEndpointId;
    if (id != null) await transport.disconnect(id);
    await transport.stopAll();
    connectedEndpointId = null;
    peers.clear();
    state.value = MultiplayerState.idle;
  }

  void _onEvent(TransportEvent event) {
    switch (event) {
      case EndpointFoundEvent(:final endpointId, :final name):
        if (!peers.any((p) => p.endpointId == endpointId)) {
          peers.add(DiscoveredPeer(endpointId, name));
        }
      case EndpointLostEvent(:final endpointId):
        peers.removeWhere((p) => p.endpointId == endpointId);
      case ConnectionInitiatedEvent(:final endpointId):
        // Auto-accept — kid-friendly, no manual approval dance. Both sides
        // accept; the pairing completes when both have accepted.
        state.value = MultiplayerState.connecting;
        unawaited(transport.acceptConnection(endpointId));
      case ConnectionResultEvent(:final endpointId, :final success):
        if (success) {
          connectedEndpointId = endpointId;
          state.value = MultiplayerState.connected;
          // Once paired, stop broadcasting/scanning to save radio + battery.
          unawaited(transport.stopAdvertising());
          unawaited(transport.stopDiscovery());
        } else if (connectedEndpointId == null) {
          state.value = MultiplayerState.error;
        }
      case DisconnectedEvent(:final endpointId):
        if (endpointId == connectedEndpointId) {
          connectedEndpointId = null;
          state.value = MultiplayerState.disconnected;
        }
      case PayloadReceivedEvent(:final bytes):
        _incoming.add(utf8.decode(bytes));
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    _incoming.close();
    unawaited(transport.dispose());
    super.onClose();
  }
}
