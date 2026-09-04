import 'package:flutter/material.dart';

import '../../constant/image_constants.dart';

/// White, rounded card that frames the Bagyes logo mark — the same treatment
/// used on the splash screen, reused on onboarding and auth screens so the
/// mark always sits on a clean surface instead of floating as a bare
/// rectangular image against the decorative background.
///
/// Padding is proportional to [size] so the mark never touches an edge
/// regardless of the source asset's aspect ratio.
class AppLogoCard extends StatelessWidget {
  const AppLogoCard({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
      
        borderRadius: BorderRadius.circular(size * 0.22),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.05),
        //     blurRadius: 24,
        //     offset: const Offset(0, 10),
        //   ),
        // ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.12),
        child: Image.asset(AssetImages.bagyesLogoRm, fit: BoxFit.contain),
      ),
    );
  }
}
