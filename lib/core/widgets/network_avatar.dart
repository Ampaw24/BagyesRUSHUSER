import 'package:bagyesrushappusernew/core/utils/image_cache_size.dart';
import 'package:flutter/material.dart';

import '../../constant/app_theme.dart';

/// "Kofi Asante" → "KA", "Ama" → "A", "" → "?".
String personInitials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  final first = parts.first[0];
  final second = parts.length > 1 ? parts.last[0] : '';
  return (first + second).toUpperCase();
}

/// Stable tint for a name — the same vendor always gets the same colour, so
/// logo-less vendors stay recognisable across lists.
Color nameTintColor(String name) {
  const palette = [
    Color(0xFFD32F2F), // brand red
    Color(0xFFDD6B20), // orange
    Color(0xFF38A169), // green
    Color(0xFF3182CE), // blue
    Color(0xFF805AD5), // purple
    Color(0xFFD53F8C), // pink
    Color(0xFF319795), // teal
    Color(0xFFB7791F), // amber
  ];
  final key = name.trim().toLowerCase();
  if (key.isEmpty) return palette.first;
  // Small, deterministic string hash (String.hashCode isn't stable across runs).
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return palette[hash % palette.length];
}

/// Circular person avatar: the photo at [photoUrl] once it has loaded, the
/// name's initials while it loads, when there is no URL, or when the image
/// fails (404, offline, …) — never an empty circle.
class NetworkAvatar extends StatelessWidget {
  const NetworkAvatar({
    super.key,
    required this.name,
    required this.size,
    this.photoUrl,
    this.backgroundColor,
    this.foregroundColor = AppColors.primary,
    this.borderRadius,
  });

  final String name;
  final double size;
  final String? photoUrl;

  /// Initials background; defaults to a light tint of [foregroundColor].
  final Color? backgroundColor;
  final Color foregroundColor;

  /// Rounded-square avatar (e.g. a vendor logo) instead of a circle.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim() ?? '';
    final initials = Container(
      color: backgroundColor ?? foregroundColor.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        personInitials(name),
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        ),
      ),
    );

    final avatar = SizedBox.square(
        dimension: size,
        child: url.isEmpty
            ? initials
            : Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: coverCacheWidth(
                  context,
                  width: size,
                  height: size,
                ),
                errorBuilder: (_, _, _) => initials,
                frameBuilder: (_, image, frame, loadedSync) {
                  if (loadedSync) return image;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      initials,
                      AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        child: image,
                      ),
                    ],
                  );
                },
              ),
    );

    final radius = borderRadius;
    return radius == null
        ? ClipOval(child: avatar)
        : ClipRRect(borderRadius: radius, child: avatar);
  }
}
