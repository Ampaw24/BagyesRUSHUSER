import '../../../../constant/image_constants.dart';

/// Defines the user roles available in the application.
///
/// This enum is designed to be scalable for future role additions
/// (e.g., Driver, Admin, Dispatcher).
enum AppRole {
  vendor('vendor', 'Vendor', 'Grow your food business'),
  user('user', 'User', 'Order meals fast');

  const AppRole(this.value, this.displayName, this.tagline);

  final String value;
  final String displayName;
  final String tagline;

  /// Convert string to AppRole enum
  static AppRole? fromString(String? value) {
    if (value == null) return null;
    return AppRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => AppRole.user,
    );
  }

  /// Get all available roles as a list for dynamic rendering
  static List<AppRole> get availableRoles => AppRole.values;
}

/// Model representing a role option with all display information
class RoleOption {
  final AppRole role;
  final String title;
  final String description;
  final String ctaText;
  final String iconAsset;

  const RoleOption({
    required this.role,
    required this.title,
    required this.description,
    required this.ctaText,
    required this.iconAsset,
  });

  /// Predefined role options for the onboarding screen
  static List<RoleOption> get options => [
    RoleOption(
      role: AppRole.vendor,
      title: 'Vendor',
      description:
          'Register your restaurant or food business and start receiving orders.',
      ctaText: 'Continue as Vendor',
      iconAsset: AssetImages.vendorIcon,
    ),
    RoleOption(
      role: AppRole.user,
      title: 'User',
      description: 'Order food and get it delivered quickly to your location.',
      ctaText: 'Continue as User',
      iconAsset: AssetImages.userIcon,
    ),
  ];
}
