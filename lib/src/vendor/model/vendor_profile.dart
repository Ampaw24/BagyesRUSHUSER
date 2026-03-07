import 'package:equatable/equatable.dart';

class VendorProfile extends Equatable {
  final String id;
  final String businessName;
  final String ownerName;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? description;
  final List<String> cuisineTypes;
  final String openingTime;
  final String closingTime;
  final Map<String, DayHours> weeklyHours;
  final List<String> operatingDays;
  final double deliveryRadiusKm;
  final double minimumOrder;
  final double deliveryFee;
  final String estimatedDeliveryTime;
  final double rating;
  final int totalReviews;
  final int totalOrders;
  final bool isVerified;
  final bool acceptsPreOrders;
  final String? instagramUrl;
  final String? facebookUrl;
  final String? websiteUrl;
  final String? tiktokUrl;
  final DateTime? createdAt;

  const VendorProfile({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    this.logoUrl,
    this.coverImageUrl,
    this.description,
    this.cuisineTypes = const [],
    this.openingTime = '08:00',
    this.closingTime = '22:00',
    this.weeklyHours = const {},
    this.operatingDays = const [],
    this.deliveryRadiusKm = 5.0,
    this.minimumOrder = 0.0,
    this.deliveryFee = 0.0,
    this.estimatedDeliveryTime = '30-45 min',
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalOrders = 0,
    this.isVerified = false,
    this.acceptsPreOrders = false,
    this.instagramUrl,
    this.facebookUrl,
    this.websiteUrl,
    this.tiktokUrl,
    this.createdAt,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      id: json['id'] as String? ?? '',
      businessName: json['business_name'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      description: json['description'] as String?,
      cuisineTypes: (json['cuisine_types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      openingTime: json['opening_time'] as String? ?? '08:00',
      closingTime: json['closing_time'] as String? ?? '22:00',
      weeklyHours: (json['weekly_hours'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, DayHours.fromJson(v as Map<String, dynamic>)),
          ) ??
          {},
      operatingDays: (json['operating_days'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      deliveryRadiusKm:
          (json['delivery_radius_km'] as num?)?.toDouble() ?? 5.0,
      minimumOrder: (json['minimum_order'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      estimatedDeliveryTime:
          json['estimated_delivery_time'] as String? ?? '30-45 min',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      totalOrders: json['total_orders'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      acceptsPreOrders: json['accepts_pre_orders'] as bool? ?? false,
      instagramUrl: json['instagram_url'] as String?,
      facebookUrl: json['facebook_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      tiktokUrl: json['tiktok_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_name': businessName,
        'owner_name': ownerName,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'logo_url': logoUrl,
        'cover_image_url': coverImageUrl,
        'description': description,
        'cuisine_types': cuisineTypes,
        'opening_time': openingTime,
        'closing_time': closingTime,
        'weekly_hours':
            weeklyHours.map((k, v) => MapEntry(k, v.toJson())),
        'operating_days': operatingDays,
        'delivery_radius_km': deliveryRadiusKm,
        'minimum_order': minimumOrder,
        'delivery_fee': deliveryFee,
        'estimated_delivery_time': estimatedDeliveryTime,
        'rating': rating,
        'total_reviews': totalReviews,
        'total_orders': totalOrders,
        'is_verified': isVerified,
        'accepts_pre_orders': acceptsPreOrders,
        'instagram_url': instagramUrl,
        'facebook_url': facebookUrl,
        'website_url': websiteUrl,
        'tiktok_url': tiktokUrl,
        'created_at': createdAt?.toIso8601String(),
      };

  VendorProfile copyWith({
    String? id,
    String? businessName,
    String? ownerName,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? logoUrl,
    String? coverImageUrl,
    String? description,
    List<String>? cuisineTypes,
    String? openingTime,
    String? closingTime,
    Map<String, DayHours>? weeklyHours,
    List<String>? operatingDays,
    double? deliveryRadiusKm,
    double? minimumOrder,
    double? deliveryFee,
    String? estimatedDeliveryTime,
    double? rating,
    int? totalReviews,
    int? totalOrders,
    bool? isVerified,
    bool? acceptsPreOrders,
    String? instagramUrl,
    String? facebookUrl,
    String? websiteUrl,
    String? tiktokUrl,
    DateTime? createdAt,
  }) {
    return VendorProfile(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      description: description ?? this.description,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      operatingDays: operatingDays ?? this.operatingDays,
      deliveryRadiusKm: deliveryRadiusKm ?? this.deliveryRadiusKm,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalOrders: totalOrders ?? this.totalOrders,
      isVerified: isVerified ?? this.isVerified,
      acceptsPreOrders: acceptsPreOrders ?? this.acceptsPreOrders,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Dummy profile for UI development
  static VendorProfile get dummy => VendorProfile(
        id: 'v_001',
        businessName: "Mama's Kitchen",
        ownerName: 'Ama Mensah',
        phone: '+233 24 123 4567',
        email: 'mama@bagyesrush.com',
        address: '15 Oxford Street, Osu',
        city: 'Accra',
        description:
            'Authentic Ghanaian home-cooked meals made with love. '
            'From jollof rice to banku with tilapia, we bring the taste of home to your doorstep.',
        cuisineTypes: ['Ghanaian', 'West African', 'Grills'],
        openingTime: '07:00',
        closingTime: '22:00',
        weeklyHours: {
          'monday': const DayHours(open: '07:00', close: '22:00'),
          'tuesday': const DayHours(open: '07:00', close: '22:00'),
          'wednesday': const DayHours(open: '07:00', close: '22:00'),
          'thursday': const DayHours(open: '07:00', close: '22:00'),
          'friday': const DayHours(open: '07:00', close: '23:00'),
          'saturday': const DayHours(open: '08:00', close: '23:00'),
          'sunday': const DayHours(open: '10:00', close: '20:00', isClosed: true),
        },
        operatingDays: [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
        ],
        deliveryRadiusKm: 8.0,
        minimumOrder: 25.0,
        deliveryFee: 5.0,
        estimatedDeliveryTime: '25-40 min',
        rating: 4.7,
        totalReviews: 328,
        totalOrders: 1254,
        isVerified: true,
        acceptsPreOrders: true,
        instagramUrl: 'mamaskitchen_accra',
        tiktokUrl: 'mamaskitchen',
        createdAt: DateTime(2024, 3, 15),
      );

  @override
  List<Object?> get props => [
        id,
        businessName,
        ownerName,
        phone,
        email,
        address,
        city,
        logoUrl,
        coverImageUrl,
        description,
        cuisineTypes,
        openingTime,
        closingTime,
        weeklyHours,
        operatingDays,
        deliveryRadiusKm,
        minimumOrder,
        deliveryFee,
        estimatedDeliveryTime,
        rating,
        totalReviews,
        totalOrders,
        isVerified,
        acceptsPreOrders,
        instagramUrl,
        facebookUrl,
        websiteUrl,
        tiktokUrl,
        createdAt,
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
