import 'package:flutter/foundation.dart';
import '../../../core/router/app_routes.dart';
import '../models/app_role.dart';
import '../services/onboarding_service.dart';

/// ViewModel state for the onboarding flow
class OnboardingState {
  final AppRole? selectedRole;
  final bool isLoading;
  final String? errorMessage;

  const OnboardingState({
    this.selectedRole,
    this.isLoading = false,
    this.errorMessage,
  });

  OnboardingState copyWith({
    AppRole? selectedRole,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OnboardingState(
      selectedRole: selectedRole ?? this.selectedRole,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// ViewModel for managing onboarding flow logic
///
/// Responsibilities:
/// - Track selected role
/// - Persist role selection
/// - Manage onboarding completion
/// - Provide navigation signals
class OnboardingViewModel extends ChangeNotifier {
  final OnboardingService _onboardingService;

  OnboardingState _state = const OnboardingState();
  OnboardingState get state => _state;

  OnboardingViewModel(this._onboardingService);

  /// Select a role (updates UI state only)
  void selectRole(AppRole role) {
    _state = _state.copyWith(selectedRole: role);
    notifyListeners();
  }

  /// Clear role selection
  void clearSelection() {
    _state = _state.copyWith(selectedRole: null);
    notifyListeners();
  }

  /// Complete onboarding with the selected role
  ///
  /// This method:
  /// 1. Validates role selection
  /// 2. Persists the role
  /// 3. Marks onboarding as completed
  /// 4. Returns true if successful, false otherwise
  Future<bool> completeOnboarding() async {
    if (_state.selectedRole == null) {
      _state = _state.copyWith(
        errorMessage: 'Please select a role to continue',
      );
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      // Save selected role
      await _onboardingService.saveSelectedRole(_state.selectedRole!);

      // Mark onboarding as completed
      await _onboardingService.completeOnboarding();

      // Mark app as launched
      await _onboardingService.markAppLaunched();

      _state = _state.copyWith(isLoading: false);
      notifyListeners();

      return true;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save your selection. Please try again.',
      );
      notifyListeners();
      return false;
    }
  }

  /// Get the navigation destination based on selected role
  ///
  /// Returns the route path for the selected role's auth flow
  String getNavigationDestination() {
    switch (_state.selectedRole) {
      case AppRole.vendor:
        return AppRoutes.vendorRegistration;
      case AppRole.user:
        return AppRoutes.signup;
      default:
        return AppRoutes.login;
    }
  }

  /// Check if onboarding should be shown
  Future<bool> shouldShowOnboarding() async {
    final isFirstLaunch = await _onboardingService.isFirstLaunch();
    final isCompleted = await _onboardingService.isOnboardingCompleted();
    return isFirstLaunch || !isCompleted;
  }

  /// Get previously selected role (if any)
  Future<AppRole?> getPreviousRole() async {
    return await _onboardingService.getSelectedRole();
  }
}
