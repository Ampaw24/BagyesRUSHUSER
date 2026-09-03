import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';

/// Hosts the Paystack-hosted checkout page returned by
/// `PaymentGatewayRepository.initializePayment`. Pops `true` once the page
/// navigates away from the gateway's own domain (Paystack redirects to the
/// backend's configured callback URL once the charge is done), so the caller
/// knows to verify the transaction by reference. Pops `false`/null if the
/// user closes the sheet manually before that happens.
class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;

  const PaymentWebViewScreen({super.key, required this.paymentUrl});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  late final Uri _startUri;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startUri = Uri.parse(widget.paymentUrl);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final leftGateway = uri != null &&
                uri.host != _startUri.host &&
                uri.host != 'checkout.paystack.com' &&
                uri.host != 'standard.paystack.co';
            if (leftGateway) {
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(_startUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
