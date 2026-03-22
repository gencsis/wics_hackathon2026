import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

//   Green  = landmark is above the confidence threshold (trusted by analyzer)
//   Yellow = landmark is below the confidence threshold (ignored by analyzer)
class PosePainter extends CustomPainter {
  final Pose   pose;
  final Size   imageSize;
  final Size   screenSize;
  final double minConfidence;

  const PosePainter({
    required this.pose,
    required this.imageSize,
    required this.screenSize,
    required this.minConfidence,
  });

  static const _connections = [
    // Head
    [PoseLandmarkType.nose,          PoseLandmarkType.leftEye],
    [PoseLandmarkType.nose,          PoseLandmarkType.rightEye],
    [PoseLandmarkType.leftEye,       PoseLandmarkType.leftEar],
    [PoseLandmarkType.rightEye,      PoseLandmarkType.rightEar],
    // Torso
    [PoseLandmarkType.leftShoulder,  PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder,  PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip,       PoseLandmarkType.rightHip],
    // Arms
    [PoseLandmarkType.leftShoulder,  PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow,     PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow,    PoseLandmarkType.rightWrist],
    // Legs
    [PoseLandmarkType.leftHip,       PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee,      PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip,      PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee,     PoseLandmarkType.rightAnkle],
    // Feet
    [PoseLandmarkType.leftAnkle,     PoseLandmarkType.leftHeel],
    [PoseLandmarkType.leftAnkle,     PoseLandmarkType.leftFootIndex],
    [PoseLandmarkType.rightAnkle,    PoseLandmarkType.rightHeel],
    [PoseLandmarkType.rightAnkle,    PoseLandmarkType.rightFootIndex],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == Size.zero) return;

    final scaleX = screenSize.width  / imageSize.height;
    final scaleY = screenSize.height / imageSize.width;

    // Flip horizontally to match the mirrored front camera preview
    Offset toScreen(PoseLandmark lm) => Offset(
      (imageSize.height - lm.x) * scaleX,
      lm.y * scaleY,
    );

    final linePaint = Paint()
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..style = PaintingStyle.fill;

    // Bones
    for (final conn in _connections) {
      final a = pose.landmarks[conn[0]];
      final b = pose.landmarks[conn[1]];
      if (a == null || b == null) continue;

      final confident =
          a.likelihood >= minConfidence && b.likelihood >= minConfidence;

      linePaint.color = confident
          ? Colors.greenAccent.withOpacity(0.85)
          : Colors.yellow.withOpacity(0.45);

      canvas.drawLine(toScreen(a), toScreen(b), linePaint);
    }

    // Joints
    for (final lm in pose.landmarks.values) {
      final confident = lm.likelihood >= minConfidence;
      dotPaint.color =
      confident ? Colors.greenAccent : Colors.yellow.withOpacity(0.55);
      canvas.drawCircle(toScreen(lm), confident ? 5.5 : 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(PosePainter old) =>
      old.pose != pose || old.screenSize != screenSize;
}