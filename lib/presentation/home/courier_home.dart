import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../constant/app_theme.dart';
import '../../core/common/app/current_user_provider.dart';
import '../../core/router/app_navigator.dart';
import '../../core/router/app_routes.dart';
import '../../src/auth/viewmodels/auth_viewmodel.dart';
import '../../states/app.state.dart';
import '../../services/auth.service.dart';
import '../../core/widgets/custom_dialogs.dart';
import '../../src/vendor/view/widgets/floating_nav_bar.dart';
import '../../features/consumer/orders/presentation/views/consumer_orders_view.dart';
import '../../features/consumer/search/presentation/views/consumer_search_view.dart';
import '../../features/consumer/profile/presentation/views/consumer_profile_view.dart';
import 'widgets/home_discovery_tab.dart';
import 'widgets/customer_drawer.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  int _navIndex = 0;
  bool _drawerOpen = false;

  static const _navItems = [
    NavItem(icon: HugeIcons.strokeRoundedHome11, label: 'Home'),
    NavItem(icon: HugeIcons.strokeRoundedDeliveryBox01, label: 'Orders'),
    NavItem(icon: HugeIcons.strokeRoundedSearch01, label: 'Search'),
    NavItem(icon: HugeIcons.strokeRoundedUser, label: 'Profile'),
  ];

  void _openDrawer() => setState(() => _drawerOpen = true);
  void _closeDrawer() => setState(() => _drawerOpen = false);

  void _handleLogout() {
    _closeDrawer();
    CustomDialog.showConfirmation(
      context: context,
      title: 'Logout',
      subtitle: 'Are you sure you want to log out?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      onConfirm: () async {
        if (!mounted) return;

        await context.read<AuthViewmodel>().logout();

        if (!mounted) return;

        final appState = context.read<AppState>();
        appState.setUser(IUser());
        appState.setPayload(ISignup());

        context.go(AppRoutes.login);
      },
    );
  }

  void _showDeleteAccountDialog() {
    _closeDrawer();
    final w = MediaQuery.sizeOf(context).width;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(w * 0.05),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.025),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(w * 0.025),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: w * 0.06,
              ),
            ),
            SizedBox(width: w * 0.03),
            const Expanded(child: Text('Delete Account')),
          ],
        ),
        titleTextStyle: TextStyle(
          fontSize: w * 0.045,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontFamily: 'Mukta',
        ),
        content: Text(
          'This action is permanent and cannot be undone. '
          'All your order history and personal data will be permanently deleted.',
          style: TextStyle(
            fontSize: w * 0.034,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: w * 0.036,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Delete',
              style: TextStyle(
                fontSize: w * 0.036,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<CurrentUserProvider>().user;
    final firstName = user?.profile?.firstName ?? '';
    final lastName = user?.profile?.lastName ?? '';
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    final initials =
        '${firstName.isNotEmpty ? firstName[0].toUpperCase() : ''}'
        '${lastName.isNotEmpty ? lastName[0].toUpperCase() : ''}';
    final email = user?.email ?? '';
    final isVerified = user?.phoneVerified ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _navIndex,
                children: [
                  HomeDiscoveryTab(onDrawerTap: _openDrawer),
                  const ConsumerOrdersView(),
                  const ConsumerSearchView(),
                  const ConsumerProfileView(),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FloatingNavBar(
                currentIndex: _navIndex,
                onTap: (i) => setState(() => _navIndex = i),
                items: _navItems,
              ),
            ),
            if (_drawerOpen)
              CustomerDrawer(
                userName: fullName.isNotEmpty ? fullName : 'User',
                userEmail: email,
                initials: initials.isNotEmpty ? initials : 'U',
                isVerified: isVerified,
                onClose: _closeDrawer,
                onProfile: () {
                  _closeDrawer();
                  setState(() => _navIndex = 3);
                },
                onOrders: () {
                  _closeDrawer();
                  setState(() => _navIndex = 1);
                },
                onNotifications: () {
                  _closeDrawer();
                  context.push(AppRoutes.notifications);
                },
                onWallet: () {
                  _closeDrawer();
                  context.push(AppRoutes.wallet);
                },
                onPaymentMethods: () {
                  _closeDrawer();
                  context.push(AppRoutes.vendorPaymentMethods);
                },
                onInviteFriends: () {
                  _closeDrawer();
                  AppNavigator.toInviteFriend(context);
                },
                onPrivacyPolicy: () => _closeDrawer(),
                onHelpSupport: () => _closeDrawer(),
                onDeleteAccount: _showDeleteAccountDialog,
                onLogout: _handleLogout,
              ),
          ],
        ),
      ),
    );
  }
}
