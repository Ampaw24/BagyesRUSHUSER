import 'dart:async';
import 'dart:math' as math;

import 'package:bagyesrushappusernew/constant/constant.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../core/common/app/current_user_provider.dart';
import '../core/services/fcm_service.dart';
import '../core/widgets/app_logo_card.dart';
import '../core/widgets/decorative_background.dart';
import '../src/auth/repositories/auth_repository.dart';
import '../src/auth/viewmodels/auth_viewmodel.dart';
import '../src/auth/viewmodels/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  String? _versionLabel;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadVersion();
    _navigateToNextScreen();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _versionLabel = 'v${info.version}');
    } catch (_) {
      // Non-critical: the version label simply stays hidden if unavailable.
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    final authState = context.read<AuthViewmodel>().state;
    final currentUser = context.read<CurrentUserProvider>();

    if (!mounted) return;

    if (authState is LoggedIn) {
      // Primary: use the role held in memory by CurrentUserProvider.
      // Fallback: read directly from secure storage in case a background
      // profile-fetch race cleared the in-memory role before we got here.
      String role = currentUser.user?.role ?? '';
      if (role.isEmpty) {
        role = await GetIt.instance<AuthRepository>().getCachedUserRole() ?? '';
      }

      if (!mounted) return;

      if (role == 'vendor') {
        context.go(AppRoutes.vendorHome);
      } else {
        context.go(AppRoutes.home);
        // Cold-launched by tapping an order-related push (see
        // FcmService.pendingOrderId) — consume once, then land on tracking
        // on top of the home screen we just routed to.
        final orderId = FcmService.pendingOrderId;
        if (orderId != null) {
          FcmService.pendingOrderId = null;
          if (mounted) context.push(AppRoutes.trackOrder, extra: orderId);
        }
      }
    } else if (authState is AuthError) {
      // Token existed but was expired/invalid → go straight to login
      context.go(AppRoutes.login);
    } else {
      // LoggedOut → no stored token → go through onboarding
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDecorativeBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // Card is clamped so it stays comfortable on both small phones
          // and large tablets, while still scaling with the viewport.
          final cardSize = (math.min(width, height) * 0.34).clamp(120.0, 260.0);
          final loaderWidth = (width * 0.32).clamp(96.0, 220.0);

          return DecorativeBackground(
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: AppLogoCard(size: cardSize),
                    ),
                  ),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: Container(
                        width: 40,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 18,
                        left: 24,
                        right: 24,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'FAST · RELIABLE · QUALITY',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            color: greyColor.withValues(alpha: 0.8),
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 6),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: loaderWidth,
                      height: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 20),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        _versionLabel ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: greyColor.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


