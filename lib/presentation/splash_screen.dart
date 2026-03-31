import 'dart:async';
import 'package:bagyesrushappusernew/constant/constant.dart';
import 'package:bagyesrushappusernew/constant/image_constants.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/common/app/current_user_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _setupAnimations();
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
      // Route by role
      final role = currentUser.user?.role ?? '';
      if (role == 'vendor') {
        context.go(AppRoutes.vendorHome);
      } else {
        context.go(AppRoutes.home);
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
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.35; // Responsive logo size

    return Scaffold(
      backgroundColor: whiteBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  AssetImages.bagyesLogo,
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            SizedBox(height: size.height * 0.03),

            // Animated App Name
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'bagyesRUSH',
                    style: TextStyle(
                      fontSize: size.width * 0.08,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 2,
                      fontFamily:
                          'Pacifico', // Using the unique font from constants
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Text(
                    'FAST • RELIABLE • QUALITY',
                    style: TextStyle(
                      fontSize: size.width * 0.03,
                      color: Colors.grey[400],
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: size.height * 0.08),

            // Modern Loader
            FadeTransition(
              opacity: _fadeAnimation,
              child: const SizedBox(
                height: 40,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
