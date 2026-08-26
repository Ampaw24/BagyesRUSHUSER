import 'package:flutter/material.dart';
import '../../model/payout_provider_model.dart';

/// Brand color + optional bundled asset for a payout provider, resolved by
/// matching known networks (so the existing MTN/Telecel/AirtelTigo artwork
/// keeps showing up) and falling back to a deterministic color for anything
/// else in the live catalog (new banks, new mobile-money networks).
class PayoutProviderVisual {
  const PayoutProviderVisual({required this.color, this.assetPath});
  final Color color;
  final String? assetPath;
}

const _fallbackPalette = [
  Color(0xFF6C5CE7),
  Color(0xFF00B894),
  Color(0xFF0984E3),
  Color(0xFFE17055),
  Color(0xFFD63031),
  Color(0xFF00CEC9),
];

PayoutProviderVisual payoutProviderVisual(PayoutProviderModel provider) {
  final key = '${provider.slug} ${provider.shortName} ${provider.name}'.toLowerCase();

  if (key.contains('mtn')) {
    return const PayoutProviderVisual(
      color: Color(0xFFFFCC00),
      assetPath: 'assets/icons/mtnbanner.png',
    );
  }
  if (key.contains('telecel') || key.contains('vodafone')) {
    return const PayoutProviderVisual(
      color: Color(0xFFE53935),
      assetPath: 'assets/icons/telecel_icon.jpg',
    );
  }
  if (key.contains('airteltigo') || key.contains('airtel') || key.contains('tigo')) {
    return const PayoutProviderVisual(
      color: Color(0xFF1565C0),
      assetPath: 'assets/icons/atbanner.png',
    );
  }

  final color = _fallbackPalette[provider.id.abs() % _fallbackPalette.length];
  return PayoutProviderVisual(color: color);
}

/// One or two initials for a provider avatar fallback, e.g. "ECB" → "EC".
String payoutProviderInitials(PayoutProviderModel provider) {
  final source = provider.shortName.trim().isNotEmpty ? provider.shortName : provider.name;
  final letters = source
      .trim()
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .map((s) => s[0])
      .take(2)
      .join()
      .toUpperCase();
  return letters.isEmpty ? '?' : letters;
}

/// Renders the best available visual for a provider: remote logo, bundled
/// brand asset, or a colored initials avatar — in that priority order.
class PayoutProviderAvatar extends StatelessWidget {
  const PayoutProviderAvatar({super.key, required this.provider, required this.size});

  final PayoutProviderModel provider;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visual = payoutProviderVisual(provider);
    final radius = size * 0.28;

    if (provider.logoUrl != null && provider.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          provider.logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(visual, radius),
        ),
      );
    }
    if (visual.assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          visual.assetPath!,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _fallback(visual, radius),
        ),
      );
    }
    return _fallback(visual, radius);
  }

  Widget _fallback(PayoutProviderVisual visual, double radius) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        payoutProviderInitials(provider),
        style: TextStyle(
          color: visual.color,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
