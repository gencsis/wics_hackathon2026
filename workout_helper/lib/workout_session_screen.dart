import 'dart:async';
import 'package:flutter/material.dart';
import 'exercise.dart';
import 'app_colors.dart';
import 'end_workout_screen.dart';

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

  @override
  void initState() {
    super.initState();

    if (isTimed) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          currentValue++;
        });

        if (currentValue >= widget.targetValue) {
          _finishWorkout(autoCompleted: true);
        }
      });
    }
  }

  void _incrementCount() {
    if (!isTimed) {
      setState(() {
        currentValue++;
      });

      if (currentValue >= widget.targetValue) {
        _finishWorkout(autoCompleted: true);
      }
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
          resultValue: isTimed ? '$currentValue sec' : '$currentValue reps',
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isTimed ? 'time workout' : 'count workout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // placement prompt
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

            // camera area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
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
                  child: Container(
                    color: AppColors.background,
                    child: const Center(
                      child: Text(
                        'Camera Feed Goes Here',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // current count/time
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isTimed ? 'CURRENT TIME' : 'CURRENT COUNT',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTimed ? '$currentValue sec' : '$currentValue reps',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (!isTimed) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _incrementCount,
                  child: const Text(
                    'ADD REP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}