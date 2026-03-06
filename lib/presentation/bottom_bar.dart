import 'dart:io';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
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

  final List<IconData> _icons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.local_mall_rounded,
    Icons.notifications_rounded,
    Icons.account_balance_wallet_rounded,
  ];

  final List<IconData> _activeIcons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.local_mall_rounded,
    Icons.notifications_rounded,
    Icons.account_balance_wallet_rounded,
  ];

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
      bottomNavigationBar: _ModernBottomNav(
        currentIndex: currentIndex,
        onTap: changePage,
        icons: _icons,
        activeIcons: _activeIcons,
      ),
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

class _ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<IconData> icons;
  final List<IconData> activeIcons;

  const _ModernBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.icons,
    required this.activeIcons,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: 12,
          bottom: bottomPadding + 12,
          left: 8,
          right: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(icons.length, (index) {
            final isSelected = index == currentIndex;
            return _NavItem(
              icon: icons[index],
              activeIcon: activeIcons[index],
              isSelected: isSelected,
              onTap: () => onTap(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textHint,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              height: 5,
              width: isSelected ? 5 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}