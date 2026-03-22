import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:workout_helper/plank_analyzer.dart';
import 'package:workout_helper/pose_input.dart';
import 'package:workout_helper/squat_analyzer.dart';
import 'package:workout_helper/pose_painter.dart';


enum Exercise { squat, plank }

// CameraScreen
//   - Camera lifecycle
//   - Frame → ML Kit input conversion
//   - Routing detected poses to the correct analyzer
//   - Rendering the camera preview, skeleton overlay, and stats HUD

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _camera;
  bool _cameraReady = false;
  Size _imageSize   = Size.zero;

  final _audioPlayer = AudioPlayer();
  final _detector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );
  bool     _busy      = false;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);

  static const _frameInterval = Duration(milliseconds: 100);

  final _squatAnalyzer = SquatAnalyzer();
  final _plankAnalyzer = PlankAnalyzer();

  Exercise _exercise = Exercise.squat;

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

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _camera?.stopImageStream();
    _camera?.dispose();
    _detector.close();
    _notifier.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final cam = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _camera = CameraController(
      cam,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup:
      Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
    );

    await _camera!.initialize();
    _imageSize = _camera!.value.previewSize ?? Size.zero;
    await _camera!.startImageStream(_onFrame);

    if (!mounted) return;
    setState(() => _cameraReady = true);
  }

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

      switch (_exercise) {
        case Exercise.squat:
          _squatResult = _squatAnalyzer.update(_pose!);
          if (_squatResult.repJustCompleted) {
            _audioPlayer.play(AssetSource('assets/correct.m4a'));
          }

        case Exercise.plank:
          final prev2 = _plankResult;
          _plankResult = _plankAnalyzer.update(_pose!);
          if (prev2.stage == PlankStage.holding &&
              _plankResult.stage == PlankStage.notReady) {
            _audioPlayer.play(AssetSource('assets/incorrect.mp3'));
          }
      }

      _notifier.value++;
    } catch (e) {
      debugPrint('Frame error: $e');
    } finally {
      _busy = false;
    }
  }

  void _switchExercise(Exercise exercise) {
    if (_exercise == exercise) return;
    _squatAnalyzer.reset();
    _plankAnalyzer.reset();
    setState(() => _exercise = exercise);
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraReady || _camera == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_camera!),

          ValueListenableBuilder<int>(
            valueListenable: _notifier,
            builder: (context, _, __) => Stack(
              fit: StackFit.expand,
              children: [
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
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: _exercise == Exercise.squat
                      ? _SquatHud(result: _squatResult)
                      : _PlankHud(result: _plankResult),
                ),

                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _ExerciseToggle(
                        current: _exercise,
                        onSelect: _switchExercise,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// knee angle and reps

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
        _StatCard(
          label: 'REPS',
          value: '${result.reps}',
        ),
      ],
    );
  }
}

//body angle
class _PlankHud extends StatelessWidget {
  final PlankResult result;
  const _PlankHud({required this.result});

  @override
  Widget build(BuildContext context) {
    final holding = result.stage == PlankStage.holding;
    final seconds = result.holdDuration.inSeconds;

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
          value: holding ? '${seconds}s' : '--',
        ),
      ],
    );
  }
}

class _ExerciseToggle extends StatelessWidget {
  final Exercise           current;
  final ValueChanged<Exercise> onSelect;

  const _ExerciseToggle({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: Exercise.values.map((ex) {
        final selected = current == ex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () => onSelect(ex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.black.withOpacity(0.60),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: selected ? Colors.white : Colors.white38),
              ),
              child: Text(
                ex.name.toUpperCase(),
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}