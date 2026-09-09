import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/src/vendor/model/vendor_profile.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.phoneVerified,
    required this.profile,
  });

  final String id;
  final String email;
  final String phone;
  final String role;
  final String status;
  final bool phoneVerified;
  final dynamic profile;

  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? role,
    String? status,
    bool? phoneVerified,
    dynamic profile,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      profile: profile ?? this.profile,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // 1. Resolve user data map (if nested inside 'user' key)
    final userMap =
        (json.containsKey('user') && json['user'] is Map<String, dynamic>)
            ? json['user'] as Map<String, dynamic>
            : json;

    final role = JsonUtils.asString(userMap['role'] ?? json['role']);
    final email = JsonUtils.asString(userMap['email'] ?? json['email']);
    final phone = JsonUtils.asString(userMap['phone'] ?? json['phone']);
    final id = JsonUtils.asString(
      userMap['_id'] ??
          userMap['id'] ??
          userMap['user_id'] ??
          json['_id'] ??
          json['id'],
    );
    final status = JsonUtils.asString(userMap['status'] ?? json['status']);
    final phoneVerified = JsonUtils.asBool(
      userMap['phone_verified'] ?? json['phone_verified'],
    );

    // 2. Resolve profile data map (if nested inside 'profile' key anywhere)
    final rawProfile = json['profile'] ?? userMap['profile'];

    dynamic parsedProfile;
    if (rawProfile != null && rawProfile is Map<String, dynamic>) {
      parsedProfile = (role == 'vendor')
          ? VendorProfile.fromJson(rawProfile).copyWith(
              email: email.isNotEmpty ? email : null,
              phone: phone.isNotEmpty ? phone : null,
            )
          : CustomerProfile.fromJson(rawProfile);
    } else if (json.containsKey('first_name') ||
        json.containsKey('profile_picture_url') ||
        json.containsKey('business_name')) {
      // The json map itself IS a profile document!
      parsedProfile = (role == 'vendor' || json.containsKey('business_name'))
          ? VendorProfile.fromJson(json).copyWith(
              email: email.isNotEmpty ? email : null,
              phone: phone.isNotEmpty ? phone : null,
            )
          : CustomerProfile.fromJson(json);
    }

    return User(
      id: id,
      email: email,
      phone: phone,
      role: role,
      status: status,
      phoneVerified: phoneVerified,
      profile: parsedProfile,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "email": email,
        "phone": phone,
        "role": role,
        "status": status,
        "phone_verified": phoneVerified,
        "profile": profile?.toJson(),
      };

  @override
  String toString() {
    return "$id, $email, $phone, $role, $status, $phoneVerified, $profile, ";
  }

  @override
  List<Object?> get props => [
        id,
        email,
        phone,
        role,
        status,
        phoneVerified,
        profile,
      ];
}

class CustomerProfile extends Equatable {
  const CustomerProfile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.profilePictureUrl,
    required this.referralCode,
    required this.referralCount,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String address;
  final String? profilePictureUrl;
  final String referralCode;
  final num referralCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final num v;

  CustomerProfile copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? address,
    String? profilePictureUrl,
    String? referralCode,
    num? referralCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    num? v,
  }) {
    return CustomerProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      address: address ?? this.address,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      referralCode: referralCode ?? this.referralCode,
      referralCount: referralCount ?? this.referralCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: JsonUtils.asString(json["_id"] ?? json["id"]),
      userId: JsonUtils.asString(json["user_id"]),
      firstName: JsonUtils.asString(json["first_name"]),
      lastName: JsonUtils.asString(json["last_name"]),
      address: JsonUtils.asString(json["address"]),
      profilePictureUrl: JsonUtils.asStringOrNull(json["profile_picture_url"]),
      referralCode: JsonUtils.asString(json["referral_code"]),
      referralCount: JsonUtils.asInt(json["referral_count"]),
      createdAt: JsonUtils.asDateTime(json["created_at"]),
      updatedAt: JsonUtils.asDateTime(json["updated_at"]),
      v: JsonUtils.asInt(json["__v"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "user_id": userId,
        "first_name": firstName,
        "last_name": lastName,
        "address": address,
        "profile_picture_url": profilePictureUrl,
        "referral_code": referralCode,
        "referral_count": referralCount,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "__v": v,
      };

  @override
  String toString() {
    return "$id, $userId, $firstName, $lastName, $address, $profilePictureUrl, $referralCode, $referralCount, $createdAt, $updatedAt, $v, ";
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        firstName,
        lastName,
        address,
        profilePictureUrl,
        referralCode,
        referralCount,
        createdAt,
        updatedAt,
        v,
      ];
}

