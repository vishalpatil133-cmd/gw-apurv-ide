import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/ide_provider.dart';
import '../../theme/app_theme.dart';

class GithubLoginDialog extends StatefulWidget {
  const GithubLoginDialog({Key? key}) : super(key: key);

  @override
  State<GithubLoginDialog> createState() => _GithubLoginDialogState();
}

class _GithubLoginDialogState extends State<GithubLoginDialog> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _triggerLogin(IdeProvider provider) async {
    final token = _passController.text.trim();
    
    setState(() {
      _loading = true;
    });

    bool success = false;
    if (token.isNotEmpty) {
      // Real authentication using Personal Access Token (PAT)
      success = await provider.loginWithToken(token);
    } else {
      // Browser authentication via OAuth flow
      success = await provider.loginWithOAuth();
    }
    
    if (mounted) {
      setState(() {
        _loading = false;
      });
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(token.isNotEmpty 
                ? "Logged in successfully with Personal Access Token!" 
                : "Logged in successfully via GitHub OAuth!"),
            backgroundColor: AppColors.neonGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Authentication failed. Please verify your token or try OAuth."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IdeProvider>(context);

    return Dialog(
      backgroundColor: const Color(0xFF0D1117), // GitHub's official dark mode background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFF30363D)), // GitHub border color
      ),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        child: _loading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    "Authorizing with GW APURV IDE...",
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Redirecting callback scheme...",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  )
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // GitHub Logo Mock
                  const Center(
                    child: Icon(Icons.hub, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      "Sign in to GitHub",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      "to continue to GW APURV IDE",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Username field
                  Text(
                    "GitHub Username (optional)",
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 32,
                    child: TextField(
                      controller: _userController,
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color(0xFF090D13),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF30363D)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF58A6FF)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Token field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Personal Access Token (PAT)",
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () {
                          // OAuth fallback directly via trigger
                          _passController.clear();
                          _triggerLogin(provider);
                        },
                        child: Text(
                          "Sign in with Browser instead",
                          style: GoogleFonts.outfit(color: const Color(0xFF58A6FF), fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 32,
                    child: TextField(
                      controller: _passController,
                      obscureText: true,
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color(0xFF090D13),
                        hintText: "ghp_...",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF30363D)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF58A6FF)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Note: Token requires 'repo' and 'workflow' permissions to perform cloud builds.",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 8),
                  ),
                  const SizedBox(height: 16),

                  // Sign In button
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => _triggerLogin(provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF238636), // GitHub Green
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        elevation: 0,
                      ),
                      child: Text(
                        "Verify & Link PAT Account",
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // OAuth button
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () {
                        _passController.clear();
                        _triggerLogin(provider);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF30363D)),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: Text(
                        "Sign in with Browser (OAuth)",
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // OAuth info footer
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF30363D)),
                    ),
                    child: Text(
                      "GW APURV IDE will request read access to repositories and workflows.",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
