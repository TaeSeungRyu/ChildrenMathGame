import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runtime-permission flow for the "부모와 함께하는 학습" (Nearby Connections)
/// mode. The exact set of runtime permissions Nearby needs differs by Android
/// API level, and we deliberately keep `minSdk` low (see
/// DOC/PARENT_COOP_LEARNING.md §3), so we branch explicitly here instead of
/// requesting a broad union that would prompt for location on Android 12+.
///
/// - Android 13+ (API 33+): BLUETOOTH_SCAN/ADVERTISE/CONNECT + NEARBY_WIFI_DEVICES.
/// - Android 12  (API 31-32): BLUETOOTH_SCAN/ADVERTISE/CONNECT.
/// - Android 11- (API ≤30): ACCESS_FINE_LOCATION (Nearby scanning needs it).
///
/// This is a thin platform wrapper (device_info + permission_handler); it has no
/// unit tests because it only forwards to platform channels.
class CoopPermissions {
  const CoopPermissions._();

  static Future<int> _androidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  /// The permissions Nearby Connections needs on *this* device's API level.
  static Future<List<Permission>> requiredPermissions() async {
    final sdk = await _androidSdkInt();
    if (sdk >= 33) {
      return const [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.nearbyWifiDevices,
      ];
    }
    if (sdk >= 31) {
      return const [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ];
    }
    // Android 11 and below — scanning for nearby peers requires fine location.
    return const [Permission.locationWhenInUse];
  }

  /// True when every required permission is already granted.
  static Future<bool> allGranted() async {
    for (final p in await requiredPermissions()) {
      if (!await p.status.isGranted) return false;
    }
    return true;
  }

  /// Requests all required permissions in one prompt batch. Returns true only
  /// if the user granted every one.
  static Future<bool> requestAll() async {
    final results = await (await requiredPermissions()).request();
    return results.values.every((s) => s.isGranted);
  }

  /// Whether any required permission is permanently denied — the caller should
  /// route the user to system settings (`openAppSettings()`).
  static Future<bool> anyPermanentlyDenied() async {
    for (final p in await requiredPermissions()) {
      if (await p.status.isPermanentlyDenied) return true;
    }
    return false;
  }
}
