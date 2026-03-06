import 'dart:convert';

import 'package:bagyesrushappusernew/constant/constant.dart';
import 'package:bagyesrushappusernew/constant/image_constants.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bagyesrushappusernew/services/notifications.service.dart';
import 'package:bagyesrushappusernew/states/app.state.dart';
import 'package:provider/provider.dart';

class Notifications extends StatefulWidget {
  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  bool loading = false;
  IUser user = IUser();
  var notificationList = [];
  void getNotifications(BuildContext context) {
    user = context.read<AppState>().userInfo;
    var token = user.token;
    var id = user.id;
    setState(() {
      loading = true;
    });
    var response = getCustomerNotifications(
      token,
      id,
    ).then((response) => response.body);
    response.then((res) {
      setState(() {
        loading = false;
      });
      var resp = jsonDecode(res) as Map<String, dynamic>;
      switch (resp['success']) {
        case true:
          notificationList = resp['data'];
          break;
        default:
          CustomDialog.showError(
            context: context,
            title: 'Oops!',
            subtitle: resp['message'],
            iconPath: AssetImages.bagyesLogo,
            isLottie: false,
          );
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    this.getNotifications(context);
  }

  // final notificationList = [
  //   {
  //     'type': 'order',
  //     'title': 'Order Placed',
  //     'desc': 'Your order placed successfully. OrderId: OID1256789.'
  //   },
  //   {
  //     'type': 'offer',
  //     'title': '25% Off use code CourierPro25',
  //     'desc':
  //         'Use code CourierPro25 for your order between 20th sept to 25th sept and get 25% off.'
  //   },
  //   {
  //     'type': 'offer',
  //     'title': 'Flat \$10 Off',
  //     'desc': 'Use code CPro10 and get \$10 off on your order.'
  //   }
  // ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: scaffoldBgColor,
        elevation: 1.0,
        automaticallyImplyLeading: false,
        title: Text('Notifications', style: appBarBlackTextStyle),
      ),
      body: loading
          ? SpinKitCircle(size: 20, color: Colors.white)
          : noticesView(),
    );
  }

  noticesView() {
    double width = MediaQuery.of(context).size.width;
    return (notificationList.length == 0)
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  FontAwesomeIcons.bellSlash,
                  color: Colors.grey,
                  size: 60.0,
                ),
                SizedBox(height: 20.0),
                Text('No Notifications', style: greyNormalTextStyle),
              ],
            ),
          )
        : ListView.builder(
            physics: BouncingScrollPhysics(),
            itemCount: notificationList.length,
            itemBuilder: (context, index) {
              final item = notificationList[index];
              return Dismissible(
                key: Key('$item'),
                onDismissed: (direction) {
                  setState(() {
                    notificationList.removeAt(index);
                  });

                  // Then show a snackbar.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${item['title']} dismissed")),
                  );
                },
                // Show a red background as the item is swiped away.
                background: Container(color: Colors.red),
                child: Center(
                  child: Container(
                    width: width - 20.0,
                    margin: EdgeInsets.only(top: 3.0, bottom: 3.0),
                    child: Card(
                      elevation: 2.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            alignment: Alignment.topLeft,
                            padding: EdgeInsets.all(10.0),
                            child: CircleAvatar(
                              child: Icon(
                                (item['type'] == 'order')
                                    ? Icons.local_shipping
                                    : Icons.local_offer,
                                size: 30.0,
                              ),
                              radius: 40.0,
                            ),
                          ),
                          Container(
                            width: width - 130.0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: 8.0,
                                    right: 8.0,
                                    left: 8.0,
                                  ),
                                  child: Text(
                                    '${item['title']}',
                                    style: blackHeadingTextStyle,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    '${item['desc']}',
                                    style: greySmallTextStyle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }
}
