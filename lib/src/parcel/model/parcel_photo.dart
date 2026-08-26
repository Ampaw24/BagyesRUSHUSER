import 'package:equatable/equatable.dart';

class ParcelPhoto extends Equatable {
  const ParcelPhoto({
    required this.id,
    required this.url,
  });

  final int id;
  final String? url;

  factory ParcelPhoto.fromJson(Map<String, dynamic> json) {
    return ParcelPhoto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      url: (json['url'] ?? json['path'] ?? json['photo_url'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
      };

  @override
  String toString() => '$id, $url';

  @override
  List<Object?> get props => [id, url];
}
