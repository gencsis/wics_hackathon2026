import 'package:flutter/material.dart';
import 'app_colors.dart';

class EndWorkoutScreen extends StatelessWidget {
  final String exerciseName;
  final String resultLabel;
  final String resultValue;
  final bool autoCompleted;

  const EndWorkoutScreen({
    super.key,
    required this.exerciseName,
    required this.resultLabel,
    required this.resultValue,
    required this.autoCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('End workout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
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
              Text(
                autoCompleted ? 'Completed Workout 🎉' : 'Workout Ended',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Exercise: $exerciseName',
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$resultLabel: $resultValue',
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
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
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text(
                    'DONE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}