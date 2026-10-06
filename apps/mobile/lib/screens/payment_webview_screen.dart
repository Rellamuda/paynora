import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/design_tokens.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final String checkoutUrl;
  final String gateway;
  final String reference;
  final String currency;
  final String amount;

  const PaymentWebviewScreen({
    super.key,
    required this.checkoutUrl,
    required this.gateway,
    required this.reference,
    required this.currency,
    required this.amount,
  });

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _loadError;
  bool _completed = false;

  bool _isCallbackUrl(String url) => url.contains('/payment-callback');

  void _finish(bool success) {
    if (_completed || !mounted) return;
    _completed = true;
    Navigator.pop(context, success);
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            if (_isCallbackUrl(url)) {
              _finish(true);
              return NavigationDecision.prevent;
            }
            // Block non-web schemes (intent://, bank app deep links) that the WebView cannot render.
            if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('about:')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            if (_isCallbackUrl(url)) {
              _finish(true);
              return;
            }
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Webview resource error: ${error.errorCode} ${error.description}');
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _loadError = error.description;
                });
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _retry() {
    setState(() {
      _loadError = null;
      _isLoading = true;
    });
    _controller.loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeNotifier.instance.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? PayNoraColors.darkBackground : PayNoraColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? PayNoraColors.darkSurface : Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.gateway} Secure Checkout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : PayNoraColors.darkBackground,
              ),
            ),
            Text(
              'Ref: ${widget.reference} • ${widget.amount} ${widget.currency}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_circle, color: PayNoraColors.brandSecondary, size: 18),
            label: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.bold, color: PayNoraColors.brandSecondary),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loadError != null)
            Container(
              color: isDark ? PayNoraColors.darkBackground : PayNoraColors.lightBackground,
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load ${widget.gateway} checkout',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : PayNoraColors.darkBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          if (_isLoading && _loadError == null)
            const Center(
              child: CircularProgressIndicator(color: PayNoraColors.brandSecondary),
            ),
        ],
      ),
    );
  }
}
