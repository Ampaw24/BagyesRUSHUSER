import 'package:bagyesrushappusernew/features/consumer/profile/domain/entities/consumer_profile.dart';

/// Sealed states for the profile screen.
sealed class ProfileState {
  const ProfileState();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final ConsumerProfile profile;
  const ProfileLoaded({required this.profile});
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError({required this.message});
}

class ProfileUpdating extends ProfileState {
  final ConsumerProfile profile;
  const ProfileUpdating({required this.profile});
}
