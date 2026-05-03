import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService extends GetxService {
  Future<bool> requestCheckInPermissions() async {
    final results = await [
      Permission.camera,
      Permission.locationWhenInUse,
    ].request();
    return results.values.every((s) => s.isGranted);
  }

  Future<bool> get cameraGranted async =>
      (await Permission.camera.status).isGranted;

  Future<bool> get locationGranted async =>
      (await Permission.locationWhenInUse.status).isGranted;
}
