import 'package:bagyesrushappusernew/src/home/models/business_type.model.dart';
import 'package:equatable/equatable.dart';

class BusinessTypesModel extends Equatable {
   const BusinessTypesModel({
        required this.data,
    });

    final List<BusinessType> data;

    BusinessTypesModel copyWith({
        List<BusinessType>? data,
    }) {
        return BusinessTypesModel(
            data: data ?? this.data,
        );
    }

    factory BusinessTypesModel.fromJson(Map<String, dynamic> json){ 
        return BusinessTypesModel(
            data: json["data"] == null ? [] : List<BusinessType>.from(json["data"]!.map((x) => BusinessType.fromJson(x))),
        );
    }

    Map<String, dynamic> toJson() => {
        "data": data.map((x) => x.toJson()).toList(),
    };

    @override
    String toString(){
        return "$data, ";
    }

    @override
    List<Object?> get props => [
    data, ];
}

