import 'package:equatable/equatable.dart';

import 'banner.dart';


class AdBannerModel extends Equatable {
    const AdBannerModel({
        required this.banners,
        required this.total,
    });

    final List<Banner> banners;
    final num total;

    AdBannerModel copyWith({
        List<Banner>? banners,
        num? total,
    }) {
        return AdBannerModel(
            banners: banners ?? this.banners,
            total: total ?? this.total,
        );
    }

    factory AdBannerModel.fromJson(Map<String, dynamic> json){ 
        return AdBannerModel(
            banners: json["banners"] == null ? [] : List<Banner>.from(json["banners"]!.map((x) => Banner.fromJson(x))),
            total: json["total"] ?? 0,
        );
    }

    Map<String, dynamic> toJson() => {
        "banners": banners.map((x) => x.toJson()).toList(),
        "total": total,
    };

    @override
    String toString(){
        return "$banners, $total, ";
    }

    @override
    List<Object?> get props => [
    banners, total, ];
}

