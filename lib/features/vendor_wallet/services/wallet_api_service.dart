import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../models/withdrawal_model.dart';

/// ── DUMMY IMPLEMENTATION ─────────────────────────────────────────────────
/// All methods simulate network latency and return realistic in-memory data.
/// Swap method bodies for real Dio calls when the API is ready.
class WalletApiService {
  WalletApiService();

  // ── In-memory state ──────────────────────────────────────────────────────

  static WalletModel _wallet = const WalletModel(
    currency: 'GH₵',
    availableBalance: 1248.50,
    pendingBalance: 312.00,
    totalEarnings: 8640.75,
    totalWithdrawn: 7080.25,
  );

  static int _txCounter = 100;

  static final List<TransactionModel> _transactions = [
    TransactionModel(
      id: 't1',
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      amount: 85.00,
      description: 'Order #ORD-4821 settled',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TransactionModel(
      id: 't2',
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      amount: 120.50,
      description: 'Order #ORD-4819 settled',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    TransactionModel(
      id: 't3',
      type: TransactionType.withdrawal,
      status: TransactionStatus.completed,
      amount: 500.00,
      fee: 7.50,
      description: 'Withdrawal to MTN MoMo',
      paymentMethodLabel: 'MTN MoMo •• 567',
      referenceId: 'WD-20240301-001',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: 't4',
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      amount: 210.00,
      description: 'Order #ORD-4810 settled',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    TransactionModel(
      id: 't5',
      type: TransactionType.withdrawal,
      status: TransactionStatus.completed,
      amount: 300.00,
      fee: 4.50,
      description: 'Withdrawal to Visa ••••4242',
      paymentMethodLabel: 'Visa ••••4242',
      referenceId: 'WD-20240228-002',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    TransactionModel(
      id: 't6',
      type: TransactionType.credit,
      status: TransactionStatus.pending,
      amount: 312.00,
      description: 'Orders #ORD-4820, #ORD-4822 (settling)',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    TransactionModel(
      id: 't7',
      type: TransactionType.refund,
      status: TransactionStatus.completed,
      amount: 45.00,
      description: 'Refund for cancelled order #ORD-4805',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    TransactionModel(
      id: 't8',
      type: TransactionType.withdrawal,
      status: TransactionStatus.failed,
      amount: 200.00,
      fee: 3.00,
      description: 'Withdrawal failed — insufficient balance',
      paymentMethodLabel: 'MTN MoMo •• 567',
      referenceId: 'WD-20240225-003',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  // ── Fetch wallet ─────────────────────────────────────────────────────────

  Future<WalletModel> fetchWallet() async {
    await _delay();
    return _wallet;
  }

  // ── Fetch transactions ───────────────────────────────────────────────────

  Future<List<TransactionModel>> fetchTransactions() async {
    await _delay();
    final sorted = List<TransactionModel>.from(_transactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  // ── Request withdrawal ───────────────────────────────────────────────────

  Future<WithdrawalModel> requestWithdrawal({
    required double amount,
    required String paymentMethodId,
    required String paymentMethodLabel,
  }) async {
    await _delay(ms: 1200);

    if (amount < kMinWithdrawal) {
      throw Exception('Minimum withdrawal is GH₵ ${kMinWithdrawal.toStringAsFixed(2)}');
    }
    if (amount > _wallet.availableBalance) {
      throw Exception('Insufficient available balance');
    }

    final fee = WithdrawalModel.calculateFee(amount);
    final net = WithdrawalModel.calculateNet(amount);
    final now = DateTime.now();
    final refCode =
        'WD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${++_txCounter}';

    // Deduct from available balance
    _wallet = _wallet.copyWith(
      availableBalance: _wallet.availableBalance - amount,
      totalWithdrawn: _wallet.totalWithdrawn + amount,
    );

    // Record as a transaction
    final tx = TransactionModel(
      id: 'tx_$refCode',
      type: TransactionType.withdrawal,
      status: TransactionStatus.processing,
      amount: amount,
      fee: fee,
      description: 'Withdrawal to $paymentMethodLabel',
      paymentMethodLabel: paymentMethodLabel,
      referenceId: refCode,
      createdAt: now,
    );
    _transactions.insert(0, tx);

    return WithdrawalModel(
      id: refCode,
      amount: amount,
      fee: fee,
      netAmount: net,
      paymentMethodId: paymentMethodId,
      paymentMethodLabel: paymentMethodLabel,
      status: TransactionStatus.processing,
      createdAt: now,
      referenceCode: refCode,
    );
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  Future<void> _delay({int ms = 800}) =>
      Future.delayed(Duration(milliseconds: ms));
}

