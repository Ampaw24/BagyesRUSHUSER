import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../constant/app_theme.dart';
import '../../core/common/app/current_user_provider.dart';
import '../../core/router/app_navigator.dart';
import '../../core/router/app_routes.dart';
import 'package:bagyesrushappusernew/src/legal/models/legal_document.dart';
import '../../src/auth/viewmodels/auth_viewmodel.dart';
import '../../src/auth/views/auth_gate.dart';
import '../../src/auth/views/widgets/guest_prompt.dart';
import '../../src/notification/viewmodel/notification_viewmodel.dart';
import '../../states/app.state.dart';
import '../../services/auth.service.dart';
import '../../core/widgets/custom_dialogs.dart';
import '../../features/parcel/presentation/widgets/parcel_direction_sheet.dart';
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

  VoidCallback? _stopSignInListener;

  @override
  void initState() {
    super.initState();
    _stopSignInListener = context
        .read<CurrentUserProvider>()
        .addSignInListener(_onSignInChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Device token registration happens earlier now — at login success
      // (AuthViewmodel.login) or at app launch for a restored session
      // (AppInitializer) — rather than here. A guest has no notifications;
      // NotificationViewmodel fetches the badge itself if they sign in.
      if (AuthGate.isSignedIn(context)) {
        context.read<NotificationViewmodel>().getUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    _stopSignInListener?.call();
    super.dispose();
  }

  /// A session ending while this shell stays up (an expired token) drops
  /// to guest mode — reset to the Home tab.
  void _onSignInChanged(bool signedIn) {
    if (signedIn) return;
    setState(() {
      _navIndex = 0;
      _drawerOpen = false;
    });
  }

  /// Closes the drawer, then opens an account-only screen — asking a guest
  /// to sign in first.
  void _openForAccount(String reason, VoidCallback open) {
    _closeDrawer();
    AuthGate.requireAuth(context, reason: reason, action: open);
  }

  void _signInFromDrawer() {
    _closeDrawer();
    AppNavigator.toLoginForResult(context);
  }

  void _openDrawer() => setState(() => _drawerOpen = true);
  void _closeDrawer() => setState(() => _drawerOpen = false);

  void _openLegal(LegalDocument document) {
    _closeDrawer();
    AppNavigator.toLegal(context, document);
  }

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

        context.go(AppRoutes.onboarding);
      },
    );
  }

  void _showDeleteAccountDialog() {
    _closeDrawer();
    CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Account',
      subtitle:
          'This action is permanent and cannot be undone. '
          'All your order history and personal data will be permanently deleted.',
      confirmText: 'Continue',
      cancelText: 'Cancel',
      onConfirm: () => context.push(AppRoutes.deleteAccount),
    );
  }

  void _showReportProblem() => _openForAccount(
    'Sign in to report a problem with an order.',
    () => AppNavigator.toMyReports(context, role: ReportRole.customer),
  );

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CurrentUserProvider>();
    final user = session.user;
    // A vendor only passes through here while the router moves them to
    // vendor home (e.g. signing in over this screen) — treat them as a
    // guest so no customer-only API is called with their token.
    final isSignedIn = session.isAuthenticated && !(user?.isVendor ?? false);
    final profile = user?.customerProfile;
    final firstName = profile?.firstName ?? '';
    final lastName = profile?.lastName ?? '';
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    final initials =
        '${firstName.isNotEmpty ? firstName[0].toUpperCase() : ''}'
        '${lastName.isNotEmpty ? lastName[0].toUpperCase() : ''}';
    final email = user?.email ?? '';
    final isVerified = user?.phoneVerified ?? false;
    final avatarUrl = profile?.profilePictureUrl;

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
                  isSignedIn
                      ? const ConsumerOrdersView()
                      : const _GuestOrdersTab(),
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
                    AuthGate.requireAuth(
                      context,
                      reason: 'Sign in to send or receive packages.',
                      action: () => showParcelDirectionSheet(context),
                    );
                    return;
                  }
                  setState(() => _navIndex = i);
                },
                items: _navItems,
              ),
            ),
            if (_drawerOpen)
              CustomerDrawer(
                userName: isSignedIn
                    ? (fullName.isNotEmpty ? fullName : 'User')
                    : 'Guest',
                userEmail: isSignedIn ? email : 'Sign in to order and track',
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
                onNotifications: () => _openForAccount(
                  'Sign in to see your notifications.',
                  () => context.push(AppRoutes.notifications),
                ),
                onTransactions: () => _openForAccount(
                  'Sign in to see your transactions.',
                  () => context.push(AppRoutes.wallet),
                ),
                onPaymentMethods: () => _openForAccount(
                  'Sign in to manage your payment methods.',
                  () => context.push(AppRoutes.customerPaymentMethods),
                ),
                onInviteFriends: () => _openForAccount(
                  'Sign in to get your referral code.',
                  () => AppNavigator.toInviteFriend(context),
                ),
                onPrivacyPolicy: () => _openLegal(LegalDocument.privacyPolicy),
                onTermsConditions: () =>
                    _openLegal(LegalDocument.termsConditions),
                onRefundPolicy: () => _openLegal(LegalDocument.refundPolicy),
                onHelpSupport: () {
                  _closeDrawer();
                  context.push(AppRoutes.helpSupport);
                },
                onReportProblem: _showReportProblem,
                onDeleteAccount: isSignedIn ? _showDeleteAccountDialog : null,
                onLogout: isSignedIn ? _handleLogout : null,
                onSignIn: isSignedIn ? null : _signInFromDrawer,
              ),
          ],
        ),
      ),
    );
  }
}

/// Orders tab for a guest: there's no order history without an account.
class _GuestOrdersTab extends StatelessWidget {
  const _GuestOrdersTab();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final horizontalPadding = w > 600 ? w * 0.2 : w * 0.08;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Orders'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            w * 0.04,
            horizontalPadding,
            FloatingNavBar.reservedHeight(context),
          ),
          child: GuestPrompt(
            icon: HugeIcons.strokeRoundedDeliveryBox01,
            title: 'Sign in to view your orders',
            message: 'Track live deliveries and see your order history '
                'once you sign in.',
            onSignIn: () => AppNavigator.toLoginForResult(context),
            onCreateAccount: () => AppNavigator.toCreateAccount(context),
          ),
        ),
      ),
    );
  }
}
