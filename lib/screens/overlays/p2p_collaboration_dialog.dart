import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/ide_provider.dart';
import '../../theme/app_theme.dart';
import 'p2p_remote_controller_screen.dart';

class P2PCollaborationDialog extends StatefulWidget {
  const P2PCollaborationDialog({Key? key}) : super(key: key);

  @override
  State<P2PCollaborationDialog> createState() => _P2PCollaborationDialogState();
}

class _P2PCollaborationDialogState extends State<P2PCollaborationDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isConnecting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IdeProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Dialog(
        backgroundColor: provider.cardBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: provider.borderColor, width: 1.5),
        ),
        child: Container(
          width: 380,
          height: 420,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "P2P REALTIME SYNC",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: provider.neonCyanColor,
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                  )
                ],
              ),
              TabBar(
                labelColor: provider.neonCyanColor,
                unselectedLabelColor: provider.textSecondaryColor,
                indicatorColor: provider.neonCyanColor,
                tabs: const [
                  Tab(text: "HOST PROJECT"),
                  Tab(text: "JOIN PROJECT"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Host Session UI
                    _buildHostTab(provider),
                    // Tab 2: Join Session UI
                    _buildJoinTab(provider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHostTab(IdeProvider provider) {
    if (provider.isP2PHosting) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: QrImageView(
              data: provider.p2pPairingCode,
              version: QrVersions.auto,
              size: 160.0,
              gapless: false,
              errorStateBuilder: (cxt, err) {
                return const Center(child: Text("QR Generation Error"));
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Pairing Code: ${provider.p2pPairingCode}",
            style: GoogleFonts.jetBrainsMono(
              color: provider.neonCyanColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await provider.stopP2PSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: provider.neonPinkColor,
              side: BorderSide(color: provider.neonPinkColor),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("STOP SESSION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.wifi_tethering, size: 48, color: provider.textSecondaryColor),
        const SizedBox(height: 16),
        Text(
          "Host the active project dynamically.\nPhone B can scan the QR code to edit together.",
          textAlign: TextAlign.center,
          style: TextStyle(color: provider.textSecondaryColor, fontSize: 11),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            await provider.startP2PHosting();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: provider.neonCyanColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: Text(
            "START HOSTING",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        )
      ],
    );
  }

  Widget _buildJoinTab(IdeProvider provider) {
    if (provider.isP2PConnected) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 48, color: AppColors.neonGreen),
          const SizedBox(height: 16),
          Text(
            "Successfully connected to host session!",
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await provider.stopP2PSession();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: provider.neonPinkColor,
                  side: BorderSide(color: provider.neonPinkColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text("DISCONNECT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const P2PRemoteControllerScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.neonCyanColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text("USE AS TOUCHPAD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              style: GoogleFonts.jetBrainsMono(color: provider.neonCyanColor, fontSize: 11),
              decoration: const InputDecoration(
                labelText: "Enter Host Pairing Code",
                helperText: "e.g., 192.168.1.100:8080",
                prefixIcon: Icon(Icons.wifi, color: AppColors.neonPurple),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Simulate camera QR code scanning fallback (auto-fill debug code if host exists)
                    _codeController.text = "127.0.0.1:8080";
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Simulated QR Scan: 127.0.0.1:8080 auto-filled!")),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: provider.neonCyanColor,
                    side: BorderSide(color: provider.borderColor),
                  ),
                  icon: const Icon(Icons.qr_code_scanner, size: 14),
                  label: const Text("SIMULATE SCAN", style: TextStyle(fontSize: 10)),
                ),
                ElevatedButton(
                  onPressed: _isConnecting
                      ? null
                      : () async {
                          setState(() {
                            _isConnecting = true;
                          });
                          try {
                            await provider.joinP2PSession(_codeController.text);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Connection failed: $e")),
                            );
                          } finally {
                            setState(() {
                              _isConnecting = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.neonCyanColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    _isConnecting ? "CONNECTING..." : "CONNECT",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
