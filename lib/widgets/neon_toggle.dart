import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class NeonToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final Color? activeColor;

  const NeonToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.icon,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.primaryNeon;
    return Row(
      children: [
        Icon(icon, color: value ? color : Colors.white54, size: 24),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: value ? color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: value ? color.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: value ? color.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
