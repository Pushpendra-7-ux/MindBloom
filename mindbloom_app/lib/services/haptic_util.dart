import 'package:flutter/services.dart';

/// Utility class for providing haptic feedback throughout the app.
///
/// Centralizes haptic feedback to ensure consistent tactile responses
/// across all interactive elements.
class HapticUtil {
  HapticUtil._();

  /// Light impact — for subtle interactions like toggling switches or
  /// selecting items in a list.
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact — for confirmations like completing a mood check-in
  /// or submitting a form.
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact — for significant actions like deleting data
  /// or triggering SOS.
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection click — a subtle tick for picker scrolls, slider changes,
  /// and tab switches.
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibrate — a standard vibration for error states or alerts.
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }
}
