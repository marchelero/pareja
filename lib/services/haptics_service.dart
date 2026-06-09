import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class HapticsService {
  HapticsService._();

  static bool _globalEnabled = true;

  static bool get isEnabled => _globalEnabled;

  static void setEnabled(bool value) {
    _globalEnabled = value;
  }

  static void light() {
    if (!_globalEnabled) return;
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.lightImpact();
    }
  }

  static void medium() {
    if (!_globalEnabled) return;
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.mediumImpact();
    }
  }

  static void heavy() {
    if (!_globalEnabled) return;
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.heavyImpact();
    }
  }

  static void vibrate() {
    if (!_globalEnabled) return;
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.vibrate();
    }
  }

  static void selection() {
    if (!_globalEnabled) return;
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.selectionClick();
    }
  }
}
