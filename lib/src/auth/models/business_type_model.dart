import 'package:equatable/equatable.dart';



class BusinessTypeModel extends Equatable {
    const BusinessTypeModel({
        required this.id,
        required this.name,
        required this.description,
        required this.isActive,
        required this.displayOrder,
        required this.createdAt,
        required this.updatedAt,
        required this.v,
    });

    final String id;
    final String name;
    final dynamic description;
    final bool isActive;
    final num displayOrder;
    final DateTime? createdAt;
    final DateTime? updatedAt;
    final num v;

    BusinessTypeModel copyWith({
        String? id,
        String? name,
        dynamic description,
        bool? isActive,
        num? displayOrder,
        DateTime? createdAt,
        DateTime? updatedAt,
        num? v,
    }) {
        return BusinessTypeModel(
            id: id ?? this.id,
            name: name ?? this.name,
            description: description ?? this.description,
            isActive: isActive ?? this.isActive,
            displayOrder: displayOrder ?? this.displayOrder,
            createdAt: createdAt ?? this.createdAt,
            updatedAt: updatedAt ?? this.updatedAt,
            v: v ?? this.v,
        );
    }

    factory BusinessTypeModel.fromJson(Map<String, dynamic> json){ 
        return BusinessTypeModel(
            id: (json["_id"] ?? json["id"])?.toString() ?? "",
            name: json["name"] ?? "",
            description: json["description"],
            isActive: json["is_active"] ?? false,
            displayOrder: json["display_order"] ?? 0,
            createdAt: DateTime.tryParse(json["created_at"] ?? ""),
            updatedAt: DateTime.tryParse(json["updated_at"] ?? ""),
            v: json["__v"] ?? 0,
        );
    }

    Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "description": description,
        "is_active": isActive,
        "display_order": displayOrder,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "__v": v,
    };

    @override
    String toString(){
        return "$id, $name, $description, $isActive, $displayOrder, $createdAt, $updatedAt, $v, ";
    }

    @override
    List<Object?> get props => [
    id, name, description, isActive, displayOrder, createdAt, updatedAt, v, ];
}
