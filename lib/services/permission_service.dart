import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request the runtime perms required for BLE central + UWB on Android 12+.
  /// UWB_RANGING is implicitly granted to apps in the foreground; we don't
  /// prompt for it via permission_handler.
  Future<bool> requestRuntimePermissions() async {
    final result = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    return result.values.every((s) => s.isGranted);
  }

  Future<bool> areGranted() async {
    final scan = await Permission.bluetoothScan.status;
    final connect = await Permission.bluetoothConnect.status;
    return scan.isGranted && connect.isGranted;
  }
}
