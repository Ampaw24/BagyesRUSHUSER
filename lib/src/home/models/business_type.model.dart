import 'package:equatable/equatable.dart';



class BusinessType extends Equatable {
    const BusinessType({
        required this.name,
        required this.description,
        required this.isActive,
        required this.displayOrder,
        required this.id,
        required this.createdAt,
        required this.updatedAt,
        required this.v,
    });

    final String name;
    final dynamic description;
    final bool isActive;
    final num displayOrder;
    final String id;
    final DateTime? createdAt;
    final DateTime? updatedAt;
    final num v;

    BusinessType copyWith({
        String? name,
        dynamic? description,
        bool? isActive,
        num? displayOrder,
        String? id,
        DateTime? createdAt,
        DateTime? updatedAt,
        num? v,
    }) {
        return BusinessType(
            name: name ?? this.name,
            description: description ?? this.description,
            isActive: isActive ?? this.isActive,
            displayOrder: displayOrder ?? this.displayOrder,
            id: id ?? this.id,
            createdAt: createdAt ?? this.createdAt,
            updatedAt: updatedAt ?? this.updatedAt,
            v: v ?? this.v,
        );
    }

    factory BusinessType.fromJson(Map<String, dynamic> json){ 
        return BusinessType(
            name: json["name"] ?? "",
            description: json["description"],
            isActive: json["is_active"] ?? false,
            displayOrder: json["display_order"] ?? 0,
            id: json["_id"] ?? "",
            createdAt: DateTime.tryParse(json["created_at"] ?? ""),
            updatedAt: DateTime.tryParse(json["updated_at"] ?? ""),
            v: json["__v"] ?? 0,
        );
    }

    Map<String, dynamic> toJson() => {
        "name": name,
        "description": description,
        "is_active": isActive,
        "display_order": displayOrder,
        "_id": id,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "__v": v,
    };

    @override
    String toString(){
        return "$name, $description, $isActive, $displayOrder, $id, $createdAt, $updatedAt, $v, ";
    }

    @override
    List<Object?> get props => [
    name, description, isActive, displayOrder, id, createdAt, updatedAt, v, ];
}
