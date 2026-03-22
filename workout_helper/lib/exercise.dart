enum ExerciseMode {
  timed,
  counted,
}

class Exercise {
  final String title;
  final String type; // workout or stretch
  final ExerciseMode mode;
  final String tutorialText;
  final String imagePath;
  final List<String> sports;
  final String badgeName;

  const Exercise({
    required this.title,
    required this.type,
    required this.mode,
    required this.tutorialText,
    required this.imagePath,
    required this.sports,
    required this.badgeName,
  });
}