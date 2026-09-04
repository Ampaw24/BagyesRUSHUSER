import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constant/app_theme.dart';
import '../../../core/router/app_routes.dart';
import '../../../src/home/viewmodel/home_discovery_viewmodel.dart';

class BannerItem {
  final String? imagePath;
  final String? title;
  final String? subtitle;
  final String actionType;
  final String actionTarget;

  const BannerItem({
    this.imagePath,
    this.title,
    this.subtitle,
    this.actionType = '',
    this.actionTarget = '',
  });
}

class PromoBannerSection extends StatelessWidget {
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const PromoBannerSection({
    super.key,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final state = context.watch<HomeDiscoveryViewModel>().state;

    switch (state.bannersStatus) {
      case BannersStatus.loading:
        return Container(
          margin: EdgeInsets.symmetric(horizontal: w * 0.05),
          height: w * 0.45,
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(w * 0.045),
          ),
        );
      case BannersStatus.error:
        return const SizedBox.shrink();
      case BannersStatus.loaded:
        final adModel = state.banners;
        final homeBanners = (adModel?.banners ?? const [])
            .where((b) => b.placement == 'home')
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        final banners = homeBanners.map(
          (b) => BannerItem(
            imagePath: b.imageUrl,
            title: b.title,
            subtitle: (b.subtitle?.isNotEmpty ?? false)
                ? b.subtitle
                : b.description,
            actionType: b.link.type,
            actionTarget: b.link.value ?? '',
          ),
        ).toList();

        if (banners.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            SizedBox(
              height: w * 0.48,
              child: PageView.builder(
                controller: controller,
                onPageChanged: onPageChanged,
                itemCount: banners.length,
                itemBuilder: (ctx, i) {
                  final banner = banners[i];
                  return GestureDetector(
                    onTap: () {
                      if (banner.actionType == 'restaurant' &&
                          banner.actionTarget.isNotEmpty) {
                        context.push(
                          AppRoutes.restaurantDetailPath(banner.actionTarget),
                        );
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: w * 0.05),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(w * 0.045),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(w * 0.045),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (banner.imagePath != null &&
                                banner.imagePath!.isNotEmpty)
                              Image.network(
                                banner.imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primary,
                                        AppColors.secondary,
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary,
                                    ],
                                  ),
                                ),
                              ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xB3000000),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            if (banner.title != null)
                              Positioned(
                                bottom: w * 0.045,
                                left: w * 0.045,
                                right: w * 0.045,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      banner.title!,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: w * 0.05,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (banner.subtitle != null)
                                      Text(
                                        banner.subtitle!,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                          fontSize: w * 0.03,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: w * 0.025),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: w * 0.008),
                  width: i == currentIndex ? w * 0.05 : w * 0.02,
                  height: w * 0.018,
                  decoration: BoxDecoration(
                    color: i == currentIndex
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}
