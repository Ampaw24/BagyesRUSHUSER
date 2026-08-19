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
        final items = json["items"] as List<dynamic>? ?? [];
        final pagination = json["pagination"] as Map<String, dynamic>?;
        return AdBannerModel(
            banners: items.map((x) => Banner.fromJson(x as Map<String, dynamic>)).toList(),
            total: pagination?["total"] ?? items.length,
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

