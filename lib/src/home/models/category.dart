import 'package:bagyesrushappusernew/src/home/models/category_element.model.dart';
import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({required this.categories, required this.total});

  final List<CategoryElement> categories;
  final num total;

  Category copyWith({List<CategoryElement>? categories, num? total}) {
    return Category(
      categories: categories ?? this.categories,
      total: total ?? this.total,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categories: json["categories"] == null
          ? []
          : List<CategoryElement>.from(
              json["categories"]!.map((x) => CategoryElement.fromJson(x)),
            ),
      total: json["total"] ?? 0,
    );
  }

  /// Builds a [Category] out of a raw `/categories` response body,
  /// regardless of whether the API wraps the list as
  /// `data: { categories: [...], total }` (the shape [Category.fromJson]
  /// expects), nests it under a paginated envelope
  /// (`data: { docs / items / results / list: [...] }`), or returns the
  /// array directly under `data`.
  ///
  /// Never throws — falls back to an empty category list so a shape
  /// mismatch surfaces as "no categories" instead of a crash.
  factory Category.fromResponseData(dynamic rawData) {
    if (rawData is! Map<String, dynamic>) {
      return const Category(categories: [], total: 0);
    }

    final inner = rawData['data'];

    if (inner is Map<String, dynamic>) {
      if (inner['categories'] != null) return Category.fromJson(inner);

      for (final key in ['docs', 'items', 'results', 'list']) {
        final nested = inner[key];
        if (nested is List) {
          final elements = nested
              .map((e) => CategoryElement.fromJson(e as Map<String, dynamic>))
              .toList();
          return Category(categories: elements, total: elements.length);
        }
      }

      return const Category(categories: [], total: 0);
    }

    if (inner is List) {
      final elements = inner
          .map((e) => CategoryElement.fromJson(e as Map<String, dynamic>))
          .toList();
      return Category(categories: elements, total: elements.length);
    }

    return const Category(categories: [], total: 0);
  }

  Map<String, dynamic> toJson() => {
    "categories": categories.map((x) => x.toJson()).toList(),
    "total": total,
  };

  @override
  String toString() {
    return "$categories, $total, ";
  }

  @override
  List<Object?> get props => [categories, total];
}
