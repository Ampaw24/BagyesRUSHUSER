import 'package:flutter/services.dart';

import '../enums/map_style_type.dart';

/// Loads Google Map style JSON from the asset bundle.
///
/// Single Responsibility: this class only knows how to fetch a style string.
/// Callers decide which [MapStyleType] to use and when to load it.
///
/// Usage:
/// ```dart
/// final style = await MapStyleService.load(MapStyleType.silver);
/// ```
class MapStyleService {
  MapStyleService._(); // prevent instantiation

  /// Returns the raw JSON string for the given [style], loaded from assets.
  ///
  /// Throws a [FlutterError] if the asset file is missing (caught at build time
  /// by the asset registration in pubspec.yaml).
  static Future<String> load(MapStyleType style) =>
      rootBundle.loadString(style.assetPath);
}
