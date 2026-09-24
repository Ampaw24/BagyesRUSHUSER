import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';

/// A customer's review of a vendor, with the vendor's optional public reply.
///
/// The backend's success shape for `GET /vendor/me/reviews` is undocumented
/// (see `vendor-review-apis.md`), so [fromJson] tolerates several plausible
/// key spellings/nesting rather than assuming one exact contract.
class Review extends Equatable {
  const Review({
    required this.id,
    required this.rating,
    this.comment,
    this.reply,
    this.repliedAt,
    this.isVisible = true,
    required this.createdAt,
    required this.customerName,
    this.customerAvatarUrl,
    this.orderId,
  });

  final String id;
  final int rating;
  final String? comment;
  final String? reply;
  final DateTime? repliedAt;
  final bool isVisible;
  final DateTime createdAt;
  final String customerName;
  final String? customerAvatarUrl;
  final String? orderId;

  bool get hasReply => reply != null && reply!.trim().isNotEmpty;

  factory Review.fromJson(DataMap json) {
    final customer = json['customer'] is DataMap
        ? json['customer'] as DataMap
        : json['user'] is DataMap
            ? json['user'] as DataMap
            : const <String, dynamic>{};

    return Review(
      id: JsonUtils.asString(json['id']),
      rating: JsonUtils.asInt(json['rating']),
      comment: JsonUtils.asStringOrNull(json['comment']),
      reply: JsonUtils.asStringOrNull(json['reply']),
      repliedAt: JsonUtils.asDateTime(json['replied_at'] ?? json['repliedAt']),
      isVisible: JsonUtils.asBool(
        json['is_visible'] ?? json['isVisible'],
        true,
      ),
      createdAt: JsonUtils.asDateTime(json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
      customerName: JsonUtils.asString(
        customer['name'] ?? json['customer_name'] ?? json['customerName'],
        'Customer',
      ),
      customerAvatarUrl: JsonUtils.asStringOrNull(
        customer['avatar'] ??
            customer['photo_url'] ??
            customer['avatar_url'] ??
            json['customer_avatar'],
      ),
      orderId: JsonUtils.asStringOrNull(json['order_id'] ?? json['orderId']),
    );
  }

  /// Narrow patch used after a successful reply submission — only the two
  /// fields that flow can ever change.
  Review copyWith({String? reply, DateTime? repliedAt}) => Review(
        id: id,
        rating: rating,
        comment: comment,
        reply: reply ?? this.reply,
        repliedAt: repliedAt ?? this.repliedAt,
        isVisible: isVisible,
        createdAt: createdAt,
        customerName: customerName,
        customerAvatarUrl: customerAvatarUrl,
        orderId: orderId,
      );

  @override
  List<Object?> get props => [
        id,
        rating,
        comment,
        reply,
        repliedAt,
        isVisible,
        createdAt,
        customerName,
        customerAvatarUrl,
        orderId,
      ];
}
