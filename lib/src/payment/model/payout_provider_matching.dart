import 'payout_provider_model.dart';

/// Best-effort match of a provider stored as a raw string (bank `name`,
/// or a mobile-money identifier like `'mtn'`) against the live-fetched
/// catalog, so previously-saved payout data can be preselected in a
/// [PayoutProviderDropdown]. Falls back to null if nothing matches.
PayoutProviderModel? matchPayoutProvider(
  List<PayoutProviderModel> providers,
  String? raw,
) {
  if (raw == null || raw.trim().isEmpty) return null;
  final needle = raw.trim().toLowerCase();
  for (final p in providers) {
    if (p.name.toLowerCase() == needle ||
        p.shortName.toLowerCase() == needle ||
        p.slug.toLowerCase() == needle) {
      return p;
    }
  }
  for (final p in providers) {
    if (needle.contains(p.shortName.toLowerCase()) ||
        p.shortName.toLowerCase().contains(needle)) {
      return p;
    }
  }
  return null;
}
