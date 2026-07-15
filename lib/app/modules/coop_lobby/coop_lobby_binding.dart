import 'package:get/get.dart';

import '../../data/services/multiplayer/multiplayer_service.dart';
import '../../data/services/multiplayer/nearby_transport.dart';
import 'coop_lobby_controller.dart';

/// Wires the shared [MultiplayerService] (real Nearby transport) and the lobby
/// controller. The service is put here rather than in `main()` so the P2P stack
/// only spins up when the user actually enters the coop flow; it stays alive as
/// long as the lobby remains in the navigation stack (the learn/coach screens
/// are pushed on top of it).
class CoopLobbyBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MultiplayerService>()) {
      Get.put<MultiplayerService>(
        MultiplayerService(transport: NearbyTransport())..init(),
      );
    }
    Get.lazyPut<CoopLobbyController>(() => CoopLobbyController());
  }
}
