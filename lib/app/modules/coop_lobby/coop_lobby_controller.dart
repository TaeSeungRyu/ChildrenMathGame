import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/models/coop_role.dart';
import '../../data/models/game_type.dart';
import '../../data/services/coop_permissions.dart';
import '../../data/services/multiplayer/coop_session.dart';
import '../../data/services/multiplayer/multiplayer_service.dart';
import '../../data/services/profile_service.dart';
import '../../routes/app_routes.dart';

/// Lobby for 부모와 함께하는 학습: pick the learning content, open a room or
/// join one, then choose this device's role once connected.
///
/// Connection lifecycle itself lives in [MultiplayerService]; this controller
/// drives the learning-selection + permission + role-pick UX on top of it.
class CoopLobbyController extends GetxController {
  final MultiplayerService mp = Get.find();
  final ProfileService _profile = Get.find();

  // Concrete ops the host can pick; null == 🎲 랜덤 (mixed per problem).
  static const List<GameType?> opChoices = [
    GameType.addition,
    GameType.subtraction,
    GameType.multiplication,
    GameType.division,
    null,
  ];
  static const List<int> levelChoices = [1, 2, 3, 4, 5];

  final Rxn<GameType> selectedOp = Rxn<GameType>(GameType.addition);
  final RxInt selectedLevel = 1.obs;

  /// True once a required permission was permanently denied — the UI then
  /// offers a jump to system settings.
  final RxBool permissionBlocked = false.obs;

  /// The role this device picked after connecting (null until chosen).
  final Rxn<CoopRole> role = Rxn<CoopRole>();

  /// The protocol session, created once a role is chosen.
  final Rxn<CoopSession> session = Rxn<CoopSession>();

  Worker? _phaseWorker;
  bool _navigatedToSession = false;

  MultiplayerState get state => mp.state.value;
  String get displayName => _profile.name.value;

  void setOp(GameType? op) => selectedOp.value = op;
  void setLevel(int level) => selectedLevel.value = level;

  Future<bool> _ensurePermissions() async {
    if (await CoopPermissions.allGranted()) return true;
    final granted = await CoopPermissions.requestAll();
    if (!granted) {
      permissionBlocked.value = await CoopPermissions.anyPermanentlyDenied();
    }
    return granted;
  }

  Future<void> hostRoom() async {
    if (!await _ensurePermissions()) return;
    await mp.startHosting(displayName);
  }

  Future<void> joinRoom() async {
    if (!await _ensurePermissions()) return;
    await mp.startJoining(displayName);
  }

  // No manual connect timeout: Nearby's Wi-Fi Direct upgrade can legitimately
  // take longer than a short watchdog, and Nearby reports a genuine failure via
  // its own connection-result callback (→ error state). The user can also back
  // out with the cancel button.
  Future<void> connectToPeer(String endpointId) => mp.connectTo(endpointId);

  Future<void> cancel() async {
    _teardown();
    await mp.disconnect();
  }

  void _teardown() {
    _phaseWorker?.dispose();
    _phaseWorker = null;
    _navigatedToSession = false;
    session.value?.dispose();
    session.value = null;
    role.value = null;
  }

  /// Session ended (this device left, partner left, or the link dropped):
  /// return everyone to the room-setup screen. Pops the learn/coach screen if
  /// it's on top, then resets the lobby to idle so `_Setup` shows.
  void _onSessionEnded() {
    final route = Get.currentRoute;
    if (route == AppRoutes.coopLearn || route == AppRoutes.coopCoach) {
      Get.back();
    }
    cancel();
  }

  void openSettings() => openAppSettings();

  /// Pick this device's role after connecting, then start the protocol session
  /// (hello handshake → host pushes config/start). The host seeds the learning
  /// selection; the guest receives it via config.
  void chooseRole(CoopRole picked) {
    role.value = picked;
    final s = CoopSession(
      mp: mp,
      selfName: _profile.name.value,
      selfAvatar: _profile.avatar.value,
      role: picked,
      gameType: mp.isHost ? selectedOp.value : null,
      level: selectedLevel.value,
    );
    session.value = s;
    // When the session starts, each device jumps to its role's screen:
    // the child to the learn screen, the parent to the coach dashboard.
    _phaseWorker = ever<CoopPhase>(s.phase, (phase) {
      if (phase == CoopPhase.running && !_navigatedToSession) {
        _navigatedToSession = true;
        final route = role.value == CoopRole.child
            ? AppRoutes.coopLearn
            : AppRoutes.coopCoach;
        Get.toNamed(route, arguments: {'session': s});
      } else if (phase == CoopPhase.ended) {
        _onSessionEnded();
      }
    });
    s.start();
  }

  /// Host: begin the session for both devices.
  void startSession() => session.value?.startSession();

  @override
  void onClose() {
    _phaseWorker?.dispose();
    session.value?.dispose();
    super.onClose();
  }
}
