import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum SquatStage {
  notReady,    // landmarks not visible or confidence too low
  standing,    // upright — angle >= standAngle
  descending,  // angle dropping from standing
  bottom,      // angle <= bottomAngle, squat confirmed
  ascending,   // rising back up after confirmed squat
}

class SquatResult {
  final SquatStage stage;
  final double     kneeAngle;
  final int        reps;
  final bool       repJustCompleted;

  const SquatResult({
    required this.stage,
    required this.kneeAngle,
    required this.reps,
    required this.repJustCompleted,
  });
}

class SquatAnalyzer {
  // Thresholds
  static const double _standAngle   = 160.0; // leg straight
  static const double _descentAngle = 140.0; // descent has started
  static const double _bottomAngle  =  90.0; // squat angle confirmed
  static const double _ascentAngle  = 120.0; // rising after completion

  // Confidence
  static const double _minConfidence    = 0.65;
  static const double minConfidence     = _minConfidence;

  // user turned away from camera
  static const double _maxSideDifference = 25.0;

  // Smoothing
  static const int _smoothingWindow = 5;
  final _angleHistory = Queue<double>();

  // State
  SquatStage _stage = SquatStage.notReady;
  int        _reps  = 0;

  // API
  SquatResult update(Pose pose) {
    if (!_landmarksReady(pose)) {
      _stage = SquatStage.notReady;
      return _result(repJustCompleted: false);
    }

    final raw = _bilateralKneeAngle(pose);
    if (raw == null) {
      _stage = SquatStage.notReady;
      return _result(repJustCompleted: false);
    }

    _pushAngle(raw);
    final repJustCompleted = _advance(_smoothedAngle);
    return _result(repJustCompleted: repJustCompleted);
  }

  void reset() {
    _stage = SquatStage.notReady;
    _reps  = 0;
    _angleHistory.clear();
  }

  static const _required = [
    PoseLandmarkType.leftHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.rightAnkle,
  ];

  bool _landmarksReady(Pose pose) => _required.every((type) {
    final lm = pose.landmarks[type];
    return lm != null && lm.likelihood >= _minConfidence;
  });

  double? _bilateralKneeAngle(Pose pose) {
    final left = _angleAt(
      pose.landmarks[PoseLandmarkType.leftHip]!,
      pose.landmarks[PoseLandmarkType.leftKnee]!,
      pose.landmarks[PoseLandmarkType.leftAnkle]!,
    );
    final right = _angleAt(
      pose.landmarks[PoseLandmarkType.rightHip]!,
      pose.landmarks[PoseLandmarkType.rightKnee]!,
      pose.landmarks[PoseLandmarkType.rightAnkle]!,
    );
    if ((left - right).abs() > _maxSideDifference) return null;
    return (left + right) / 2.0;
  }


  // Returns the angle at [b] in the triangle a–b–c.

  double _angleAt(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ab = Offset(a.x - b.x, a.y - b.y);
    final cb = Offset(c.x - b.x, c.y - b.y);
    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final mag = math.sqrt(ab.dx * ab.dx + ab.dy * ab.dy) *
        math.sqrt(cb.dx * cb.dx + cb.dy * cb.dy);
    if (mag == 0) return 0;
    return math.acos((dot / mag).clamp(-1.0, 1.0)) * 180 / math.pi;
  }

  // More smoothing

  void _pushAngle(double angle) {
    _angleHistory.addLast(angle);
    if (_angleHistory.length > _smoothingWindow) _angleHistory.removeFirst();
  }

  double get _smoothedAngle {
    if (_angleHistory.isEmpty) return 0;
    return _angleHistory.reduce((a, b) => a + b) / _angleHistory.length;
  }

  // State machine

  bool _advance(double angle) {
    var repCompleted = false;

    switch (_stage) {
      case SquatStage.notReady:
        if (angle >= _standAngle) _stage = SquatStage.standing;

      case SquatStage.standing:
        if (angle < _descentAngle) _stage = SquatStage.descending;

      case SquatStage.descending:
        if (angle <= _bottomAngle) {
          _stage = SquatStage.bottom;
        } else if (angle >= _standAngle) {
          _stage = SquatStage.standing;
        }

      case SquatStage.bottom:
        if (angle > _ascentAngle) _stage = SquatStage.ascending;

      case SquatStage.ascending:
        if (angle >= _standAngle) {
          _reps++;
          repCompleted = true;
          _stage = SquatStage.standing;
        } else if (angle <= _bottomAngle) {
          _stage = SquatStage.bottom;
        }
    }

    return repCompleted;
  }

  // helper

  SquatResult _result({required bool repJustCompleted}) => SquatResult(
    stage: _stage,
    kneeAngle: _smoothedAngle,
    reps: _reps,
    repJustCompleted: repJustCompleted,
  );
}