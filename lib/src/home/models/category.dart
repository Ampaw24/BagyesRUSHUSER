import 'package:bagyesrushappusernew/src/home/models/category_element.model.dart';
import 'package:equatable/equatable.dart';


class Category extends Equatable {
    const Category({
        required this.categories,
        required this.total,
    });

    final List<CategoryElement> categories;
    final num total;

    Category copyWith({
        List<CategoryElement>? categories,
        num? total,
    }) {
        return Category(
            categories: categories ?? this.categories,
            total: total ?? this.total,
        );
    }

    factory Category.fromJson(Map<String, dynamic> json){ 
        return Category(
            categories: json["categories"] == null ? [] : List<CategoryElement>.from(json["categories"]!.map((x) => CategoryElement.fromJson(x))),
            total: json["total"] ?? 0,
        );
    }

    Map<String, dynamic> toJson() => {
        "categories": categories.map((x) => x.toJson()).toList(),
        "total": total,
    };

    @override
    String toString(){
        return "$categories, $total, ";
    }

    @override
    List<Object?> get props => [
    categories, total, ];
}

