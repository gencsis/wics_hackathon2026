import 'dart:async';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'camera_screen.dart';
import 'end_workout_screen.dart';
import 'exercise.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final Exercise exercise;
  final int targetValue;

  const WorkoutSessionScreen({
    super.key,
    required this.exercise,
    required this.targetValue,
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  Timer? _timer;
  int currentValue = 0;

  bool get isTimed => widget.exercise.mode == ExerciseMode.timed;


  CameraExercise? get _cameraExercise {
    switch (widget.exercise.title.toLowerCase()) {
      case 'squats':
        return CameraExercise.squat;
      case 'plank':
        return CameraExercise.plank;
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();

    if (isTimed) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => currentValue++);
        if (currentValue >= widget.targetValue) {
          _finishWorkout(autoCompleted: true);
        }
      });
    }
  }

  void _incrementCount() {
    if (isTimed) return;
    setState(() => currentValue++);
    if (currentValue >= widget.targetValue) {
      _finishWorkout(autoCompleted: true);
    }
  }

  void _finishWorkout({required bool autoCompleted}) {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EndWorkoutScreen(
          exerciseName: widget.exercise.title,
          resultLabel: isTimed ? 'Time' : 'Count',
          resultValue:
          isTimed ? '$currentValue sec' : '$currentValue reps',
          autoCompleted: autoCompleted,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promptText = isTimed
        ? 'Stand 4–6 feet away and keep your full body in frame.'
        : 'Stand far enough so your full movement is visible in frame.';

    final cameraExercise = _cameraExercise;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTimed ? 'time workout' : 'count workout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Placement prompt
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary, width: 1.4),
              ),
              child: Text(
                promptText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Camera area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: cameraExercise != null
                      ? CameraScreen(exercise: cameraExercise)

                      : const _CameraPlaceholder(),
                ),
              ),
            ),

            const SizedBox(height: 20),


            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.end,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => _finishWorkout(autoCompleted: false),
                child: const Text(
                  'END',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shown for exercises that don't have camera detection yet
class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Text(
          'Camera detection\nnot available yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
          ),
        ),
      ),
    );
  }
}