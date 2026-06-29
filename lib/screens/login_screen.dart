import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../services/github_auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final GithubAuthService _githubAuthService = GithubAuthService();
  bool _isLoading = false;

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google Sign-In failed: $e"),
            backgroundColor: AppColors.neonPink,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleGitHubSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await _githubAuthService.signInWithGitHub();
      if (credential != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("GitHub Sign-In failed: $e"),
            backgroundColor: AppColors.neonPink,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _skipLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Screen is locked to Landscape
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17), // Rich dark background
      body: Stack(
        children: [
          // Background Tech Grid Lines or Ambient Glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan.withOpacity(0.02),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withOpacity(0.08),
                    blurRadius: 100,
                    spreadRadius: 50,
                  )
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonPurple.withOpacity(0.02),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonPurple.withOpacity(0.08),
                    blurRadius: 100,
                    spreadRadius: 50,
                  )
                ],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 460,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF121824).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonCyan.withOpacity(0.05),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // IDE Brand Logo/Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.code_rounded, color: AppColors.neonCyan, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          "GW APURV IDE",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Premium Agentic Mobile Coding Workspace",
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_isLoading) ...[
                      const SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.neonCyan,
                          ),
                        ),
                      ),
                    ] else ...[
                      // Google Login Button
                      SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          icon: const Icon(
                            Icons.g_mobiledata,
                            color: Colors.white,
                            size: 24,
                          ),
                          label: Text(
                            "Sign In with Google",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.08),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30, width: 0.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // GitHub Login Button
                      SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: _handleGitHubSignIn,
                          icon: const Icon(Icons.code, color: AppColors.neonCyan, size: 16),
                          label: Text(
                            "Sign In with GitHub",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonCyan.withOpacity(0.15),
                            foregroundColor: AppColors.neonCyan,
                            side: const BorderSide(color: AppColors.neonCyan, width: 0.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.1), height: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "OR",
                              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.1), height: 1)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Skip / Guest button
                      TextButton(
                        onPressed: _skipLogin,
                        child: Text(
                          "Skip Login / Use Offline Mode",
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 10,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
