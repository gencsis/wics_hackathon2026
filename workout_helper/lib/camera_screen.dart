import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:cathlete/plank_analyzer.dart';
import 'package:cathlete/pose_input.dart';
import 'package:cathlete/squat_analyzer.dart';
import 'package:cathlete/pose_painter.dart';

enum CameraExercise { squat, plank }

class CameraScreen extends StatefulWidget {
  final CameraExercise exercise;
  const CameraScreen({super.key, required this.exercise});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _camera;
  bool _cameraReady = false;
  Size _imageSize   = Size.zero;

  // Which direction the active camera is facing.
  // Starts on front so the user can see themselves.
  CameraLensDirection _lensDirection = CameraLensDirection.front;

  // ── Audio ────────────────────────────────────────────────────────────────────
  final _correctPlayer   = AudioPlayer();
  final _incorrectPlayer = AudioPlayer();

  static const _correctSound   = 'correct.m4a';
  static const _incorrectSound = 'incorrect.mp3';

  bool _correctPlaying   = false;
  bool _incorrectPlaying = false;

  Future<void> _playCorrect() async {
    if (_correctPlaying) return;
    _correctPlaying = true;
    await _correctPlayer.play(AssetSource(_correctSound));
    _correctPlaying = false;
  }

  Future<void> _playIncorrect() async {
    if (_incorrectPlaying) return;
    _incorrectPlaying = true;
    await _incorrectPlayer.play(AssetSource(_incorrectSound));
    _incorrectPlaying = false;
  }

  // ── Detector ─────────────────────────────────────────────────────────────────
  final _detector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );
  bool     _busy      = false;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);
  static const _frameInterval = Duration(milliseconds: 100);

  // ── Analyzers ─────────────────────────────────────────────────────────────────
  final _squatAnalyzer = SquatAnalyzer();
  final _plankAnalyzer = PlankAnalyzer();

  // ── Display state ─────────────────────────────────────────────────────────────
  SquatResult _squatResult = const SquatResult(
    stage: SquatStage.notReady,
    kneeAngle: 0,
    reps: 0,
    repJustCompleted: false,
  );
  PlankResult _plankResult = const PlankResult(
    stage: PlankStage.notReady,
    bodyAngle: 0,
    deviation: 0,
    holdDuration: Duration.zero,
    holdJustStarted: false,
  );
  Pose? _pose;

  final _notifier = ValueNotifier<int>(0);

  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initAudio();
    _initCamera(_lensDirection);
  }

  @override
  void dispose() {
    _correctPlayer.dispose();
    _incorrectPlayer.dispose();
    _camera?.stopImageStream();
    _camera?.dispose();
    _detector.close();
    _notifier.dispose();
    super.dispose();
  }

  // ── Audio ─────────────────────────────────────────────────────────────────────

  Future<void> _initAudio() async {
    await _correctPlayer.setSource(AssetSource(_correctSound));
    await _incorrectPlayer.setSource(AssetSource(_incorrectSound));
  }

  // ── Camera ────────────────────────────────────────────────────────────────────

  Future<void> _initCamera(CameraLensDirection direction) async {
    // Tear down the existing camera before starting a new one
    await _camera?.stopImageStream();
    await _camera?.dispose();
    _camera = null;

    if (mounted) setState(() => _cameraReady = false);

    final cameras = await availableCameras();

    // Pick the camera that matches the requested direction.
    // Fall back to whatever is available if the device only has one camera.
    final cam = cameras.firstWhere(
          (c) => c.lensDirection == direction,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup:
      Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
    );

    await controller.initialize();

    if (!mounted) {
      await controller.dispose();
      return;
    }

    _camera    = controller;
    _imageSize = controller.value.previewSize ?? Size.zero;

    // Reset analyzers so state from the previous camera session doesn't carry over
    _squatAnalyzer.reset();
    _plankAnalyzer.reset();

    await controller.startImageStream(_onFrame);
    setState(() => _cameraReady = true);
  }

  // ── Flip camera ───────────────────────────────────────────────────────────────

  Future<void> _flipCamera() async {
    final next = _lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    _lensDirection = next;
    await _initCamera(next);
  }

  // ── Frame processing ──────────────────────────────────────────────────────────

  Future<void> _onFrame(CameraImage image) async {
    final now = DateTime.now();
    if (now.difference(_lastFrame) < _frameInterval) return;
    _lastFrame = now;

    if (_busy || _camera == null) return;
    _busy = true;

    try {
      final input = PoseInputConverter.toInputImage(image, _camera!);
      if (input == null) return;

      final poses = await _detector.processImage(input);

      if (poses.isEmpty) {
        _pose = null;
        _squatAnalyzer.reset();
        _plankAnalyzer.reset();
        _notifier.value++;
        return;
      }

      _pose = poses.first;

      switch (widget.exercise) {
        case CameraExercise.squat:
          final prev   = _squatResult;
          _squatResult = _squatAnalyzer.update(_pose!);

          if (_squatResult.repJustCompleted) _playCorrect();

          if (prev.stage == SquatStage.descending &&
              _squatResult.stage == SquatStage.standing) {
            _playIncorrect();
          }

        case CameraExercise.plank:
          final prev   = _plankResult;
          _plankResult = _plankAnalyzer.update(_pose!);

          if (_plankResult.holdJustStarted) _playCorrect();

          if (prev.stage == PlankStage.holding &&
              _plankResult.stage == PlankStage.notReady) {
            _playIncorrect();
          }
      }

      _notifier.value++;
    } catch (e) {
      debugPrint('Frame error: $e');
    } finally {
      _busy = false;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_cameraReady || _camera == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera feed — never rebuilds from the notifier
        CameraPreview(_camera!),

        ValueListenableBuilder<int>(
          valueListenable: _notifier,
          builder: (context, _, __) => Stack(
            fit: StackFit.expand,
            children: [
              // Skeleton overlay
              if (_pose != null)
                LayoutBuilder(
                  builder: (_, constraints) => CustomPaint(
                    painter: PosePainter(
                      pose: _pose!,
                      imageSize: _imageSize,
                      screenSize: Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                      minConfidence: SquatAnalyzer.minConfidence,
                    ),
                  ),
                ),

              // Stats HUD at the bottom
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: widget.exercise == CameraExercise.squat
                    ? _SquatHud(result: _squatResult)
                    : _PlankHud(result: _plankResult),
              ),
            ],
          ),
        ),

        // Flip button — sits in its own Positioned so it never gets
        // caught inside the ValueListenableBuilder rebuild cycle
        Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: GestureDetector(
              onTap: _flipCamera,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.flip_camera_ios_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// HUD widgets
// =============================================================================

class _SquatHud extends StatelessWidget {
  final SquatResult result;
  const _SquatHud({required this.result});

  @override
  Widget build(BuildContext context) {
    final ready = result.stage != SquatStage.notReady;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatCard(
          label: 'KNEE ANGLE',
          value: ready ? '${result.kneeAngle.toInt()}°' : '--',
        ),
        _StatCard(label: 'REPS', value: '${result.reps}'),
      ],
    );
  }
}

class _PlankHud extends StatelessWidget {
  final PlankResult result;
  const _PlankHud({required this.result});

  @override
  Widget build(BuildContext context) {
    final holding = result.stage == PlankStage.holding;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatCard(
          label: 'BODY ANGLE',
          value: result.stage == PlankStage.notReady
              ? '--'
              : '${result.deviation.toInt()}° off',
        ),
        _StatCard(
          label: 'HOLD',
          value: holding ? '${result.holdDuration.inSeconds}s' : '--',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 11, letterSpacing: 1.4)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}