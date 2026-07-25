import 'package:flutter/material.dart';
import 'package:pareja/core/utils/age_calculator.dart';

/// Modal that asks the user for their date of birth and returns `true`
/// (via `Navigator.pop(context, true)`) when they are 18 or older.
///
/// On any other outcome (cancel, user is under 18) the modal pops with
/// `false` or `null`.
///
/// Pure UI: it does NOT persist anything. The caller (typically
/// `SettingsScreen`) is responsible for calling
/// `SettingsProvider.setAgeVerified(true)` after a successful result.
class AgeGateModal extends StatefulWidget {
  const AgeGateModal({super.key});

  /// Convenience helper that shows the modal and resolves to a bool
  /// indicating whether the user passed the age check.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AgeGateModal(),
    );
    return result ?? false;
  }

  @override
  State<AgeGateModal> createState() => _AgeGateModalState();
}

class _AgeGateModalState extends State<AgeGateModal> {
  DateTime? _selectedDate;
  String? _errorMessage;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 120, 1, 1),
      lastDate: now,
      helpText: 'Selecciona tu fecha de nacimiento',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _errorMessage = null;
      });
    }
  }

  void _verify() {
    final dob = _selectedDate;
    if (dob == null) {
      setState(() => _errorMessage = 'Por favor, selecciona una fecha.');
      return;
    }
    if (isAdult(dob)) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage =
          'Lo sentimos, debes ser mayor de 18 años para acceder a este contenido.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Row(
        children: [
          Icon(Icons.cake_outlined, color: Colors.pinkAccent),
          SizedBox(width: 8),
          Text(
            'Verificación de edad',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Para activar el contenido +18, confirma tu fecha de nacimiento.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              _selectedDate == null
                  ? 'Seleccionar fecha'
                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: const TextStyle(color: Colors.white),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: _verify,
          child: const Text(
            'VERIFICAR',
            style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
