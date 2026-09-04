import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../constant/app_theme.dart';
import '../../core/common/app/current_user_provider.dart';
import '../../core/router/app_navigator.dart';
import '../../core/router/app_routes.dart';
import '../../src/auth/viewmodels/auth_viewmodel.dart';
import '../../src/notification/viewmodel/notification_viewmodel.dart';
import '../../states/app.state.dart';
import '../../services/auth.service.dart';
import '../../core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/src/report/model/report.dart';
import '../../src/vendor/view/widgets/floating_nav_bar.dart';
import '../../src/consumer_orders/views/consumer_orders_view.dart';
import '../profile/profile.dart';
import 'widgets/home_discovery_tab.dart';
import 'widgets/customer_drawer.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _navIndex = 0;
  bool _drawerOpen = false;

  static const _navItems = [
    NavItem(icon: HugeIcons.strokeRoundedHome11, label: 'Home'),
    NavItem(icon: HugeIcons.strokeRoundedDeliveryBox01, label: 'Orders'),
    NavItem(icon: HugeIcons.strokeRoundedPackage, label: 'Send Package'),
    NavItem(icon: HugeIcons.strokeRoundedUser, label: 'Profile'),
  ];

  // Index into _navItems that triggers the send-package flow instead of
  // switching tabs — it has no corresponding page in the IndexedStack.
  static const _sendPackageNavIndex = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Device token registration happens earlier now — at login success
      // (AuthViewmodel.login) or at app launch for a restored session
      // (AppInitializer) — rather than here.
      context.read<NotificationViewmodel>().getUnreadCount();
    });
  }

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
    CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Account',
      subtitle: 'This action is permanent and cannot be undone. '
          'All your order history and personal data will be permanently deleted.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      onConfirm: () {},
    );
  }

  void _showReportProblem() {
    _closeDrawer();
    AppNavigator.toMyReports(context, role: ReportRole.customer);
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
    final avatarUrl = user?.profile?.profilePictureUrl;

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
                index: _navIndex > _sendPackageNavIndex
                    ? _navIndex - 1
                    : _navIndex,
                children: [
                  HomeDiscoveryTab(onDrawerTap: _openDrawer),
                  const ConsumerOrdersView(),
                  const Profile(),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FloatingNavBar(
                currentIndex: _navIndex,
                onTap: (i) {
                  if (i == _sendPackageNavIndex) {
                    AppNavigator.toSendPackages(context);
                    return;
                  }
                  setState(() => _navIndex = i);
                },
                items: _navItems,
              ),
            ),
            if (_drawerOpen)
              CustomerDrawer(
                userName: fullName.isNotEmpty ? fullName : 'User',
                userEmail: email,
                initials: initials.isNotEmpty ? initials : 'U',
                isVerified: isVerified,
                avatarUrl: avatarUrl,
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
                onTransactions: () {
                  _closeDrawer();
                  context.push(AppRoutes.wallet);
                },
                onPaymentMethods: () {
                  _closeDrawer();
                  context.push(AppRoutes.customerPaymentMethods);
                },
                onInviteFriends: () {
                  _closeDrawer();
                  AppNavigator.toInviteFriend(context);
                },
                onPrivacyPolicy: () => _closeDrawer(),
                onHelpSupport: () {
                  _closeDrawer();
                  context.push(AppRoutes.helpSupport);
                },
                onReportProblem: _showReportProblem,
                onDeleteAccount: _showDeleteAccountDialog,
                onLogout: _handleLogout,
              ),
          ],
        ),
      ),
    );
  }
}
