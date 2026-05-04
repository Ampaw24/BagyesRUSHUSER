import 'package:equatable/equatable.dart';

class ApiCategory extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? iconUrl;

  const ApiCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
  });

  factory ApiCategory.fromJson(Map<String, dynamic> json) {
    return ApiCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      iconUrl: json['icon_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'icon_url': iconUrl,
      };

  @override
  List<Object?> get props => [id, name, slug, iconUrl];
}
