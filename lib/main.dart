import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/ide_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/video_splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using native config bindings
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // Enable Full Screen Immersive Mode
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );
  
  // Hard lock the IDE to Landscape orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IdeProvider()),
      ],
      child: const AntigravityApp(),
    ),
  );
}

class AntigravityApp extends StatelessWidget {
  const AntigravityApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IdeProvider>(context);
    return MaterialApp(
      title: 'GW APURV IDE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: provider.lightThemeActive ? ThemeMode.light : ThemeMode.dark,
      home: const VideoSplashScreen(),
    );
  }
}
