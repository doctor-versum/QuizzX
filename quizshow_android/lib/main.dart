import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_menu.dart';

void main() {
  // Initialize Flutter binding first
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations to landscape only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Hide system UI for full screen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  
  // Keep screen awake
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Show',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LandscapeOrientation(child: MainMenu()),
      builder: (context, child) {
        // Keep screen awake
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        return child!;
      },
    );
  }
}

// Landscape orientation wrapper
class LandscapeOrientation extends StatelessWidget {
  final Widget child;

  const LandscapeOrientation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          // Force landscape orientation
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }
        return child;
      },
    );
  }
}
