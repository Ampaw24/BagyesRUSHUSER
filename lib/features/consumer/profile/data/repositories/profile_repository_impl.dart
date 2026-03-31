import 'package:bagyesrushappusernew/features/consumer/profile/domain/entities/consumer_profile.dart';
import 'package:bagyesrushappusernew/features/consumer/profile/domain/repositories/i_profile_repository.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  
  ConsumerProfile _profile = const ConsumerProfile(
    id: 'u1',
    fullName: 'Ampaw Justice',
    email: 'john@bagyesrush.com',
    isVerified: true,
    orderCount: 14,
    reviewCount: 6,
    walletBalance: 45,
  );

  @override
  Future<ConsumerProfile> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _profile;
  }

  @override
  Future<ConsumerProfile> updateProfile(ConsumerProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _profile = profile;
    return _profile;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> deleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
