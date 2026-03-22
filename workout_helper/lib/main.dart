import 'package:flutter/material.dart';

import 'package:workout_helper/camera_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _App());
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraScreen(),
    );
  }
}