import 'package:equatable/equatable.dart';

class CategoryElement extends Equatable {
  const CategoryElement({
    required this.id,
    required this.name,
    required this.description,
    required this.imageKey,
    required this.imageUrl,
    required this.isActive,
    required this.displayOrder,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  final String id;
  final String name;
  final String description;
  final String imageKey;
  final String imageUrl;
  final bool isActive;
  final num displayOrder;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final num v;

  CategoryElement copyWith({
    String? id,
    String? name,
    String? description,
    String? imageKey,
    String? imageUrl,
    bool? isActive,
    num? displayOrder,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    num? v,
  }) {
    return CategoryElement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageKey: imageKey ?? this.imageKey,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }

  factory CategoryElement.fromJson(Map<String, dynamic> json) {
    return CategoryElement(
      id: (json["id"] ?? json["_id"])?.toString() ?? "",
      name: json["name"] ?? "",
      description: json["description"] ?? "",
      imageKey: json["image_key"] ?? "",
      imageUrl: json["image_url"] ?? "",
      isActive: json["is_active"] ?? false,
      displayOrder: json["display_order"] ?? 0,
      createdBy: json["created_by"] ?? "",
      createdAt: DateTime.tryParse(json["created_at"] ?? ""),
      updatedAt: DateTime.tryParse(json["updated_at"] ?? ""),
      v: json["__v"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "description": description,
    "image_key": imageKey,
    "image_url": imageUrl,
    "is_active": isActive,
    "display_order": displayOrder,
    "created_by": createdBy,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "__v": v,
  };

  @override
  String toString() {
    return "$id, $name, $description, $imageKey, $imageUrl, $isActive, $displayOrder, $createdBy, $createdAt, $updatedAt, $v, ";
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    imageKey,
    imageUrl,
    isActive,
    displayOrder,
    createdBy,
    createdAt,
    updatedAt,
    v,
  ];
}
