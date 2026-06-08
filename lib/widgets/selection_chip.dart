import 'package:flutter/material.dart';

class SelectionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;
  final double height;
  final double width;
  final String? subtitle;
  final double borderRadius;

  const SelectionChip({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    this.selectedColor = Colors.pinkAccent,
    required this.onTap,
    this.height = 40,
    this.width = 52,
    this.subtitle,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: subtitle == null
              ? Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight:
                        isSelected ? FontWeight.w900 : FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontWeight:
                            isSelected ? FontWeight.w900 : FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white70
                            : Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class SelectionChipRow extends StatelessWidget {
  final List<String> options;
  final String? selectedValue;
  final int? selectedIntValue;
  final ValueChanged<String>? onStringSelected;
  final ValueChanged<int>? onIntSelected;
  final Color accentColor;
  final double chipWidth;
  final double chipHeight;

  const SelectionChipRow({
    super.key,
    required this.options,
    this.selectedValue,
    this.selectedIntValue,
    this.onStringSelected,
    this.onIntSelected,
    this.accentColor = Colors.pinkAccent,
    this.chipWidth = 52,
    this.chipHeight = 40,
  });

  @override
  Widget build(BuildContext context) {
    final bool isExpanded = chipWidth == double.infinity;
    return Row(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final intValue = int.tryParse(option) ?? index;
        final isSelected = selectedValue != null
            ? selectedValue == option
            : selectedIntValue == intValue;

        final chip = Padding(
          padding: EdgeInsets.only(left: index > 0 ? 8 : 0),
          child: SelectionChip(
            label: option,
            isSelected: isSelected,
            selectedColor: accentColor,
            width: isExpanded ? double.infinity : chipWidth,
            height: chipHeight,
            onTap: () {
              onStringSelected?.call(option);
              onIntSelected?.call(intValue);
            },
          ),
        );

        return isExpanded ? Expanded(child: chip) : chip;
      }).toList(),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color chipColor;
  final VoidCallback onTap;
  final bool compact;

  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.chipColor,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(compact ? 12 : 15),
          border: Border.all(
            color: isSelected ? chipColor : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white54,
              size: compact ? 16 : 18,
            ),
            SizedBox(width: compact ? 6 : 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: compact ? 11 : 13,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
