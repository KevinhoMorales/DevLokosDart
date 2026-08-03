import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia del onboarding de primera apertura.
class OnboardingService {
  static const String _completedKey = 'onboarding_completed';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }
}
