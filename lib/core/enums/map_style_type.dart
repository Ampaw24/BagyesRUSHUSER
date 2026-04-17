/// Defines the available Google Map visual styles.
///
/// Each value maps directly to a JSON file under `assets/map_styles/`.
/// To add a new style:
///   1. Add a new value here (e.g. `dark`)
///   2. Drop the matching file at `assets/map_styles/dark.json`
///   — no other code needs to change (Open/Closed Principle).
enum MapStyleType {
  silver;

  /// Asset path resolved from the enum name — e.g. `assets/map_styles/silver.json`.
  String get assetPath => 'assets/map_styles/$name.json';
}
