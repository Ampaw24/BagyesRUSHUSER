import 'package:bagyesrushappusernew/constant/constant.dart';
import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/core/router/router.dart';
import 'package:bagyesrushappusernew/services/auth.service.dart';
import 'package:bagyesrushappusernew/src/auth/models/user.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';
import 'package:bagyesrushappusernew/states/app.state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../src/notification/viewmodel/notification_viewmodel.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Reference unit scales every spacing/size below relative to screen
    // width (10.0 at a 375-wide phone, the size this layout was designed
    // against) instead of hardcoding pixel values — clamped so spacing
    // doesn't balloon on tablets or shrink too far on small phones.
    final unit = (width / 37.5).clamp(8.0, 14.0);

    // Watch (not read) so the avatar/name refresh immediately when
    // EditProfile's save or avatar upload updates CurrentUserProvider —
    // no need to leave and re-enter this screen to see the change.
    final user = context.watch<CurrentUserProvider>().user;
    final profile =
        user?.profile is CustomerProfile ? user!.profile as CustomerProfile : null;
    final fullName = [profile?.firstName, profile?.lastName]
        .where((part) => part != null && part.isNotEmpty)
        .join(' ');
    final avatarUrl = profile?.profilePictureUrl;

    logoutDialogue() {
      CustomDialog.showConfirmation(
        context: context,
        title: "Logout?",
        subtitle: "You sure want to logout?",
        onConfirm: () async {
          await context.read<AuthViewmodel>().logout();
          if (!context.mounted) return;

          final appState = context.read<AppState>();
          appState.setUser(IUser());
          appState.setPayload(ISignup());

          context.go(AppRoutes.login);
        },
        confirmText: 'Log out',
        cancelText: 'Cancel',
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: scaffoldBgColor,
        elevation: 0.0,
        title: Text(
          'Profile',
          style: blackExtraLargeTextStyle.copyWith(
            fontSize: (unit * 2.2).clamp(18.0, 26.0),
          ),
        ),
      ),
      body: ListView(
        children: <Widget>[
          InkWell(
            onTap: () {
              AppNavigator.toEditProfile(context);
            },
            child: Container(
              width: width,
              padding: EdgeInsets.all(unit),
              color: whiteColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: unit * 7,
                        height: unit * 7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(unit * 0.5),
                          image: DecorationImage(
                            image: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : const AssetImage('assets/user.jpg')
                                    as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: unit),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (fullName.isNotEmpty) ...[
                            Text(
                              fullName,
                              style: blackHeadingTextStyle.copyWith(
                                fontSize: (unit * 1.7).clamp(14.0, 19.0),
                              ),
                            ),
                            SizedBox(height: unit),
                          ],
                          Text(
                            user?.phone ?? '',
                            style: greySmallTextStyle.copyWith(
                              fontSize: (unit * 1.5).clamp(12.0, 17.0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: unit * 1.6,
                    color: Colors.grey.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.all(unit),
            padding: EdgeInsets.all(unit),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(unit * 0.5),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  blurRadius: unit * 0.15,
                  spreadRadius: unit * 0.15,
                  color: Colors.grey[200]!,
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                InkWell(
                  onTap: () {
                    context.push(AppRoutes.notifications);
                  },
                  child: getTile(
                    Icon(
                      Icons.notifications,
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                    'Notifications',
                    unit,
                    badgeCount:
                        context.watch<NotificationViewmodel>().unreadCount,
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: getTile(
                    Icon(
                      Icons.language,
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                    'Language',
                    unit,
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: getTile(
                    Icon(
                      Icons.settings,
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                    'Settings',
                    unit,
                  ),
                ),
                InkWell(
                  onTap: () {
                    AppNavigator.toInviteFriend(context);
                  },
                  child: getTile(
                    Icon(
                      Icons.group_add,
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                    'Invite Friends',
                    unit,
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: getTile(
                    Icon(
                      Icons.headset_mic,
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                    'Support',
                    unit,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(unit),
            padding: EdgeInsets.all(unit),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(unit * 0.5),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  blurRadius: unit * 0.15,
                  spreadRadius: unit * 0.15,
                  color: Colors.grey[200]!,
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                InkWell(
                  onTap: logoutDialogue,
                  child: getTile(
                    Icon(
                      Icons.exit_to_app,
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                    'Logout',
                    unit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Row getTile(Icon icon, String title, double unit, {int badgeCount = 0}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              height: unit * 4,
              width: unit * 4,
              alignment: Alignment.center,
              child: icon,
            ),
            SizedBox(width: unit),
            Text(
              title,
              style: inputTextStyle.copyWith(
                fontSize: (unit * 1.6).clamp(13.0, 18.0),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeCount > 0) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: unit * 0.7,
                  vertical: unit * 0.2,
                ),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(unit * 2),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (unit * 1.1).clamp(9.0, 13.0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: unit),
            ],
            Icon(
              Icons.arrow_forward_ios,
              size: unit * 1.6,
              color: Colors.grey.withValues(alpha: 0.6),
            ),
          ],
        ),
      ],
    );
  }
}
