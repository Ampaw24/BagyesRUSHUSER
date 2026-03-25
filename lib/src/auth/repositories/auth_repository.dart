import '../../../constant/typedef.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  ResultFuture<UserModel> signup(DataMap data);
  ResultFuture<DataMap> sendOtp(DataMap data);
  ResultFuture<UserModel> getUserDetails(String id);
}