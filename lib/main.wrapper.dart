import 'package:gopady/appBehaviour/my_behaviour.dart';
import 'package:gopady/constant/app_theme.dart';
import 'package:gopady/core/router/app_router.dart';
import 'package:gopady/core/widgets/keyboard_dismisser.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GoPady',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      builder: (context, child) {
        return KeyboardDismisser(
          child: ScrollConfiguration(behavior: MyBehavior(), child: child!),
        );
      },
    );
  }
}
