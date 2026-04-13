import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/features/consumer/profile/domain/entities/consumer_profile.dart';
import 'package:bagyesrushappusernew/features/consumer/profile/domain/repositories/i_profile_repository.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  ProfileRepositoryImpl({required CurrentUserProvider currentUserProvider})
    : _currentUserProvider = currentUserProvider;

  final CurrentUserProvider _currentUserProvider;

  @override
  Future<ConsumerProfile> getProfile() async {
    final user = _currentUserProvider.user;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final firstName = user.profile?.firstName ?? '';
    final lastName = user.profile?.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();

    return ConsumerProfile(
      id: user.id,
      fullName: fullName.isNotEmpty ? fullName : user.email,
      email: user.email,
      avatarUrl: user.profile?.profilePictureUrl,
      isVerified: user.phoneVerified,
      orderCount: 0,
      reviewCount: 0,
      walletBalance: 0,
    );
  }

  @override
  Future<ConsumerProfile> updateProfile(ConsumerProfile profile) async {
    // Local optimistic update — wire to a real API call when the endpoint exists.
    return profile;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> deleteAccount() async {}
}
