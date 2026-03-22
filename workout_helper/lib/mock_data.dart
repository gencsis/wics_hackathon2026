import 'exercise.dart';

class MockData {
  static const String userName = 'Michael';
  static const int age = 20;
  static const String gender = 'Male';

  static final List<String> recentActivities = [
    'Squats',
    'Plank',
    'Toe Stretch',
    'Arm Circle',
  ];

  static final List<String> earnedBadges = [
    'Squat Starter',
    'Plank Pro',
    'Toe Stretch',
  ];

  static final List<String> sports = [
    'All',
    'Soccer',
    'Basketball',
    'Baseball',
    'Running',
    'Other',
  ];

  static final List<Exercise> exercises = [
    Exercise(
      title: 'Squats',
      type: 'workout',
      mode: ExerciseMode.counted,
      tutorialText: 'Keep your chest up, knees aligned, and hips back.',
      imagePath: 'assets/images/squat_cat.png',
      gifPath: 'assets/images/squat_cat.gif',
      sports: ['Soccer', 'Basketball', 'Running'],
      badgeName: 'Squat Starter',
    ),
    Exercise(
      title: 'Plank',
      type: 'workout',
      mode: ExerciseMode.timed,
      tutorialText: 'Keep your back straight and core engaged.',
      imagePath: 'assets/images/plank_cat.png',
      gifPath: 'assets/images/plank_cat.gif',
      sports: ['Soccer', 'Running'],
      badgeName: 'Plank Pro',
    ),
    Exercise(
      title: 'Toe Stretch',
      type: 'stretch',
      mode: ExerciseMode.counted,
      tutorialText: 'Reach for your toes slowly without locking your knees.',
      imagePath: '',
      gifPath: '',
      sports: ['Running', 'Other'],
      badgeName: 'Toe Stretch',
    ),
    Exercise(
      title: 'Arm Circle',
      type: 'stretch',
      mode: ExerciseMode.counted,
      tutorialText: 'Keep your arms extended and make controlled circles.',
      imagePath: '',
      gifPath: '',
      sports: ['Basketball', 'Other'],
      badgeName: 'Arm Circle',
    ),
    Exercise(
      title: 'Lunges',
      type: 'workout',
      mode: ExerciseMode.counted,
      tutorialText: 'Step forward, keep balance, and lower carefully.',
      imagePath: '',
      gifPath: '',
      sports: ['Soccer', 'Baseball'],
      badgeName: 'Lunge Legend',
    ),
    Exercise(
      title: 'Jumps',
      type: 'workout',
      mode: ExerciseMode.counted,
      tutorialText: 'Land softly and keep your core engaged.',
      imagePath: '',
      gifPath: '',
      sports: ['Basketball'],
      badgeName: 'Jump Jet',
    ),
    Exercise(
      title: 'Shoulder Stretch',
      type: 'stretch',
      mode: ExerciseMode.counted,
      tutorialText: 'Stretch gently and avoid shrugging your shoulders.',
      imagePath: '',
      gifPath: '',
      sports: ['Baseball'],
      badgeName: 'Shoulder Saver',
    ),
    Exercise(
      title: 'Cobra Stretch',
      type: 'stretch',
      mode: ExerciseMode.counted,
      tutorialText: 'Lie on your stomach, place your hands under your shoulders, and gently push your chest upward while keeping your hips on the ground.',
      imagePath: 'assets/images/cobra_stretch.png',
      gifPath: 'assets/images/cobra_stretch.gif',
      sports: ['Running', 'Other'],
      badgeName: 'Cobra Flex',
    ),
  ];
}