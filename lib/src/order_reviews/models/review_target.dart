import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';

/// Who a rating is for. One `POST customer/orders/:id/review` can rate both
/// the vendor (food orders) and the rider who delivered.
enum ReviewSubject {
  vendor,
  rider;

  /// Request/response keys: `vendor_rating`, `rider_comment`, …
  String get ratingKey => '${name}_rating';
  String get commentKey => '${name}_comment';
}

/// One reviewable party on an order.
class ReviewParty extends Equatable {
  const ReviewParty({
    required this.subject,
    required this.name,
    this.imageUrl,
    this.phone,
  });

  final ReviewSubject subject;
  final String name;
  final String? imageUrl;
  final String? phone;

  static const riderFallbackName = 'your rider';

  bool get isRider => subject == ReviewSubject.rider;

  /// False for a rider whose name the backend didn't send.
  bool get hasNamedRider => isRider && name != riderFallbackName;

  @override
  List<Object?> get props => [subject, name, imageUrl, phone];
}

/// Everything the review UI needs about the order being rated.
class ReviewTarget extends Equatable {
  const ReviewTarget({
    required this.orderId,
    required this.parties,
    this.isParcel = false,
  });

  final String orderId;

  /// Vendor first (food orders), then the rider. Never empty.
  final List<ReviewParty> parties;
  final bool isParcel;

  factory ReviewTarget.fromOrder(ConsumerOrder order) {
    final isParcel = order.isParcel;
    final vendor = order.restaurantName.trim();
    final rider = order.driverName?.trim() ?? '';

    return ReviewTarget(
      orderId: order.id,
      isParcel: isParcel,
      parties: [
        if (!isParcel)
          ReviewParty(
            subject: ReviewSubject.vendor,
            name: vendor.isEmpty ? 'the restaurant' : vendor,
            imageUrl: order.restaurantImageUrl.isEmpty
                ? null
                : order.restaurantImageUrl,
          ),
        // A parcel is all about its rider, so it keeps the section even
        // unnamed; a food order's rider shows once the backend names one.
        if (isParcel || rider.isNotEmpty)
          ReviewParty(
            subject: ReviewSubject.rider,
            name: rider.isEmpty ? ReviewParty.riderFallbackName : rider,
            phone: order.driverPhone,
          ),
      ],
    );
  }

  /// The party the quick "tap a star" prompts rate.
  ReviewParty get primary => parties.first;

  ReviewParty? partyFor(ReviewSubject subject) {
    for (final party in parties) {
      if (party.subject == subject) return party;
    }
    return null;
  }

  @override
  List<Object?> get props => [orderId, parties, isParcel];
}
