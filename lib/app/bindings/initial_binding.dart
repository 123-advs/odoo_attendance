import 'package:get/get.dart';

import '../services/api_service.dart';
import '../services/face_match_service.dart';
import '../services/permission_service.dart';
import '../services/storage_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<StorageService>(StorageService(), permanent: true);
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<PermissionService>(PermissionService(), permanent: true);

    // Fire-and-forget TFLite load. The service exposes `isReady` so
    // any consumer (FaceCapture/Enroll screens) can show a "model not
    // ready" state if the .tflite asset isn't present yet.
    final faceMatch = FaceMatchService();
    Get.put<FaceMatchService>(faceMatch, permanent: true);
    faceMatch.init();
  }
}
