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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Webview resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
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
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: PayNoraColors.brandSecondary),
            ),
        ],
      ),
    );
  }
}
