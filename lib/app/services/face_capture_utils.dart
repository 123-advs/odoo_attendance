import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../core/constants/face_constants.dart';

/// Result of a single quality assessment on detected faces.
class FaceQuality {
  const FaceQuality({
    required this.face,
    required this.reason,
    required this.isGood,
  });

  final Face? face;
  final String reason;
  final bool isGood;
}

/// Static helpers for the face capture flow — camera lifecycle,
/// quality assessment, face cropping. Each capture screen owns its
/// own CameraController and FaceDetector; these helpers are pure.
class FaceCaptureUtils {
  FaceCaptureUtils._();

  /// Build the standard ML Kit options used across capture / enroll.
  static FaceDetectorOptions detectorOptions() {
    return FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableClassification: true, // eyes-open + smile probabilities
      enableLandmarks: false,
      enableContours: false,
      enableTracking: false,
      minFaceSize: FaceConstants.minFaceSize,
    );
  }

  /// Create the standard ML Kit detector. Caller is responsible for
  /// calling `detector.close()` in onClose.
  static FaceDetector createDetector() =>
      FaceDetector(options: detectorOptions());

  /// Find the front camera and initialize a controller. Returns null
  /// if no camera available (e.g. emulator without front cam) or
  /// initialization failed.
  static Future<CameraController?> initFrontCamera({
    ResolutionPreset preset = ResolutionPreset.medium,
  }) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('[FaceCapture] No cameras available');
        return null;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        preset,
        enableAudio: false,
        // NV21 keeps stream frames in a layout ML Kit expects natively
        // on Android. takePicture() still returns JPEG regardless.
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await controller.initialize();
      return controller;
    } catch (e, st) {
      debugPrint('[FaceCapture] Camera init failed: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }

  /// Run face detection on a still image at `filePath` (e.g. from
  /// `controller.takePicture()`). Returns the assessed quality.
  static Future<FaceQuality> detectFromFile(
    FaceDetector detector,
    String filePath,
  ) async {
    try {
      final faces = await detector.processImage(InputImage.fromFilePath(filePath));
      return assess(faces);
    } catch (e) {
      debugPrint('[FaceCapture] detectFromFile failed: $e');
      return const FaceQuality(
        face: null,
        reason: 'Lỗi xử lý ảnh',
        isGood: false,
      );
    }
  }

  /// Pure rule-based quality scoring on a list of detected faces.
  static FaceQuality assess(List<Face> faces) {
    if (faces.isEmpty) {
      return const FaceQuality(
        face: null,
        reason: 'Không thấy khuôn mặt — đưa mặt vào khung',
        isGood: false,
      );
    }
    if (faces.length > 1) {
      return const FaceQuality(
        face: null,
        reason: 'Có nhiều khuôn mặt — chỉ 1 người vào khung',
        isGood: false,
      );
    }
    final face = faces.first;

    final leftEye = face.leftEyeOpenProbability ?? 1.0;
    final rightEye = face.rightEyeOpenProbability ?? 1.0;
    if (leftEye < FaceConstants.eyesOpenMin ||
        rightEye < FaceConstants.eyesOpenMin) {
      return FaceQuality(
        face: face,
        reason: 'Mắt nhắm — vui lòng mở mắt',
        isGood: false,
      );
    }

    final headY = (face.headEulerAngleY ?? 0).abs();
    final headZ = (face.headEulerAngleZ ?? 0).abs();
    if (headY > FaceConstants.headPoseMaxYDeg ||
        headZ > FaceConstants.headPoseMaxYDeg) {
      return FaceQuality(
        face: face,
        reason: 'Hãy nhìn thẳng vào camera',
        isGood: false,
      );
    }

    return FaceQuality(
      face: face,
      reason: 'Sẵn sàng — chạm để chụp',
      isGood: true,
    );
  }

  /// Crop a square region around the face (with `padding` extra on
  /// each side) and resize to MobileFaceNet input size. Returns JPEG
  /// bytes ready for [FaceMatchService.extractEmbedding].
  static Uint8List? cropFaceJpeg(
    Uint8List jpegBytes,
    Face face, {
    double padding = 0.3,
  }) {
    final decoded = img.decodeImage(jpegBytes);
    if (decoded == null) return null;

    final bbox = face.boundingBox;
    final padX = bbox.width * padding;
    final padY = bbox.height * padding;
    final left = (bbox.left - padX).clamp(0.0, decoded.width.toDouble());
    final top = (bbox.top - padY).clamp(0.0, decoded.height.toDouble());
    final right =
        (bbox.right + padX).clamp(0.0, decoded.width.toDouble());
    final bottom =
        (bbox.bottom + padY).clamp(0.0, decoded.height.toDouble());

    final w = (right - left).toInt();
    final h = (bottom - top).toInt();
    if (w <= 0 || h <= 0) return null;

    final cropped = img.copyCrop(
      decoded,
      x: left.toInt(),
      y: top.toInt(),
      width: w,
      height: h,
    );
    final resized = img.copyResize(
      cropped,
      width: FaceConstants.modelInputSize,
      height: FaceConstants.modelInputSize,
      interpolation: img.Interpolation.cubic,
    );
    return Uint8List.fromList(
      img.encodeJpg(resized, quality: FaceConstants.selfieJpegQuality),
    );
  }

  /// Compress a still selfie down to `selfieMaxDim` longest edge for
  /// upload to Odoo as `face_image_in/out`.
  static Uint8List? compressSelfie(Uint8List jpegBytes) {
    final decoded = img.decodeImage(jpegBytes);
    if (decoded == null) return null;
    final maxDim = FaceConstants.selfieMaxDim;
    final needsResize = decoded.width > maxDim || decoded.height > maxDim;
    final resized = needsResize
        ? (decoded.width >= decoded.height
            ? img.copyResize(decoded, width: maxDim)
            : img.copyResize(decoded, height: maxDim))
        : decoded;
    return Uint8List.fromList(
      img.encodeJpg(resized, quality: FaceConstants.selfieJpegQuality),
    );
  }
}
