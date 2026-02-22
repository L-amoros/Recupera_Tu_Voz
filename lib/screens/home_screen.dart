import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onEmpezar;
  const HomeScreen({super.key, required this.onEmpezar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo circle ───────────────────────────────
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent, width: 1.8),
                    color: AppColors.accent.withOpacity(0.06),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                const Text(
                  'Recupera tu voz',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Escribe y haz que todos te escuchen',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMid,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Waveform ──────────────────────────────────
                WaveBar(
                  color: AppColors.accent,
                  barCount: 30,
                  height: 44,
                ),
                const SizedBox(height: 44),

                // ── CTA ───────────────────────────────────────
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accent, width: 1.6),
                    foregroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 52, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onEmpezar,
                  child: const Text(
                    'EMPEZAR',
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
