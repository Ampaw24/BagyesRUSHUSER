import '../models/payment_method_model.dart';
import '../models/mobile_money_model.dart';
import '../models/visa_card_model.dart';
import '../utils/card_utils.dart';

/// ── DUMMY IMPLEMENTATION ─────────────────────────────────────────────────
/// Uses an in-memory list so the feature is fully interactive without a
/// live backend. Swap the method bodies for real Dio calls when the API
/// is ready — the rest of the stack (repository, providers, UI) stays unchanged.
class PaymentApiService {
  PaymentApiService();

  // ── In-memory store ──────────────────────────────────────────────────────

  static int _idCounter = 3;

  static final List<PaymentMethodModel> _store = [
    PaymentMethodModel(
      id: '1',
      type: PaymentMethodType.mobileMoney,
      status: PaymentMethodStatus.verified,
      isDefault: true,
      isEnabled: true,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      mobileMoney: const MobileMoneyModel(
        provider: MobileMoneyProvider.mtnMomo,
        phoneNumber: '+233541234567',
        accountName: 'Kwame Asante',
      ),
    ),
    PaymentMethodModel(
      id: '2',
      type: PaymentMethodType.visaCard,
      status: PaymentMethodStatus.verified,
      isDefault: false,
      isEnabled: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      visaCard: const VisaCardModel(
        cardLast4: '4242',
        cardholderName: 'KWAME ASANTE',
        expiryMonth: '12',
        expiryYear: '27',
        brand: CardBrand.visa,
        tokenizedCardId: 'tok_dummy_visa_4242',
      ),
    ),
  ];

  // ── Fetch all ──────────────────────────────────────────────────────────

  Future<List<PaymentMethodModel>> fetchPaymentMethods() async {
    await _fakeDelay();
    return List<PaymentMethodModel>.from(_store);
  }

  // ── Add mobile money ───────────────────────────────────────────────────

  Future<PaymentMethodModel> addMobileMoney(MobileMoneyModel model) async {
    await _fakeDelay();
    final newMethod = PaymentMethodModel(
      id: '${++_idCounter}',
      type: PaymentMethodType.mobileMoney,
      status: PaymentMethodStatus.pending, // pending until OTP verified
      isDefault: _store.isEmpty,
      isEnabled: true,
      createdAt: DateTime.now(),
      mobileMoney: model,
    );
    _store.add(newMethod);
    return newMethod;
  }

  // ── Add Visa card ──────────────────────────────────────────────────────

  Future<PaymentMethodModel> addVisaCard({
    required String rawCardNumber,
    required String cardholderName,
    required String expiry,
    required String cvv,
  }) async {
    await _fakeDelay();
    final last4 = CardUtils.extractLast4(rawCardNumber);
    final brand = CardUtils.detectBrand(rawCardNumber);
    final (month, year) = CardUtils.parseExpiry(expiry);

    final model = VisaCardModel(
      cardLast4: last4,
      cardholderName: cardholderName.toUpperCase(),
      expiryMonth: month,
      expiryYear: year,
      brand: brand,
      tokenizedCardId: 'tok_dummy_${last4}_${DateTime.now().millisecondsSinceEpoch}',
    );

    final newMethod = PaymentMethodModel(
      id: '${++_idCounter}',
      type: PaymentMethodType.visaCard,
      status: PaymentMethodStatus.pending,
      isDefault: _store.isEmpty,
      isEnabled: true,
      createdAt: DateTime.now(),
      visaCard: model,
    );
    _store.add(newMethod);
    return newMethod;
  }

  // ── Delete ─────────────────────────────────────────────────────────────

  Future<void> deletePaymentMethod(String id) async {
    await _fakeDelay(ms: 600);
    _store.removeWhere((m) => m.id == id);
  }

  // ── Set default ────────────────────────────────────────────────────────

  Future<void> setDefaultPaymentMethod(String id) async {
    await _fakeDelay(ms: 600);
    for (int i = 0; i < _store.length; i++) {
      _store[i] = _store[i].copyWith(isDefault: _store[i].id == id);
    }
  }

  // ── Toggle enabled ─────────────────────────────────────────────────────

  Future<void> toggleEnabled(String id, {required bool enabled}) async {
    await _fakeDelay(ms: 500);
    final idx = _store.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _store[idx] = _store[idx].copyWith(isEnabled: enabled);
    }
  }

  // ── Mark verified (called by OTP service after success) ────────────────

  void markVerified(String id) {
    final idx = _store.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _store[idx] = _store[idx].copyWith(status: PaymentMethodStatus.verified);
    }
  }

  // ── Helper ─────────────────────────────────────────────────────────────

  Future<void> _fakeDelay({int ms = 900}) =>
      Future.delayed(Duration(milliseconds: ms));
}
