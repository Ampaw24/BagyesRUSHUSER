import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/features/consumer/profile/data/repositories/profile_repository_impl.dart';
import 'package:bagyesrushappusernew/features/consumer/profile/domain/entities/consumer_profile.dart';
import 'package:bagyesrushappusernew/features/consumer/profile/domain/repositories/i_profile_repository.dart';
import 'package:bagyesrushappusernew/features/consumer/profile/presentation/states/profile_state.dart';

// ─── Repository provider ──────────────────────────────────────────────────

final profileRepositoryProvider = Provider<IProfileRepository>(
  (_) => ProfileRepositoryImpl(),
);

// ─── Profile ViewModel ────────────────────────────────────────────────────

class ProfileViewModel extends Notifier<ProfileState> {
  IProfileRepository get _repo => ref.read(profileRepositoryProvider);

  @override
  ProfileState build() {
    _loadProfile();
    return const ProfileLoading();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _repo.getProfile();
      state = ProfileLoaded(profile: profile);
    } catch (e) {
      state = ProfileError(message: e.toString());
    }
  }

  Future<void> updateProfile(ConsumerProfile updated) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    state = ProfileUpdating(profile: current.profile);
    try {
      final saved = await _repo.updateProfile(updated);
      state = ProfileLoaded(profile: saved);
    } catch (e) {
      state = ProfileLoaded(profile: current.profile);
    }
  }

  Future<void> logout() => _repo.logout();

  Future<void> deleteAccount() => _repo.deleteAccount();
}

final profileProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);
