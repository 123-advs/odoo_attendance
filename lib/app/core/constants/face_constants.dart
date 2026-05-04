class FaceConstants {
  FaceConstants._();

  // Match threshold: cosine similarity >= this is considered a match.
  // 0.70 is the typical MobileFaceNet baseline; tune after collecting
  // false-positive / false-negative rates from real users.
  static const double matchThreshold = 0.70;

  // ML Kit minimum face size (proportion of image height/width).
  static const double minFaceSize = 0.25;

  // Eyes-open + head-pose checks
  static const double eyesOpenMin = 0.4;
  static const double headPoseMaxYDeg = 25.0;

  // TFLite model
  static const String modelAssetPath = 'assets/models/mobilefacenet.tflite';
  static const int modelInputSize = 112;
  static const int embeddingLength = 192;

  // Selfie compression for upload
  static const int selfieMaxDim = 640;
  static const int selfieJpegQuality = 80;

  // Capture flow
  static const int maxMatchAttempts = 3;
}
