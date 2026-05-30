import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class HapticsService {
  HapticsService._();

  static void light() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.lightImpact();
    }
  }

  static void medium() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.mediumImpact();
    }
  }

  static void heavy() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.heavyImpact();
    }
  }

  static void vibrate() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.vibrate();
    }
  }

  static void selection() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.selectionClick();
    }
  }
}
