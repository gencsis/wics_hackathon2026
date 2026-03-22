import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// =============================================================================
// PlankStage
//
// Stages advance in this order only:
//   notReady → settling → holding → (lost) → notReady
//
// "Settling" is a short stabilisation window before the hold is confirmed.
// This prevents a single good frame from immediately triggering a hold.
// The hold duration (seconds) is tracked and exposed in PlankResult.
//
// There are no reps for a plank — the metric is hold duration instead.
// =============================================================================

enum PlankStage {
  notReady, // landmarks missing, confidence too low, or body line too far off
  settling, // body line is good — waiting for stabilisation frames before confirming
  holding,  // hold confirmed and actively being timed
}

// =============================================================================
// PlankResult — returned every frame, consumed only by the UI
// =============================================================================

class PlankResult {
  final PlankStage stage;
  final double     bodyAngle;     // smoothed shoulder–hip–ankle angle, degrees
  final double     deviation;     // abs(180 - bodyAngle) — how far off straight
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

// =============================================================================
// PlankAnalyzer
//
// Mirrors SquatAnalyzer exactly in structure.
// The measured angle is the body-line angle: shoulder → hip → ankle.
// A perfect plank = 180°. We measure deviation from 180° rather than
// the raw angle so the threshold is intuitive (e.g. within 15° of straight).
// =============================================================================

class PlankAnalyzer {
  // ── Thresholds ────────────────────────────────────────────────────────────────
  // Body line must be within this many degrees of 180° to count as good form.
  static const double _goodDeviationThreshold = 15.0;
  // Body line must worsen past this before the hold is broken.
  // The gap between good and break thresholds acts as hysteresis —
  // minor wobbles don't break the hold immediately.
  static const double _breakDeviationThreshold = 25.0;

  // Number of consecutive good frames required before a hold is confirmed.
  // At ~10 fps this is roughly 0.5 s of stable position before we start timing.
  static const int _settlingFrames = 5;

  // ── Confidence ───────────────────────────────────────────────────────────────
  // Shared with SquatAnalyzer so the skeleton painter uses one value.
  static const double minConfidence = 0.65;
  // Max difference between left and right body-line angles.
  static const double _maxSideDiff  = 20.0;

  // ── Smoothing ────────────────────────────────────────────────────────────────
  static const int _smoothingWindow = 5;
  final _angleHistory = Queue<double>();

  // ── State ────────────────────────────────────────────────────────────────────
  PlankStage _stage         = PlankStage.notReady;
  int        _settlingCount = 0;
  DateTime?  _holdStart;

  // ── Public API ───────────────────────────────────────────────────────────────

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

  // ── Landmark validation ───────────────────────────────────────────────────────

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

  // ── Bilateral body-line angle ─────────────────────────────────────────────────
  // Computes shoulder→hip→ankle for both sides and averages them.
  // Returns null if the two sides disagree too much.

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

  // ── Angle math ────────────────────────────────────────────────────────────────

  double _angleAt(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ab = Offset(a.x - b.x, a.y - b.y);
    final cb = Offset(c.x - b.x, c.y - b.y);
    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final mag = math.sqrt(ab.dx * ab.dx + ab.dy * ab.dy) *
        math.sqrt(cb.dx * cb.dx + cb.dy * cb.dy);
    if (mag == 0) return 0;
    return math.acos((dot / mag).clamp(-1.0, 1.0)) * 180 / math.pi;
  }

  // ── Smoothing ─────────────────────────────────────────────────────────────────

  void _pushAngle(double angle) {
    _angleHistory.addLast(angle);
    if (_angleHistory.length > _smoothingWindow) _angleHistory.removeFirst();
  }

  double get _smoothedAngle {
    if (_angleHistory.isEmpty) return 0;
    return _angleHistory.reduce((a, b) => a + b) / _angleHistory.length;
  }

  // ── State machine ─────────────────────────────────────────────────────────────

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
            // Enough consecutive good frames — confirm the hold
            _stage     = PlankStage.holding;
            _holdStart = DateTime.now();
            holdJustStarted = true;
          }
        } else {
          // Wobbled before stabilising — restart the settling count
          _stage         = PlankStage.notReady;
          _settlingCount = 0;
        }

      case PlankStage.holding:
        if (deviation > _breakDeviationThreshold) {
          // Form has broken — end the hold, reset fully
          _reset();
        }
    // If form is slightly off (_goodDeviationThreshold < deviation <= _breakDeviationThreshold)
    // we stay in holding but keep timing. The hysteresis gap handles minor wobbles.
    }

    return holdJustStarted;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

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