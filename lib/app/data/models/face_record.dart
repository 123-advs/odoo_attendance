import 'dart:typed_data';

/// Output of a successful face capture flow.
///
/// `selfieJpeg` is the compressed full-frame selfie sent to Odoo as
/// audit evidence. `faceCropJpeg` is the tight 112×112 crop fed to
/// MobileFaceNet (kept around so we can re-extract embedding if needed).
/// `embedding` is the 192-d L2-normalized vector ready for cosine.
/// `matchScore` is the cosine similarity vs the enrolled embedding —
/// only meaningful for check-in/out flow, set to 1.0 for enrollment.
class FaceCaptureResult {
  const FaceCaptureResult({
    required this.selfieJpeg,
    required this.faceCropJpeg,
    required this.embedding,
    required this.matchScore,
  });

  final Uint8List selfieJpeg;
  final Uint8List faceCropJpeg;
  final List<double> embedding;
  final double matchScore;
}
