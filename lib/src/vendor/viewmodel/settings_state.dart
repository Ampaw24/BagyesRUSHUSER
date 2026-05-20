import 'package:equatable/equatable.dart';
import '../../../core/errors/failure.dart';
import '../model/vendor_profile.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

final class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

final class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

final class SettingsSaving extends SettingsState {
  const SettingsSaving();
}

final class SettingsLoaded extends SettingsState {
  const SettingsLoaded(this.profile);

  final VendorProfile profile;

  @override
  List<Object?> get props => [profile];
}

final class SettingsError extends SettingsState {
  const SettingsError({required this.message, required this.title});

  SettingsError.fromFailure(Failure failure)
      : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object?> get props => [message, title];
}
