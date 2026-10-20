import 'dart:async';
import 'package:gopady/constant/app_theme.dart';
import 'package:gopady/constant/app_tokens.dart';
import 'package:gopady/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../core/common/app/current_user_provider.dart';
import '../resources/resources.dart';
import '../core/services/fcm_service.dart';
import '../core/widgets/brand_pattern_background.dart';
import '../core/widgets/gopady_logo.dart';
import '../core/widgets/skyline_watermark.dart';
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
  /// The intro animation plus a brief hold.
  static const _minimumDisplay = Duration(seconds: 2);
  static const _maxValidationWait = Duration(seconds: 4);
  static const _maxPrecacheWait = Duration(seconds: 1);

  late AnimationController _animationController;
  final Completer<void> _introFinished = Completer<void>();
  bool _introStarted = false;

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
      duration: AppMotion.intro,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_introStarted) return;
    _introStarted = true;
    _playIntro();
  }

  /// Decodes the artwork first so the intro never starts on an empty frame
  /// (an image that decodes mid-animation would just pop in).
  Future<void> _playIntro() async {
    try {
      await Future.wait([
        precacheImage(
          const AssetImage(BrandAssets.gopadyLogoTransparentWhite),
          context,
        ),
        precacheImage(const AssetImage(BrandAssets.gopadyIconYellow), context),
        precacheImage(const AssetImage(IconAssets.rebrandFilter), context),
      ]).timeout(_maxPrecacheWait);
    } catch (_) {
      // Best effort: play the intro even if an asset is slow to decode.
    }
    if (!mounted) return;
    await _animationController.forward().orCancel.catchError((_) {});
    if (!_introFinished.isCompleted) _introFinished.complete();
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
    if (!_introFinished.isCompleted) _introFinished.complete();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    final authViewmodel = context.read<AuthViewmodel>();

    // Show the branded splash for its animation plus a short hold, and wait
    // (bounded) for the launch-time session validation kicked off by
    // `restoreSession()` — its outcome may correct `authState` from LoggedIn
    // to LoggedOut before we read it below, so a rejected token never gets
    // routed to Home. If validation is slow we route on the cached session
    // and let it finish in the background (an unreachable backend never
    // logs the user out; a 401 later does, via the router).
    await Future.wait([
      Future.delayed(_minimumDisplay),
      _introFinished.future,
      authViewmodel.sessionValidation.timeout(
        _maxValidationWait,
        onTimeout: () {},
      ),
    ]);

    if (!mounted) return;

    final authState = authViewmodel.state;
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
      backgroundColor: AppColors.primary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          // Everything scales off the shorter side so portrait, landscape and
          // split-screen all keep the same proportions.
          final unit = size.shortestSide;

          return Stack(
            children: [
              Positioned.fill(
                child: BrandReveal(
                  animation: _animationController,
                  end: 0.5,
                  child: const BrandPatternBackground(),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: BrandReveal(
                  animation: _animationController,
                  begin: 0.1,
                  end: 0.65,
                  slideFrom: const Offset(0, 0.25),
                  child: const SkylineWatermark(color: AppColors.primaryDark),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandReveal(
                        animation: _animationController,
                        begin: 0.2,
                        end: 0.8,
                        scaleFrom: 0.9,
                        slideFrom: const Offset(0, 0.08),
                        blurFrom: unit * 0.025,
                        child: GoPadyLogo(
                          width: unit * 0.72,
                          variant: GoPadyLogoVariant.onDark,
                        ),
                      ),
                      SizedBox(height: unit * 0.1),
                      BrandReveal(
                        animation: _animationController,
                        begin: 0.7,
                        end: 1,
                        child: SizedBox(
                          width: unit * 0.3,
                          height: unit * 0.008,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(unit * 0.004),
                            child: const LinearProgressIndicator(
                              backgroundColor: AppColors.primaryDark,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // SizedBox(height: unit * 0.04),
                      // Text(
                      //   _versionLabel ?? '',
                      //   style: TextStyle(
                      //     fontSize: unit * 0.03,
                      //     color: AppColors.onDarkMuted,
                      //     letterSpacing: unit * 0.001,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
