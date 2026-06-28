import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({Key? key}) : super(key: key);

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _checkingSplash = true;

  @override
  void initState() {
    super.initState();
    _checkSplashState();
  }

  Future<void> _checkSplashState() async {
    const channel = MethodChannel('com.example.antigravity_ide/splash_state');
    try {
      final bool alreadyShown = await channel.invokeMethod('checkSplash');
      if (alreadyShown) {
        _navigateToHomeImmediate();
        return;
      }
      await channel.invokeMethod('setSplashShown');
    } catch (_) {}

    if (mounted) {
      setState(() {
        _checkingSplash = false;
      });
      _initializeVideo();
    }
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.asset('assets/video_project_2.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          _controller.play();
          _controller.setLooping(false);
        }
      });

    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHomeImmediate() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    if (!_checkingSplash) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSplash) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyan),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _initialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(color: Colors.cyan),
      ),
    );
  }
}
