import '../models/app_role.dart';
import '../../../core/services/secure_storage_service.dart';

/// Service responsible for managing onboarding state and user role persistence.
///
/// This service handles:
/// - First launch detection
/// - Role selection persistence
/// - Onboarding completion tracking
class OnboardingService {
  final SecureStorageService _storage;

  static const String _keyFirstLaunch = 'isFirstLaunch';
  static const String _keySelectedRole = 'selectedRole';
  static const String _keyOnboardingCompleted = 'onboardingCompleted';

  OnboardingService(this._storage);

  /// Check if this is the first time the app is launched
  Future<bool> isFirstLaunch() async {
    final value = await _storage.read(_keyFirstLaunch);
    return value == null; // If null, it's first launch
  }

  /// Mark that the app has been launched before
  Future<void> markAppLaunched() async {
    await _storage.write(_keyFirstLaunch, 'false');
  }

  /// Check if onboarding has been completed
  Future<bool> isOnboardingCompleted() async {
    final value = await _storage.read(_keyOnboardingCompleted);
    return value == 'true';
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    await _storage.write(_keyOnboardingCompleted, 'true');
  }

  /// Save the selected user role
  Future<void> saveSelectedRole(AppRole role) async {
    await _storage.write(_keySelectedRole, role.value);
  }

  /// Get the previously selected role
  Future<AppRole?> getSelectedRole() async {
    final value = await _storage.read(_keySelectedRole);
    return AppRole.fromString(value);
  }

  /// Clear all onboarding data (useful for testing or logout)
  Future<void> clearOnboardingData() async {
    await _storage.delete(_keyFirstLaunch);
    await _storage.delete(_keySelectedRole);
    await _storage.delete(_keyOnboardingCompleted);
  }

  /// Reset to first launch state (for testing)
  Future<void> resetToFirstLaunch() async {
    await clearOnboardingData();
  }
}
