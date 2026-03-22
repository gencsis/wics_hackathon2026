import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:workout_helper/pose_input.dart';
import 'package:workout_helper/squat_analyzer.dart';
import 'package:workout_helper/pose_painter.dart';

// CameraScreen
//   - Camera lifecycle
//   - Pass frames to PoseInputConverter and PoseDetector
//   - Pass detected poses to SquatAnalyzer
//   - Render camera preview, pose skeleton, and debugging containers

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _camera;
  bool  _cameraReady = false;
  Size  _imageSize   = Size.zero;

  final _detector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );

  bool     _busy      = false;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);

  static const _frameInterval = Duration(milliseconds: 100);

  final _analyzer = SquatAnalyzer();


  // avoids rebuilding CameraPreview
  SquatResult _result = const SquatResult(
    stage: SquatStage.notReady,
    kneeAngle: 0,
    reps: 0,
    repJustCompleted: false,
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
        _result = SquatResult(
          stage: SquatStage.notReady,
          kneeAngle: 0,
          reps: _result.reps,
          repJustCompleted: false,
        );
        _notifier.value++;
        return;
      }

      _pose   = poses.first;
      _result = _analyzer.update(_pose!);
      _notifier.value++;
    } catch (e) {
      debugPrint('Frame error: $e');
    } finally {
      _busy = false;
    }
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
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: _StatsHud(result: _result),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//knee angle and reps containers
class _StatsHud extends StatelessWidget {
  final SquatResult result;

  const _StatsHud({required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatCard(
          label: 'KNEE ANGLE',
          value: result.stage == SquatStage.notReady
              ? '--'
              : '${result.kneeAngle.toInt()}°',
        ),
        _StatCard(
          label: 'REPS',
          value: '${result.reps}',
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
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}