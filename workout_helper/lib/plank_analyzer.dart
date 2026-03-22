import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';


enum PlankStage {
  notReady, // landmarks missing, confidence too low, or body line too far off
  settling, // body line is good, waiting for stabilisation frames before confirming
  holding,  // hold confirmed and actively being timed
}


class PlankResult {
  final PlankStage stage;
  final double     bodyAngle;     // smoothed shoulder–hip–ankle angle
  final double     deviation;     // how far off straight
  final Duration   holdDuration;  // how long the current hold has lasted
  final bool       holdJustStarted; // true only on the frame holding begins

  const PlankResult({
    required this.stage,
    required this.bodyAngle,
    required this.deviation,
    required this.holdDuration,
    required this.holdJustStarted,
  });
}


// Mirrors SquatAnalyzer exactly in structure.

class PlankAnalyzer {
  // Thresholds
  static const double _goodDeviationThreshold = 15.0;

  static const double _breakDeviationThreshold = 25.0;

  static const int _settlingFrames = 5;

  static const double minConfidence = 0.65;

  static const double _maxSideDiff  = 20.0;

  // Smoothing
  static const int _smoothingWindow = 5;
  final _angleHistory = Queue<double>();

  // State
  PlankStage _stage         = PlankStage.notReady;
  int        _settlingCount = 0;
  DateTime?  _holdStart;

  PlankResult update(Pose pose) {
    if (!_landmarksReady(pose)) {
      _reset();
      return _result(holdJustStarted: false);
    }

    final raw = _bilateralBodyAngle(pose);
    if (raw == null) {
      _reset();
      return _result(holdJustStarted: false);
    }

    _pushAngle(raw);
    final angle     = _smoothedAngle;
    final deviation = (180.0 - angle).abs();

    final holdJustStarted = _advance(deviation);
    return _result(holdJustStarted: holdJustStarted);
  }

  void reset() => _reset();

  // validation
  static const _required = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.rightAnkle,
  ];

  bool _landmarksReady(Pose pose) => _required.every((type) {
    final lm = pose.landmarks[type];
    return lm != null && lm.likelihood >= minConfidence;
  });


  double? _bilateralBodyAngle(Pose pose) {
    final left = _angleAt(
      pose.landmarks[PoseLandmarkType.leftShoulder]!,
      pose.landmarks[PoseLandmarkType.leftHip]!,
      pose.landmarks[PoseLandmarkType.leftAnkle]!,
    );
    final right = _angleAt(
      pose.landmarks[PoseLandmarkType.rightShoulder]!,
      pose.landmarks[PoseLandmarkType.rightHip]!,
      pose.landmarks[PoseLandmarkType.rightAnkle]!,
    );
    if ((left - right).abs() > _maxSideDiff) return null;
    return (left + right) / 2.0;
  }

  // math for angle
  double _angleAt(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ab = Offset(a.x - b.x, a.y - b.y);
    final cb = Offset(c.x - b.x, c.y - b.y);
    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final mag = math.sqrt(ab.dx * ab.dx + ab.dy * ab.dy) *
        math.sqrt(cb.dx * cb.dx + cb.dy * cb.dy);
    if (mag == 0) return 0;
    return math.acos((dot / mag).clamp(-1.0, 1.0)) * 180 / math.pi;
  }


  void _pushAngle(double angle) {
    _angleHistory.addLast(angle);
    if (_angleHistory.length > _smoothingWindow) _angleHistory.removeFirst();
  }

  double get _smoothedAngle {
    if (_angleHistory.isEmpty) return 0;
    return _angleHistory.reduce((a, b) => a + b) / _angleHistory.length;
  }

  // state machine
  bool _advance(double deviation) {
    var holdJustStarted = false;

    switch (_stage) {
      case PlankStage.notReady:
        if (deviation <= _goodDeviationThreshold) {
          _stage         = PlankStage.settling;
          _settlingCount = 1;
        }

      case PlankStage.settling:
        if (deviation <= _goodDeviationThreshold) {
          _settlingCount++;
          if (_settlingCount >= _settlingFrames) {
            _stage     = PlankStage.holding;
            _holdStart = DateTime.now();
            holdJustStarted = true;
          }
        } else {
          _stage         = PlankStage.notReady;
          _settlingCount = 0;
        }

      case PlankStage.holding:
        if (deviation > _breakDeviationThreshold) {
          _reset();
        }
    }

    return holdJustStarted;
  }

  // helpers
  void _reset() {
    _stage         = PlankStage.notReady;
    _settlingCount = 0;
    _holdStart     = null;
    _angleHistory.clear();
  }

  Duration get _holdDuration {
    if (_stage != PlankStage.holding || _holdStart == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(_holdStart!);
  }

  PlankResult _result({required bool holdJustStarted}) => PlankResult(
    stage: _stage,
    bodyAngle: _smoothedAngle,
    deviation: _smoothedAngle == 0 ? 0 : (180.0 - _smoothedAngle).abs(),
    holdDuration: _holdDuration,
    holdJustStarted: holdJustStarted,
  );
}