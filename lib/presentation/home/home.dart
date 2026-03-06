import 'package:bagyesrushappusernew/constant/constant.dart';
import 'package:bagyesrushappusernew/core/router/router.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: scaffoldBgColor,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text('BagyesRUSH', style: appBarTextStyle),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: primaryColor),
            onPressed: () {
              AppNavigator.toProfile(context);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(fixPadding * 2.0),
            child: Image.asset(
              'assets/banner.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
          heightSpace,
          InkWell(
            onTap: () {
              AppNavigator.toInviteFriend(context);
            },
            child: Container(
              padding: EdgeInsets.all(fixPadding * 2.0),
              color: lightPrimaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/wallet.png',
                        width: 35.0,
                        height: 35.0,
                        fit: BoxFit.fitHeight,
                      ),
                      widthSpace,
                      Container(
                        width: width - (fixPadding * 4.0 + 35.0 + 30.0 + 10.0),
                        child: Text(
                            'Invite friends to and earn upto \GHS20 as Bonus',
                            style: blackSmallTextStyle),
                      ),
                    ],
                  ),
                  Container(
                    width: 30.0,
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.arrow_forward_ios,
                        color: greyColor, size: 18.0),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              AppNavigator.toSendPackages(context);
            },
            child: Hero(
              tag: 'Send Packages',
              child: Container(
                margin: EdgeInsets.only(
                    top: fixPadding * 2.0,
                    right: fixPadding * 2.0,
                    left: fixPadding * 2.0),
                padding: EdgeInsets.all(fixPadding * 2.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: whiteColor,
                  border: Border.all(width: 0.2, color: primaryColor),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      blurRadius: 1.5,
                      spreadRadius: 1.5,
                      color: primaryColor.withValues(alpha: 0.2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 70.0,
                      height: 70.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35.0),
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                      child: Image.asset(
                        'assets/icons/courier.png',
                        width: 40.0,
                        height: 40.0,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                    widthSpace,
                    Container(
                      width: width - (fixPadding * 8.0 + 70.0 + 10.0 + 0.4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Send Packages',
                              style: primaryColorHeadingTextStyle),
                          Text('Send packages to anywhere and anytime.',
                              style: greySmallTextStyle)
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          // Send Packages Start

          // Food Deliver Start
          InkWell(
            onTap: () {
              AppNavigator.toFoodDelivery(context);
            },
            child: Hero(
              tag: 'Get Food Deliver',
              child: Container(
                margin: EdgeInsets.only(
                    top: fixPadding * 2.0,
                    right: fixPadding * 2.0,
                    left: fixPadding * 2.0),
                padding: EdgeInsets.all(fixPadding * 2.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: whiteColor,
                  border: Border.all(width: 0.2, color: primaryColor),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      blurRadius: 1.5,
                      spreadRadius: 1.5,
                      color: primaryColor.withValues(alpha: 0.2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 70.0,
                      height: 70.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35.0),
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                      child: Image.asset(
                        'assets/icons/food.png',
                        width: 40.0,
                        height: 40.0,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                    widthSpace,
                    Container(
                      width: width - (fixPadding * 8.0 + 70.0 + 10.0 + 0.4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Get Food Deliver',
                              style: primaryColorHeadingTextStyle),
                          Text('Order food and we will deliver it.',
                              style: greySmallTextStyle)
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          // Food Deliver Start

          // Grocery Deliver Start
          InkWell(
            onTap: () {
              AppNavigator.toGroceryDelivery(context);
            },
            child: Container(
              margin: EdgeInsets.only(
                  top: fixPadding * 2.0,
                  right: fixPadding * 2.0,
                  left: fixPadding * 2.0),
              padding: EdgeInsets.all(fixPadding * 2.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: whiteColor,
                border: Border.all(width: 0.2, color: primaryColor),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    blurRadius: 1.5,
                    spreadRadius: 1.5,
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 70.0,
                    height: 70.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35.0),
                      color: primaryColor.withValues(alpha: 0.2),
                    ),
                    child: Image.asset(
                      'assets/icons/grocery.png',
                      width: 40.0,
                      height: 40.0,
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                  widthSpace,
                  Container(
                    width: width - (fixPadding * 8.0 + 70.0 + 10.0 + 0.4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Get Grocery Deliver',
                            style: primaryColorHeadingTextStyle),
                        Text(
                            'Order grocery at your favourite store and we will deliver it.',
                            style: greySmallTextStyle)
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          // Grocery Deliver Start
          // Courier Type End
          heightSpace,
          heightSpace,
        ],
      ),
    );
  }
}
