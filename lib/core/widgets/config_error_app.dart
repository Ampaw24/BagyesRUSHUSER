import 'package:flutter/material.dart';

/// Shown instead of the app when it was launched without its build-time
/// config (see `Config.validate`) — a stalled splash screen gives no clue.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Builder(
            builder: (context) {
              final width = MediaQuery.sizeOf(context).width;
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(width * 0.08),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.settings_suggest_rounded, size: width * 0.16),
                      SizedBox(height: width * 0.04),
                      Text(
                        'App configuration missing',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: width * 0.05,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: width * 0.03),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: width * 0.038),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
