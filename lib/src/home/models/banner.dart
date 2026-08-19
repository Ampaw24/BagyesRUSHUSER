import 'package:equatable/equatable.dart';

class BannerLink extends Equatable {
  const BannerLink({required this.type, this.value});

  final String type;
  final String? value;

  factory BannerLink.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BannerLink(type: 'none');
    return BannerLink(
      type: json['type'] ?? 'none',
      value: json['value']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'value': value,
      };

  @override
  List<Object?> get props => [type, value];
}

class Banner extends Equatable {
  const Banner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
    required this.placement,
    required this.displayOrder,
    required this.link,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final String placement;
  final num displayOrder;
  final BannerLink link;

  Banner copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? imageUrl,
    String? placement,
    num? displayOrder,
    BannerLink? link,
  }) {
    return Banner(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      placement: placement ?? this.placement,
      displayOrder: displayOrder ?? this.displayOrder,
      link: link ?? this.link,
    );
  }

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      placement: json['placement'] ?? '',
      displayOrder: json['display_order'] ?? 0,
      link: BannerLink.fromJson(json['link'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'image_url': imageUrl,
        'placement': placement,
        'display_order': displayOrder,
        'link': link.toJson(),
      };

  @override
  String toString() {
    return '$id, $title, $subtitle, $description, $imageUrl, $placement, $displayOrder, $link';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        description,
        imageUrl,
        placement,
        displayOrder,
        link,
      ];
}
