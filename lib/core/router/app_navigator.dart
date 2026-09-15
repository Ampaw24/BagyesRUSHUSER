import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bagyesrushappusernew/src/restaurant/models/restaurant.dart';
import 'package:bagyesrushappusernew/src/report/model/report.dart';
import 'package:bagyesrushappusernew/src/report/views/report_flow_args.dart';
import 'package:bagyesrushappusernew/src/chat/view/chat_thread_args.dart';
import 'package:bagyesrushappusernew/src/chat/view/chat_thread_sheet.dart';

import 'app_routes.dart';

/// Convenience navigation helpers accessible via `AppNavigator.toHome(context)`.
///
/// These wrap GoRouter calls so screens don't need to import route constants
/// or know the routing implementation details.
abstract final class AppNavigator {
  // ── Auth ──
  static void toOnboarding(BuildContext context) =>
      context.go(AppRoutes.onboarding);
  static void toLogin(BuildContext context) => context.push(AppRoutes.login);
  static void toSignup(BuildContext context) => context.push(AppRoutes.signup);
  static void toWalkthrough(BuildContext context) =>
      context.push(AppRoutes.walkthrough);
  static void toOtp(BuildContext context) => context.push(AppRoutes.otp);
  static void toResetPassword(BuildContext context, String phone, String code) =>
      context.push(AppRoutes.resetPassword, extra: {'phone': phone, 'code': code});

  // ── Main ──
  static void toHome(BuildContext context) => context.go(AppRoutes.home);

  // ── Profile ──
  static void toProfile(BuildContext context) =>
      context.push(AppRoutes.profile);
  static void toEditProfile(BuildContext context) =>
      context.push(AppRoutes.editProfile);
  static void toCustomerPaymentMethods(BuildContext context) =>
      context.push(AppRoutes.customerPaymentMethods);

  // ── Courier ──
  static void toSendPackages(BuildContext context) =>
      context.push(AppRoutes.sendPackages);

  // ── Cart & payment ──
  static void toCart(BuildContext context) => context.push(AppRoutes.cart);
  static void toPayment(BuildContext context) =>
      context.push(AppRoutes.payment);

  // ── Orders ──
  static void toTrackOrder(BuildContext context) =>
      context.push(AppRoutes.trackOrder);

  static void toRouteMap(
    BuildContext context, {
    required double sourceLat,
    required double sourceLng,
    required double destLat,
    required double destLng,
  }) => context.push(
    AppRoutes.routeMapWith(
      sourceLat: sourceLat,
      sourceLng: sourceLng,
      destLat: destLat,
      destLng: destLng,
    ),
  );

  // ── Vendor ──
  static void toVendorHome(BuildContext context) =>
      context.go(AppRoutes.vendorHome);
  static void toVendorRegistration(BuildContext context) =>
      context.push(AppRoutes.vendorRegistration);
  static void toVendorPaymentMethods(BuildContext context) =>
      context.push(AppRoutes.vendorPaymentMethods);
  static void toVendorWallet(BuildContext context) =>
      context.push(AppRoutes.vendorWallet);

  // ── Consumer features ──
  /// Opens the vendor's menu — blocked with a notice when the vendor is
  /// currently closed, so a customer can never enter the ordering flow for
  /// a vendor that can't accept orders.
  static void toRestaurantDetail(BuildContext context, Restaurant restaurant) {
    if (!restaurant.isOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This vendor is currently closed and not accepting orders.'),
        ),
      );
      return;
    }
    context.push(AppRoutes.restaurantDetailPath(restaurant.id));
  }

  static void toCheckout(BuildContext context) =>
      context.push(AppRoutes.checkout);

  static void toConsumerSearch(BuildContext context) =>
      context.push(AppRoutes.consumerSearch);

  static void toOrderTracking(BuildContext context, String orderId) =>
      context.push(AppRoutes.trackOrder, extra: orderId);

  // ── Other ──
  static void toInviteFriend(BuildContext context) =>
      context.push(AppRoutes.inviteFriend);

  // ── Report a problem ──
  static void toReportFlow(BuildContext context, {required ReportFlowArgs args}) =>
      context.push(AppRoutes.reportFlow, extra: args);

  static void toMyReports(BuildContext context, {required ReportRole role}) =>
      context.push(AppRoutes.myReports, extra: role);

  static void toReportDetail(
    BuildContext context,
    String id, {
    required ReportRole role,
  }) =>
      context.push(AppRoutes.reportDetail(id), extra: role);

  // ── Chat ──
  /// The "active orders" inbox — a normal full-screen page.
  static void toChatList(BuildContext context) =>
      context.push(AppRoutes.chatList);

  /// Opens a conversation as a draggable bottom sheet over whatever screen
  /// is already showing (order tracking's live map, the inbox list, …)
  /// rather than navigating to a new page — see [ChatThreadSheet].
  ///
  /// Provide either [conversationId] (tapping an inbox row) or [orderId] (an
  /// order-tracking screen's "Chat" button) — the thread resolves whichever
  /// one it's given. [peerName] is an optional best-effort title shown while
  /// the real conversation is still loading; [peerPhone], when known
  /// locally, adds a native-dialer "Call" button to the sheet header.
  static void showChatThread(
    BuildContext context, {
    String? conversationId,
    String? orderId,
    String? peerName,
    String? peerPhone,
  }) =>
      ChatThreadSheet.show(
        context,
        args: ChatThreadArgs(
          conversationId: conversationId,
          orderId: orderId,
          peerName: peerName,
          peerPhone: peerPhone,
        ),
      );
}
