import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class GameHelpModal {
  static void show({
    required BuildContext context,
    required List<Widget> sections,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text('REGLAS', style: TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3,
                    )),
                  ),
                  const SizedBox(height: 24),
                  ...sections,
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 2)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.modeATiempo,
              shape: BoxShape.circle,
            ),
            child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, height: 1.4)),
          ),
        ],
      ),
    );
  }

  static Widget bullet(String? label, String text, Color color, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          if (label != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
            )
          else
            Icon(Icons.arrow_right, color: color, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                children: [
                  TextSpan(text: '$text ', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget text(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 36),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
    );
  }

  static Widget helpButton(VoidCallback onPressed) {
    return IconButton(
      icon: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38),
        ),
        child: const Center(
          child: Text('?', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
      onPressed: onPressed,
    );
  }
}

class HelpSection {
  final String number;
  final String text;
  final List<HelpBullet>? bullets;
  final String? extraText;

  const HelpSection({
    required this.number,
    required this.text,
    this.bullets,
    this.extraText,
  });
}

class HelpBullet {
  final String? label;
  final String text;
  final String description;
  final Color color;

  const HelpBullet({
    this.label,
    required this.text,
    required this.description,
    this.color = Colors.white,
  });
}
