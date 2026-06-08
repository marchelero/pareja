import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color? iconColor;
  final double iconSize;
  final double spacing;

  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.iconColor,
    this.iconSize = 24,
    this.spacing = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor ?? Colors.white70, size: iconSize),
            SizedBox(width: spacing),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Flexible(child: child),
      ],
    );
  }
}

class SettingDivider extends StatelessWidget {
  const SettingDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(color: Colors.white12, height: 1),
    );
  }
}

class SettingDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  const SettingDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
      dropdownColor: Colors.black87,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      underline: const SizedBox(),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
      items: items.map((v) {
        return DropdownMenuItem<T>(
          value: v,
          child: Text(labelBuilder(v)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class SettingSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const SettingSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.primaryNeon;
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: color,
      activeTrackColor: color.withValues(alpha: 0.5),
    );
  }
}
