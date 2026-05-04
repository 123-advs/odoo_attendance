import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../core/constants/face_constants.dart';

class FaceMatchService extends GetxService {
  Interpreter? _interpreter;
  final _isReady = false.obs;

  bool get isReady => _isReady.value;
  RxBool get readyRx => _isReady;

  /// Loads MobileFaceNet TFLite model from assets. Safe to fail —
  /// `isReady` stays false and consumers should fall back / show a
  /// "model missing" error.
  Future<void> init() async {
    try {
      _interpreter = await Interpreter.fromAsset(FaceConstants.modelAssetPath);
      _interpreter!.allocateTensors();
      final inShape = _interpreter!.getInputTensor(0).shape;
      final outShape = _interpreter!.getOutputTensor(0).shape;
      debugPrint(
          '[FaceMatch] Model loaded — input $inShape, output $outShape');
      _isReady.value = true;
    } catch (e) {
      debugPrint('[FaceMatch] Model load failed: $e');
      _isReady.value = false;
    }
  }

  /// Decode JPEG → resize 112×112 → normalize to [-1, 1] → run TFLite →
  /// return L2-normalized 192-d embedding. Returns null if model isn't
  /// loaded or anything fails.
  ///
  /// The TFLite interpreter cannot be moved across isolates, so we run
  /// inference on the main isolate. The work is fast (~50–150ms on a
  /// mid-range Android) and TFLite uses native threads internally, so
  /// the UI stays responsive.
  Future<List<double>?> extractEmbedding(Uint8List jpegBytes) async {
    final interp = _interpreter;
    if (!_isReady.value || interp == null) return null;

    try {
      final decoded = img.decodeImage(jpegBytes);
      if (decoded == null) return null;

      final resized = img.copyResize(
        decoded,
        width: FaceConstants.modelInputSize,
        height: FaceConstants.modelInputSize,
        interpolation: img.Interpolation.cubic,
      );

      // Build [1, 112, 112, 3] float32 in [-1, 1].
      final pixels = List.generate(
        1,
        (_) => List.generate(
          FaceConstants.modelInputSize,
          (y) => List.generate(FaceConstants.modelInputSize, (x) {
            final p = resized.getPixel(x, y);
            return [
              (p.r.toDouble() - 127.5) / 127.5,
              (p.g.toDouble() - 127.5) / 127.5,
              (p.b.toDouble() - 127.5) / 127.5,
            ];
          }),
        ),
      );

      final output = List.generate(
        1,
        (_) => List<double>.filled(FaceConstants.embeddingLength, 0),
      );
      interp.run(pixels, output);

      return _l2Normalize(output[0]);
    } catch (e, st) {
      debugPrint('[FaceMatch] extractEmbedding failed: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }

  /// Cosine similarity in [-1, 1]. Treats norm-zero vectors as 0.
  static double cosine(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0;
    double dot = 0;
    double na = 0;
    double nb = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na == 0 || nb == 0) return 0;
    return dot / (math.sqrt(na) * math.sqrt(nb));
  }

  /// Average + L2-normalize a list of embeddings (used for enrollment
  /// where we capture 3 angles and merge them into 1 stable template).
  static List<double> averageNormalized(List<List<double>> embeddings) {
    if (embeddings.isEmpty) return const [];
    final len = embeddings.first.length;
    final avg = List<double>.filled(len, 0);
    for (final e in embeddings) {
      for (var i = 0; i < len; i++) {
        avg[i] += e[i];
      }
    }
    for (var i = 0; i < len; i++) {
      avg[i] /= embeddings.length;
    }
    return _l2Normalize(avg);
  }

  static List<double> _l2Normalize(List<double> v) {
    double norm = 0;
    for (final x in v) {
      norm += x * x;
    }
    norm = math.sqrt(norm);
    if (norm == 0) return List<double>.filled(v.length, 0);
    return v.map((x) => x / norm).toList(growable: false);
  }

  @override
  void onClose() {
    _interpreter?.close();
    _interpreter = null;
    super.onClose();
  }
}
