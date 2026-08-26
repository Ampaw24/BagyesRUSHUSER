/// Mobile money networks payouts can be sent to.
///
/// The API identifies a provider by [id] (`payout_provider_id`, validated
/// server-side against `payout_providers` table). There is no "list
/// providers" endpoint yet, so the known set is declared here.
enum PayoutProvider {
  mtnMomo(1, 'MTN Mobile Money', 'MTN', ['024', '054', '055', '059']),
  telecelCash(2, 'Telecel Cash', 'Telecel', ['020', '050']),
  airtelTigo(3, 'AirtelTigo Money', 'AT', ['026', '027', '056', '057']);

  const PayoutProvider(
    this.id,
    this.displayName,
    this.shortName,
    this.dialPrefixes,
  );

  final int id;
  final String displayName;
  final String shortName;

  /// Expected dial prefix(es) for Ghana (country-code +233 stripped).
  final List<String> dialPrefixes;

  static PayoutProvider? fromId(int? id) {
    for (final provider in PayoutProvider.values) {
      if (provider.id == id) return provider;
    }
    return null;
  }
}
