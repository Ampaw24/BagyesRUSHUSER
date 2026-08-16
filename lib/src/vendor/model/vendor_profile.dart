import 'package:equatable/equatable.dart';

class VendorProfile extends Equatable {
  const VendorProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.businessTypeId,
    required this.contactPersonName,
    required this.businessAddress,
    required this.city,
    required this.description,
    required this.taxIdentificationNumber,
    required this.cuisineTypes,
    required this.deliveryRadiusKm,
    required this.openingTime,
    required this.closingTime,
    required this.operatingDays,
    required this.estimatedPrepTimeMinutes,
    required this.status,
    required this.isProfileComplete,
    required this.name,
    required this.categories,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTimeMin,
    required this.deliveryTimeMax,
    required this.deliveryFee,
    required this.minOrder,
    required this.isOpen,
    required this.isFeatured,
    required this.isActive,
    required this.discountPercent,
    required this.createdAt,
    required this.updatedAt,
    this.logoUrl,
    this.coverImageUrl,
    this.instagramUrl,
    this.facebookUrl,
    this.tiktokUrl,
    this.websiteUrl,
    this.acceptsPreOrders = false,
    this.totalOrders = 0,
    this.phone = '',
    this.email = '',
  });

  final String id;
  final String userId;
  final String businessName;
  final String businessTypeId;
  final String contactPersonName;
  final String businessAddress;
  final String city;
  final String description;
  final String taxIdentificationNumber;
  final List<String> cuisineTypes;
  final num deliveryRadiusKm;
  final String openingTime;
  final String closingTime;
  final List<String> operatingDays;
  final int estimatedPrepTimeMinutes;
  final String status;
  final bool isProfileComplete;
  final String name;
  final List<dynamic> categories;
  final num rating;
  final int reviewCount;
  final int deliveryTimeMin;
  final int deliveryTimeMax;
  final num deliveryFee;
  final num minOrder;
  final bool isOpen;
  final bool isFeatured;
  final bool isActive;
  final num discountPercent;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Optional fields for UI compatibility
  final String? logoUrl;
  final String? coverImageUrl;
  final String? instagramUrl;
  final String? facebookUrl;
  final String? tiktokUrl;
  final String? websiteUrl;
  final bool acceptsPreOrders;
  final int totalOrders;
  final String phone;
  final String email;

  // Compatibility Getters
  String get ownerName => contactPersonName;
  String get address => businessAddress;
  num get minimumOrder => minOrder;
  String get estimatedDeliveryTime => '$deliveryTimeMin-$deliveryTimeMax min';
  int get totalReviews => reviewCount;
  bool get isVerified => status == 'active';

  // Static dummy for compatibility
  static VendorProfile get dummy => VendorProfile(
        id: 'dummy_id',
        userId: 'dummy_user_id',
        businessName: "Mama's Kitchen",
        businessTypeId: 'dummy_type',
        contactPersonName: 'Ama Mensah',
        businessAddress: '15 Oxford Street, Osu',
        city: 'Accra',
        description: 'Authentic Ghanaian home-cooked meals.',
        taxIdentificationNumber: 'TIN123456',
        cuisineTypes: const ['Ghanaian', 'Local'],
        deliveryRadiusKm: 5.0,
        openingTime: '08:00',
        closingTime: '22:00',
        operatingDays: const ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
        estimatedPrepTimeMinutes: 30,
        status: 'active',
        isProfileComplete: true,
        name: "Mama's Kitchen",
        categories: const [],
        rating: 4.5,
        reviewCount: 120,
        deliveryTimeMin: 30,
        deliveryTimeMax: 45,
        deliveryFee: 5.0,
        minOrder: 20.0,
        isOpen: true,
        isFeatured: false,
        isActive: true,
        discountPercent: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  // Calculated fields for UI compatibility
  Map<String, DayHours> get weeklyHours {
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return {
      for (final day in days)
        day: DayHours(
          open: openingTime,
          close: closingTime,
          isClosed: !operatingDays.contains(day.toLowerCase()),
        ),
    };
  }

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      userId: (json["user_id"] ?? "").toString(),
      businessName: json["business_name"] ?? "",
      businessTypeId: json["business_type_id"] ?? "",
      contactPersonName: json["contact_person_name"] ?? "",
      businessAddress: json["business_address"] ?? "",
      city: json["city"] ?? "",
      description: json["description"] ?? "",
      taxIdentificationNumber: json["tax_identification_number"] ?? "",
      cuisineTypes: List<String>.from(json["cuisine_types"] ?? []),
      deliveryRadiusKm: json["delivery_radius_km"] ?? 0,
      openingTime: json["opening_time"] ?? "08:00",
      closingTime: json["closing_time"] ?? "22:00",
      operatingDays: List<String>.from(json["operating_days"] ?? []),
      estimatedPrepTimeMinutes: json["estimated_prep_time_minutes"] ?? 0,
      status: json["status"] ?? "",
      isProfileComplete: json["is_profile_complete"] ?? false,
      name: json["name"] ?? "",
      categories: List<dynamic>.from(json["categories"] ?? []),
      rating: (json["rating"] as num?)?.toDouble() ?? 0.0,
      reviewCount: json["review_count"] ?? 0,
      deliveryTimeMin: json["delivery_time_min"] ?? 0,
      deliveryTimeMax: json["delivery_time_max"] ?? 0,
      deliveryFee: (json["delivery_fee"] as num?)?.toDouble() ?? 0.0,
      minOrder: (json["min_order"] as num?)?.toDouble() ?? 0.0,
      isOpen: json["is_open"] ?? false,
      isFeatured: json["is_featured"] ?? false,
      isActive: json["is_active"] ?? false,
      discountPercent: json["discount_percent"] ?? 0,
      createdAt: json["created_at"] != null
          ? DateTime.tryParse(json["created_at"] as String)
          : null,
      updatedAt: json["updated_at"] != null
          ? DateTime.tryParse(json["updated_at"] as String)
          : null,
      logoUrl: json["logo_url"] as String?,
      coverImageUrl: json["cover_image_url"] as String?,
      instagramUrl: json["instagram_url"] as String?,
      facebookUrl: json["facebook_url"] as String?,
      tiktokUrl: json["tiktok_url"] as String?,
      websiteUrl: json["website_url"] as String?,
      acceptsPreOrders: json["accepts_pre_orders"] ?? false,
      totalOrders: json["total_orders"] ?? 0,
      phone: json["phone"] as String? ?? '',
      email: json["email"] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "user_id": userId,
        "business_name": businessName,
        "business_type_id": businessTypeId,
        "contact_person_name": contactPersonName,
        "business_address": businessAddress,
        "city": city,
        "description": description,
        "tax_identification_number": taxIdentificationNumber,
        "cuisine_types": cuisineTypes,
        "delivery_radius_km": deliveryRadiusKm,
        "opening_time": openingTime,
        "closing_time": closingTime,
        "operating_days": operatingDays,
        "estimated_prep_time_minutes": estimatedPrepTimeMinutes,
        "status": status,
        "is_profile_complete": isProfileComplete,
        "name": name,
        "categories": categories,
        "rating": rating,
        "review_count": reviewCount,
        "delivery_time_min": deliveryTimeMin,
        "delivery_time_max": deliveryTimeMax,
        "delivery_fee": deliveryFee,
        "min_order": minOrder,
        "is_open": isOpen,
        "is_featured": isFeatured,
        "is_active": isActive,
        "discount_percent": discountPercent,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "logo_url": logoUrl,
        "cover_image_url": coverImageUrl,
        "instagram_url": instagramUrl,
        "facebook_url": facebookUrl,
        "tiktok_url": tiktokUrl,
        "website_url": websiteUrl,
        "accepts_pre_orders": acceptsPreOrders,
        "total_orders": totalOrders,
        "phone": phone,
        "email": email,
      };

  VendorProfile copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? businessTypeId,
    String? contactPersonName,
    String? businessAddress,
    String? city,
    String? description,
    String? taxIdentificationNumber,
    List<String>? cuisineTypes,
    num? deliveryRadiusKm,
    String? openingTime,
    String? closingTime,
    List<String>? operatingDays,
    int? estimatedPrepTimeMinutes,
    String? status,
    bool? isProfileComplete,
    String? name,
    List<dynamic>? categories,
    num? rating,
    int? reviewCount,
    int? deliveryTimeMin,
    int? deliveryTimeMax,
    num? deliveryFee,
    num? minOrder,
    bool? isOpen,
    bool? isFeatured,
    bool? isActive,
    num? discountPercent,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? logoUrl,
    String? coverImageUrl,
    String? instagramUrl,
    String? facebookUrl,
    String? tiktokUrl,
    String? websiteUrl,
    bool? acceptsPreOrders,
    int? totalOrders,
    String? phone,
    String? email,
    Map<String, DayHours>? weeklyHours,
    // Compatibility parameters
    String? ownerName,
    String? address,
    num? minimumOrder,
    String? estimatedDeliveryTime,
  }) {
    // If weeklyHours is passed, we might want to update operatingDays
    List<String>? newOperatingDays = operatingDays;
    String? newOpeningTime = openingTime;
    String? newClosingTime = closingTime;
    
    if (weeklyHours != null) {
      newOperatingDays = weeklyHours.entries
          .where((e) => !e.value.isClosed)
          .map((e) => e.key)
          .toList();
      if (weeklyHours.isNotEmpty) {
        final firstDay = weeklyHours.values.first;
        newOpeningTime = firstDay.open;
        newClosingTime = firstDay.close;
      }
    }

    return VendorProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      businessTypeId: businessTypeId ?? this.businessTypeId,
      contactPersonName: ownerName ?? contactPersonName ?? this.contactPersonName,
      businessAddress: address ?? businessAddress ?? this.businessAddress,
      city: city ?? this.city,
      description: description ?? this.description,
      taxIdentificationNumber: taxIdentificationNumber ?? this.taxIdentificationNumber,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      deliveryRadiusKm: deliveryRadiusKm ?? this.deliveryRadiusKm,
      openingTime: newOpeningTime ?? this.openingTime,
      closingTime: newClosingTime ?? this.closingTime,
      operatingDays: newOperatingDays ?? this.operatingDays,
      estimatedPrepTimeMinutes: estimatedPrepTimeMinutes ?? this.estimatedPrepTimeMinutes,
      status: status ?? this.status,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      name: name ?? this.name,
      categories: categories ?? this.categories,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      deliveryTimeMin: deliveryTimeMin ?? this.deliveryTimeMin,
      deliveryTimeMax: deliveryTimeMax ?? this.deliveryTimeMax,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minOrder: minimumOrder ?? minOrder ?? this.minOrder,
      isOpen: isOpen ?? this.isOpen,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      discountPercent: discountPercent ?? this.discountPercent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      acceptsPreOrders: acceptsPreOrders ?? this.acceptsPreOrders,
      totalOrders: totalOrders ?? this.totalOrders,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        businessName,
        businessTypeId,
        contactPersonName,
        businessAddress,
        city,
        description,
        taxIdentificationNumber,
        cuisineTypes,
        deliveryRadiusKm,
        openingTime,
        closingTime,
        operatingDays,
        estimatedPrepTimeMinutes,
        status,
        isProfileComplete,
        name,
        categories,
        rating,
        reviewCount,
        deliveryTimeMin,
        deliveryTimeMax,
        deliveryFee,
        minOrder,
        isOpen,
        isFeatured,
        isActive,
        discountPercent,
        createdAt,
        updatedAt,
        logoUrl,
        coverImageUrl,
        instagramUrl,
        facebookUrl,
        tiktokUrl,
        websiteUrl,
        acceptsPreOrders,
        totalOrders,
        phone,
        email,
      ];
}

class DayHours extends Equatable {
  final String open;
  final String close;
  final bool isClosed;

  const DayHours({
    required this.open,
    required this.close,
    this.isClosed = false,
  });

  factory DayHours.fromJson(Map<String, dynamic> json) {
    return DayHours(
      open: json['open'] as String? ?? '08:00',
      close: json['close'] as String? ?? '22:00',
      isClosed: json['is_closed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'open': open,
        'close': close,
        'is_closed': isClosed,
      };

  DayHours copyWith({String? open, String? close, bool? isClosed}) {
    return DayHours(
      open: open ?? this.open,
      close: close ?? this.close,
      isClosed: isClosed ?? this.isClosed,
    );
  }

  @override
  List<Object?> get props => [open, close, isClosed];
}
