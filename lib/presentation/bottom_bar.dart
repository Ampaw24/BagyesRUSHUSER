import 'dart:io';

import 'package:bagyesrushappusernew/presentation/home/home.dart';
import 'package:bagyesrushappusernew/presentation/notifications/notifications.dart';
import 'package:bagyesrushappusernew/presentation/orders/orders.dart';
import 'package:bagyesrushappusernew/presentation/search/search.dart';
import 'package:bagyesrushappusernew/presentation/wallet/wallet.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int currentIndex = 0;
  DateTime? currentBackPressTime;

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
  }

  void changePage(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Widget onTabChange() {
    switch (currentIndex) {
      case 0:
        return Home();
      case 1:
        return Search();
      case 2:
        return Orders();
      case 3:
        return Notifications();
      default:
        return Wallet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) return;
          bool backStatus = onWillPop();
          if (backStatus) {
            exit(0);
          }
        },
        child: onTabChange(),
      ),
    );
  }

  onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(
        msg: 'Press Back Once Again to Exit.',
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
      return false;
    } else {
      return true;
    }
  }
}