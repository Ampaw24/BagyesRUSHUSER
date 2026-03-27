import 'package:equatable/equatable.dart';

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
    final Profile? profile;

    User copyWith({
        String? id,
        String? email,
        String? phone,
        String? role,
        String? status,
        bool? phoneVerified,
        Profile? profile,
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

    factory User.fromJson(Map<String, dynamic> json){ 
        return User(
            id: json["id"] ?? "",
            email: json["email"] ?? "",
            phone: json["phone"] ?? "",
            role: json["role"] ?? "",
            status: json["status"] ?? "",
            phoneVerified: json["phone_verified"] ?? false,
            profile: json["profile"] == null ? null : Profile.fromJson(json["profile"]),
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
    String toString(){
        return "$id, $email, $phone, $role, $status, $phoneVerified, $profile, ";
    }

    @override
    List<Object?> get props => [
    id, email, phone, role, status, phoneVerified, profile, ];
}

class Profile extends Equatable {
   const Profile({
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
    final dynamic profilePictureUrl;
    final String referralCode;
    final num referralCount;
    final DateTime? createdAt;
    final DateTime? updatedAt;
    final num v;

    Profile copyWith({
        String? id,
        String? userId,
        String? firstName,
        String? lastName,
        String? address,
        dynamic profilePictureUrl,
        String? referralCode,
        num? referralCount,
        DateTime? createdAt,
        DateTime? updatedAt,
        num? v,
    }) {
        return Profile(
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

    factory Profile.fromJson(Map<String, dynamic> json){ 
        return Profile(
            id: json["_id"] ?? "",
            userId: json["user_id"] ?? "",
            firstName: json["first_name"] ?? "",
            lastName: json["last_name"] ?? "",
            address: json["address"] ?? "",
            profilePictureUrl: json["profile_picture_url"],
            referralCode: json["referral_code"] ?? "",
            referralCount: json["referral_count"] ?? 0,
            createdAt: DateTime.tryParse(json["created_at"] ?? ""),
            updatedAt: DateTime.tryParse(json["updated_at"] ?? ""),
            v: json["__v"] ?? 0,
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
    String toString(){
        return "$id, $userId, $firstName, $lastName, $address, $profilePictureUrl, $referralCode, $referralCount, $createdAt, $updatedAt, $v, ";
    }

    @override
    List<Object?> get props => [
    id, userId, firstName, lastName, address, profilePictureUrl, referralCode, referralCount, createdAt, updatedAt, v, ];
}
