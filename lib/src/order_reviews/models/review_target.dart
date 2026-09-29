import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';

/// Who a review lands on. `POST customer/orders/:id/review` decides this
/// from the order itself — food orders review the vendor, parcels the rider.
enum ReviewSubject { vendor, rider }

/// Everything the review UI needs about the order being rated.
class ReviewTarget extends Equatable {
  const ReviewTarget({
    required this.orderId,
    required this.subject,
    required this.name,
    this.imageUrl,
    this.phone,
  });

  final String orderId;
  final ReviewSubject subject;
  final String name;
  final String? imageUrl;
  final String? phone;

  static const riderFallbackName = 'your rider';

  factory ReviewTarget.fromOrder(ConsumerOrder order) {
    if (order.parcelDirection != null) {
      final rider = order.driverName?.trim() ?? '';
      return ReviewTarget(
        orderId: order.id,
        subject: ReviewSubject.rider,
        name: rider.isEmpty ? riderFallbackName : rider,
        phone: order.driverPhone,
      );
    }
    return ReviewTarget(
      orderId: order.id,
      subject: ReviewSubject.vendor,
      name: order.restaurantName.trim().isEmpty
          ? 'the restaurant'
          : order.restaurantName,
      imageUrl: order.restaurantImageUrl.isEmpty
          ? null
          : order.restaurantImageUrl,
    );
  }

  bool get isRider => subject == ReviewSubject.rider;

  /// False for a parcel whose rider name the backend didn't send.
  bool get hasNamedRider => isRider && name != riderFallbackName;

  @override
  List<Object?> get props => [orderId, subject, name, imageUrl, phone];
}
