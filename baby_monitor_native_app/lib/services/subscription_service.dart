import 'package:shared_preferences/shared_preferences.dart';

// Demo mode: build with --dart-define=DEMO_MODE=true to unlock all features
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);

class SubscriptionService {
  static const String _premiumKey = 'is_premium';

  /// Returns true if the user has an active Premium subscription,
  /// or if the app was built in Demo mode.
  static Future<bool> isPremium() async {
    if (kDemoMode) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  /// Activates Premium locally (simulated until real billing is integrated).
  static Future<void> activatePremium() async {
    if (kDemoMode) return; // No-op in demo mode — always premium
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, true);
  }

  /// Deactivates Premium. Useful for testing.
  static Future<void> deactivatePremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, false);
  }

  /// Returns a user-facing message explaining why a feature requires Premium.
  static String upgradeRequiredMessage(String featureName) {
    return '$featureName requiere el plan Premium. '
        '¡Actualiza para disfrutar de todas las funciones!';
  }
}
