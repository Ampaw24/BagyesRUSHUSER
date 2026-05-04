import 'package:equatable/equatable.dart';

class Banner extends Equatable {
   const  Banner({
        required this.id,
        required this.type,
        required this.title,
        required this.subtitle,
        required this.imageUrl,
        required this.backgroundColor,
        required this.textColor,
        required this.ctaLabel,
        required this.actionType,
        required this.actionTarget,
        required this.priority,
        required this.startsAt,
        required this.endsAt,
        required this.isActive,
        required this.createdBy,
        required this.createdAt,
        required this.updatedAt,
        required this.v,
    });

    final String id;
    final String type;
    final String title;
    final String subtitle;
    final String imageUrl;
    final String backgroundColor;
    final String textColor;
    final String ctaLabel;
    final String actionType;
    final String actionTarget;
    final num priority;
    final DateTime? startsAt;
    final DateTime? endsAt;
    final bool isActive;
    final String createdBy;
    final DateTime? createdAt;
    final DateTime? updatedAt;
    final num v;

    Banner copyWith({
        String? id,
        String? type,
        String? title,
        String? subtitle,
        String? imageUrl,
        String? backgroundColor,
        String? textColor,
        String? ctaLabel,
        String? actionType,
        String? actionTarget,
        num? priority,
        DateTime? startsAt,
        DateTime? endsAt,
        bool? isActive,
        String? createdBy,
        DateTime? createdAt,
        DateTime? updatedAt,
        num? v,
    }) {
        return Banner(
            id: id ?? this.id,
            type: type ?? this.type,
            title: title ?? this.title,
            subtitle: subtitle ?? this.subtitle,
            imageUrl: imageUrl ?? this.imageUrl,
            backgroundColor: backgroundColor ?? this.backgroundColor,
            textColor: textColor ?? this.textColor,
            ctaLabel: ctaLabel ?? this.ctaLabel,
            actionType: actionType ?? this.actionType,
            actionTarget: actionTarget ?? this.actionTarget,
            priority: priority ?? this.priority,
            startsAt: startsAt ?? this.startsAt,
            endsAt: endsAt ?? this.endsAt,
            isActive: isActive ?? this.isActive,
            createdBy: createdBy ?? this.createdBy,
            createdAt: createdAt ?? this.createdAt,
            updatedAt: updatedAt ?? this.updatedAt,
            v: v ?? this.v,
        );
    }

    factory Banner.fromJson(Map<String, dynamic> json){ 
        return Banner(
            id: json["_id"] ?? "",
            type: json["type"] ?? "",
            title: json["title"] ?? "",
            subtitle: json["subtitle"] ?? "",
            imageUrl: json["image_url"] ?? "",
            backgroundColor: json["background_color"] ?? "",
            textColor: json["text_color"] ?? "",
            ctaLabel: json["cta_label"] ?? "",
            actionType: json["action_type"] ?? "",
            actionTarget: json["action_target"] ?? "",
            priority: json["priority"] ?? 0,
            startsAt: DateTime.tryParse(json["starts_at"] ?? ""),
            endsAt: DateTime.tryParse(json["ends_at"] ?? ""),
            isActive: json["is_active"] ?? false,
            createdBy: json["created_by"] ?? "",
            createdAt: DateTime.tryParse(json["created_at"] ?? ""),
            updatedAt: DateTime.tryParse(json["updated_at"] ?? ""),
            v: json["__v"] ?? 0,
        );
    }

    Map<String, dynamic> toJson() => {
        "_id": id,
        "type": type,
        "title": title,
        "subtitle": subtitle,
        "image_url": imageUrl,
        "background_color": backgroundColor,
        "text_color": textColor,
        "cta_label": ctaLabel,
        "action_type": actionType,
        "action_target": actionTarget,
        "priority": priority,
        "starts_at": startsAt?.toIso8601String(),
        "ends_at": endsAt?.toIso8601String(),
        "is_active": isActive,
        "created_by": createdBy,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "__v": v,
    };

    @override
    String toString(){
        return "$id, $type, $title, $subtitle, $imageUrl, $backgroundColor, $textColor, $ctaLabel, $actionType, $actionTarget, $priority, $startsAt, $endsAt, $isActive, $createdBy, $createdAt, $updatedAt, $v, ";
    }

    @override
    List<Object?> get props => [
    id, type, title, subtitle, imageUrl, backgroundColor, textColor, ctaLabel, actionType, actionTarget, priority, startsAt, endsAt, isActive, createdBy, createdAt, updatedAt, v, ];
}
