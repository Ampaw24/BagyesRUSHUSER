/// Represents the logged-in consumer's profile data.
class ConsumerProfile {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final bool isVerified;
  final int orderCount;
  final int reviewCount;
  final double walletBalance;

  const ConsumerProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.isVerified = false,
    this.orderCount = 0,
    this.reviewCount = 0,
    this.walletBalance = 0,
  });

  /// Two-letter initials derived from [fullName].
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.substring(0, 2).toUpperCase();
  }

  String get formattedWallet => 'GHS ${walletBalance.toStringAsFixed(0)}';

  ConsumerProfile copyWith({
    String? fullName,
    String? email,
    String? avatarUrl,
    bool? isVerified,
    int? orderCount,
    int? reviewCount,
    double? walletBalance,
  }) {
    return ConsumerProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      orderCount: orderCount ?? this.orderCount,
      reviewCount: reviewCount ?? this.reviewCount,
      walletBalance: walletBalance ?? this.walletBalance,
    );
  }
}
