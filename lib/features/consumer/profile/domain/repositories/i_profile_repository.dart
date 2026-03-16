import 'package:bagyesrushappusernew/features/consumer/profile/domain/entities/consumer_profile.dart';

abstract interface class IProfileRepository {
  Future<ConsumerProfile> getProfile();
  Future<ConsumerProfile> updateProfile(ConsumerProfile profile);
  Future<void> logout();
  Future<void> deleteAccount();
}
