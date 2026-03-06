import 'package:bagyesrushappusernew/constant/constant.dart';
import 'package:bagyesrushappusernew/constant/image_constants.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/core/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../states/app.state.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final user = context.read<AppState>().userInfo;

    logoutDialogue() {
      CustomDialog.showConfirmation(
        context: context,
        title: "Logout?",
        subtitle: "You sure want to logout?",
        iconPath: AssetImages.bagyesLogo,
        isLottie: false,
        onConfirm: () {
          AppNavigator.toWalkthrough(context);
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
        title: Text('Profile', style: blackExtraLargeTextStyle),
      ),
      body: ListView(
        children: <Widget>[
          InkWell(
            onTap: () {
              AppNavigator.toEditProfile(context);
            },
            child: Container(
              width: width,
              padding: EdgeInsets.all(fixPadding),
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
                        width: 70.0,
                        height: 70.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                          image: DecorationImage(
                            image: AssetImage('assets/user.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      widthSpace,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Text(
                          //   user.name,
                          //   style: blackHeadingTextStyle,
                          // ),
                          heightSpace,
                          Text(user.phone, style: greySmallTextStyle),
                        ],
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16.0,
                    color: Colors.grey.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.all(fixPadding),
            padding: EdgeInsets.all(fixPadding),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(5.0),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  blurRadius: 1.5,
                  spreadRadius: 1.5,
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
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(fixPadding),
            padding: EdgeInsets.all(fixPadding),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(5.0),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  blurRadius: 1.5,
                  spreadRadius: 1.5,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  getTile(Icon icon, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 40.0,
              width: 40.0,
              alignment: Alignment.center,
              child: icon,
            ),
            widthSpace,
            Text(title, style: inputTextStyle),
          ],
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 16.0,
          color: Colors.grey.withValues(alpha: 0.6),
        ),
      ],
    );
  }
}
