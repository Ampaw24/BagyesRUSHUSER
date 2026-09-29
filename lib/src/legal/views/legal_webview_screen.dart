import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/legal/models/legal_document.dart';

/// Shows a [LegalDocument] from the bagyesRUSH website. Only https pages on
/// [legalSiteHost] load in-app; any other link (mailto:, tel:, other sites)
/// is handed to the system instead.
class LegalWebViewScreen extends StatefulWidget {
  const LegalWebViewScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  State<LegalWebViewScreen> createState() => _LegalWebViewScreenState();
}

class _LegalWebViewScreenState extends State<LegalWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.scaffold)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _hasError = false);
          },
          onPageFinished: (_) => _syncCanGoBack(),
          onWebResourceError: (error) {
            // Subresource failures (analytics, fonts) don't break the page.
            if (!mounted || error.isForMainFrame == false) return;
            setState(() => _hasError = true);
          },
          onNavigationRequest: _onNavigationRequest,
        ),
      )
      ..loadRequest(Uri.parse(widget.document.url));
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    if (uri.scheme == 'https' && _isLegalSite(uri.host)) {
      return NavigationDecision.navigate;
    }
    launchUrl(uri, mode: LaunchMode.externalApplication);
    return NavigationDecision.prevent;
  }

  bool _isLegalSite(String host) =>
      host == legalSiteHost || host.endsWith('.$legalSiteHost');

  Future<void> _syncCanGoBack() async {
    final canGoBack = await _controller.canGoBack();
    if (mounted && canGoBack != _canGoBack) {
      setState(() => _canGoBack = canGoBack);
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _progress = 0;
    });
    _controller.loadRequest(Uri.parse(widget.document.url));
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    // Back steps through in-site history before leaving the screen.
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _controller.goBack().then((_) => _syncCanGoBack());
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          title: Text(widget.document.title),
          bottom: _progress < 100 && !_hasError
              ? PreferredSize(
                  preferredSize: Size.fromHeight(w * 0.008),
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: w * 0.008,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                )
              : null,
        ),
        body: _hasError
            ? _LoadError(onRetry: _retry)
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: w * 0.14,
              color: AppColors.textHint,
            ),
            SizedBox(height: w * 0.04),
            Text(
              "Couldn't load this page",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.045,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.02),
            Text(
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.034,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: w * 0.05),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
