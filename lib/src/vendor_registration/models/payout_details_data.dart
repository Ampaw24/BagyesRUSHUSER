import 'package:equatable/equatable.dart';

/// Data model for Step 4 - Payout Details
class PayoutDetailsData extends Equatable {
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String? branchCode;
  final String? mobileMoneyNumber;
  final String? mobileMoneyProvider;

  const PayoutDetailsData({
    this.bankName = '',
    this.accountNumber = '',
    this.accountName = '',
    this.branchCode,
    this.mobileMoneyNumber,
    this.mobileMoneyProvider,
  });

  PayoutDetailsData copyWith({
    String? bankName,
    String? accountNumber,
    String? accountName,
    String? branchCode,
    String? mobileMoneyNumber,
    String? mobileMoneyProvider,
  }) {
    return PayoutDetailsData(
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      branchCode: branchCode ?? this.branchCode,
      mobileMoneyNumber: mobileMoneyNumber ?? this.mobileMoneyNumber,
      mobileMoneyProvider: mobileMoneyProvider ?? this.mobileMoneyProvider,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_name': accountName,
      'branch_code': branchCode,
      'mobile_money_number': mobileMoneyNumber,
      'mobile_money_provider': mobileMoneyProvider,
    };
  }

  @override
  List<Object?> get props => [
    bankName,
    accountNumber,
    accountName,
    branchCode,
    mobileMoneyNumber,
    mobileMoneyProvider,
  ];
}
