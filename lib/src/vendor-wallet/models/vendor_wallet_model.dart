import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/utils/json_utils.dart';

/// Result of `GET /vendor/me/wallet`.
class VendorWalletModel extends Equatable {
  const VendorWalletModel({required this.balance, this.currency = 'GHS'});

  final double balance;
  final String currency;

  String get formattedBalance => '$currency ${balance.toStringAsFixed(2)}';

  factory VendorWalletModel.fromJson(Map<String, dynamic> json) {
    return VendorWalletModel(
      balance: JsonUtils.asDouble(json['balance']),
      currency: JsonUtils.asString(json['currency'], 'GHS'),
    );
  }

  @override
  List<Object?> get props => [balance, currency];
}
