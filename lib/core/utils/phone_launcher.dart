import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hands off to the device's native phone dialer via the `tel:` scheme —
/// never an in-app/VoIP call — so the OS's own call UI takes over.
Future<void> launchPhoneCall(BuildContext context, String phoneNumber) async {
  final uri = Uri(scheme: 'tel', path: phoneNumber.replaceAll(' ', ''));
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to start a call on this device.')),
    );
  }
}
