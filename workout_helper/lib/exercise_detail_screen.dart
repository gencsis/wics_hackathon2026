import 'package:flutter/material.dart';
import 'exercise.dart';
import 'app_colors.dart';
import 'workout_session_screen.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final TextEditingController inputController = TextEditingController();

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTimed = widget.exercise.mode == ExerciseMode.timed;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Quick tutorial card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QUICK TUTORIAL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.sticker,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: widget.exercise.gifPath.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              widget.exercise.gifPath,
                              fit: BoxFit.contain,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.fitness_center,
                              size: 48,
                              color: AppColors.primaryDark,
                            ),
                          ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    widget.exercise.tutorialText,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Amount input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    isTimed ? 'AMOUNT OF TIME' : 'AMOUNT OF REPS',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: inputController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: isTimed ? 'sec' : 'reps',
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  final value = int.tryParse(inputController.text) ?? 0;
                  if (value <= 0) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutSessionScreen(
                        exercise: widget.exercise,
                        targetValue: value,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'START',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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