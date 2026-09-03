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
  String? _loadError;

  /// Only Paystack's own hosted-checkout domains may be loaded/navigated to.
  /// Everything else (including the merchant's own callback host once the
  /// charge completes) is treated as "left the gateway" rather than followed,
  /// so a compromised or malformed `authorization_url` can never point this
  /// WebView at an arbitrary site.
  static const _trustedGatewayHosts = {
    'checkout.paystack.com',
    'standard.paystack.co',
  };

  bool get _isInvalidStartUrl =>
      _startUri.scheme != 'https' || !_trustedGatewayHosts.contains(_startUri.host);

  @override
  void initState() {
    super.initState();
    _startUri = Uri.tryParse(widget.paymentUrl) ?? Uri();

    if (_isInvalidStartUrl) {
      // Malformed, non-HTTPS, or non-Paystack URL — refuse to load rather
      // than risk a cleartext request or a scheme-hijack redirect.
      _isLoading = false;
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _loadError = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            // Only the main-frame load failing should block the page —
            // ignore errors from ads/analytics subresources on the checkout
            // page itself.
            if (!mounted || error.isForMainFrame == false) return;
            setState(() {
              _isLoading = false;
              _loadError = 'Couldn\'t reach the payment gateway. Check your '
                  'connection and try again.';
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            // Block anything that isn't a plain https:// navigation — stops
            // scheme hijacking (tel:, intent:, javascript:) and cleartext
            // http downgrades from ever being followed.
            if (uri == null || uri.scheme != 'https') {
              return NavigationDecision.prevent;
            }
            final leftGateway = !_trustedGatewayHosts.contains(uri.host);
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

  void _retry() {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    _controller.loadRequest(_startUri);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: _isInvalidStartUrl
          ? _ErrorState(
              width: width,
              message: 'This payment link couldn\'t be verified as secure.',
              onClose: () => Navigator.of(context).pop(false),
            )
          : _loadError != null
              ? _ErrorState(
                  width: width,
                  message: _loadError!,
                  onRetry: _retry,
                  onClose: () => Navigator.of(context).pop(false),
                )
              : Stack(
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.width,
    required this.message,
    required this.onClose,
    this.onRetry,
  });

  final double width;
  final String message;
  final VoidCallback onClose;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: width * 0.12,
              color: AppColors.primary,
            ),
            SizedBox(height: width * 0.04),
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: width * 0.05),
            Wrap(
              spacing: width * 0.03,
              alignment: WrapAlignment.center,
              children: [
                if (onRetry != null)
                  ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
                OutlinedButton(onPressed: onClose, child: const Text('Close')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
