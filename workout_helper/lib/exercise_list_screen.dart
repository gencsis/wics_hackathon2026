import 'package:flutter/material.dart';
import 'mock_data.dart';
import 'exercise.dart';
import 'app_colors.dart';
import 'exercise_detail_screen.dart';

class ExerciseListScreen extends StatefulWidget {
  final String type; // 'stretch' or 'workout'

  const ExerciseListScreen({super.key, required this.type});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  String selectedSport = 'All';
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    final exercises = MockData.exercises.where((exercise) {
      final matchesType = exercise.type == widget.type;
      final matchesSport =
          selectedSport == 'All' || exercise.sports.contains(selectedSport);
      final matchesSearch =
          exercise.title.toLowerCase().contains(searchText.toLowerCase());

      return matchesType && matchesSport && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == 'stretch' ? 'Stretches' : 'Workouts'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Sport filter
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedSport,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primaryDark,
                  ),
                  items: MockData.sports.map((sport) {
                    return DropdownMenuItem<String>(
                      value: sport,
                      child: Text(
                        sport,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedSport = value;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Exercise cards
            Expanded(
              child: exercises.isEmpty
                  ? const Center(
                      child: Text(
                        'No exercises found',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textLight,
                        ),
                      ),
                    )
                  : GridView.builder(
                      itemCount: exercises.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.88,
                      ),
                      itemBuilder: (context, index) {
                        final Exercise exercise = exercises[index];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ExerciseDetailScreen(exercise: exercise),
                              ),
                            );
                          },
                          child: Container(
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
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.sticker,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 3,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      right: 12,
                                      child: Text(
                                        exercise.title.toUpperCase(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: exercise.imagePath.isNotEmpty
                                            ? Image.asset(
                                                exercise.imagePath,
                                                fit: BoxFit.contain,
                                              )
                                            : Icon(
                                                widget.type == 'stretch'
                                                    ? Icons.accessibility_new
                                                    : Icons.fitness_center,
                                                size: 54,
                                                color: AppColors.primaryDark,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}