import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/ide_provider.dart';
import '../../theme/app_theme.dart';

class PlanningOverlay extends StatelessWidget {
  const PlanningOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IdeProvider>(context);
    final agent = provider.planningAgent;

    if (agent == null) return const SizedBox.shrink();

    return Material(
      color: Colors.black.withOpacity(0.6), // Dimmed viewport overlay
      child: Center(
        child: Container(
          width: 600,
          height: 320,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.neonPurple, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonPurple.withOpacity(0.15),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF161619),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, color: AppColors.neonPurple, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "AI AGENT PLANNING MODE: ${agent.name.toUpperCase()}",
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Content Area (Two Columns: Text Outline & Logic Flow Chart)
              Expanded(
                child: Row(
                  children: [
                    // Column 1: Markdown proposal text
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: const BoxDecoration(
                          border: Border(right: BorderSide(color: AppColors.border)),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "PROPOSED SPECIFICATIONS",
                                style: GoogleFonts.outfit(
                                  color: AppColors.neonCyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                agent.planningLog,
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppColors.textPrimary,
                                  fontSize: 9.5,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Column 2: Logic Flow representation
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.black.withOpacity(0.15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "EXECUTION PIPELINE",
                              style: GoogleFonts.outfit(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildPipelineStep("Read: ${agent.targetFile}", isFirst: true),
                            _buildArrow(),
                            _buildPipelineStep("Process: AST Optimizations"),
                            _buildArrow(),
                            _buildPipelineStep("Write: Code Revisions"),
                            _buildArrow(),
                            _buildPipelineStep("Verify: Compile & Unit Tests", isLast: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions Footer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF161619),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: provider.cancelAgentPlan,
                      child: const Text(
                        "REJECT PLAN",
                        style: TextStyle(color: AppColors.neonPink, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: provider.approveAgentPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text(
                        "APPROVE PLAN & EXECUTE",
                        style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPipelineStep(String label, {bool isFirst = false, bool isLast = false}) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isFirst
            ? Colors.cyan.withOpacity(0.1)
            : isLast
                ? Colors.green.withOpacity(0.1)
                : AppColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isFirst
              ? AppColors.neonCyan
              : isLast
                  ? AppColors.neonGreen
                  : AppColors.border,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            color: isFirst
                ? AppColors.neonCyan
                : isLast
                    ? AppColors.neonGreen
                    : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildArrow() {
    return const Icon(
      Icons.keyboard_arrow_down,
      size: 10,
      color: AppColors.textSecondary,
    );
  }
}
