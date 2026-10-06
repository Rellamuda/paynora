/// Smart gateway routing table (mirrors backend `GATEWAY_ROUTING`).
///
/// For every currency it defines which gateway is recommended (best coverage /
/// success rate), which gateways are able to process it, and per-transaction
/// limits. The backend re-validates everything, so this is purely for UX.
class GatewayRoute {
  final String currency;
  final String recommended;
  final List<String> supported;
  final double min;
  final double max;
  final String reason;

  const GatewayRoute({
    required this.currency,
    required this.recommended,
    required this.supported,
    required this.min,
    required this.max,
    required this.reason,
  });

  bool supports(String gateway) => supported.contains(gateway);

  /// Returns an error message if [amount] is out of range, otherwise null.
  String? validate(String raw) {
    final value = double.tryParse(raw.replaceAll(',', '').trim());
    if (value == null || value <= 0) return 'Enter a valid amount';
    if (value < min) return 'Minimum deposit is ${_fmt(min)} $currency';
    if (value > max) return 'Maximum single deposit is ${_fmt(max)} $currency';
    return null;
  }

  String get limitsLabel => 'Limits: ${_fmt(min)} – ${_fmt(max)} $currency per deposit';

  static String _fmt(double v) {
    final s = v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
    return s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

class GatewayRouting {
  static const String paystack = 'PAYSTACK';
  static const String flutterwave = 'FLUTTERWAVE';

  static const Map<String, GatewayRoute> _routes = {
    'NGN': GatewayRoute(currency: 'NGN', recommended: paystack, supported: [paystack, flutterwave], min: 100, max: 5000000, reason: 'Best Nigerian card, bank transfer & USSD success rates'),
    'GHS': GatewayRoute(currency: 'GHS', recommended: paystack, supported: [paystack, flutterwave], min: 1, max: 50000, reason: 'Native Ghana card & mobile money rails'),
    'ZAR': GatewayRoute(currency: 'ZAR', recommended: paystack, supported: [paystack, flutterwave], min: 10, max: 60000, reason: 'Native South African card & EFT rails'),
    'KES': GatewayRoute(currency: 'KES', recommended: paystack, supported: [paystack, flutterwave], min: 10, max: 450000, reason: 'Native Kenya card & M-Pesa rails'),
    'USD': GatewayRoute(currency: 'USD', recommended: flutterwave, supported: [flutterwave], min: 1, max: 4500, reason: 'Global multi-currency card acquiring'),
    'GBP': GatewayRoute(currency: 'GBP', recommended: flutterwave, supported: [flutterwave], min: 1, max: 3500, reason: 'Global multi-currency card acquiring'),
    'EUR': GatewayRoute(currency: 'EUR', recommended: flutterwave, supported: [flutterwave], min: 1, max: 4000, reason: 'Global multi-currency card acquiring'),
    'CAD': GatewayRoute(currency: 'CAD', recommended: flutterwave, supported: [flutterwave], min: 1, max: 6000, reason: 'Global multi-currency card acquiring'),
    'UGX': GatewayRoute(currency: 'UGX', recommended: flutterwave, supported: [flutterwave], min: 500, max: 15000000, reason: 'Uganda mobile money coverage'),
    'TZS': GatewayRoute(currency: 'TZS', recommended: flutterwave, supported: [flutterwave], min: 500, max: 10000000, reason: 'Tanzania mobile money coverage'),
    'RWF': GatewayRoute(currency: 'RWF', recommended: flutterwave, supported: [flutterwave], min: 100, max: 5000000, reason: 'Rwanda mobile money coverage'),
    'XAF': GatewayRoute(currency: 'XAF', recommended: flutterwave, supported: [flutterwave], min: 100, max: 2500000, reason: 'Francophone Central Africa mobile money'),
    'XOF': GatewayRoute(currency: 'XOF', recommended: flutterwave, supported: [flutterwave], min: 100, max: 2500000, reason: 'Francophone West Africa mobile money'),
    'ZMW': GatewayRoute(currency: 'ZMW', recommended: flutterwave, supported: [flutterwave], min: 5, max: 100000, reason: 'Zambia mobile money coverage'),
    'EGP': GatewayRoute(currency: 'EGP', recommended: flutterwave, supported: [flutterwave], min: 10, max: 200000, reason: 'Egypt card acquiring'),
  };

  static GatewayRoute forCurrency(String currency) {
    final c = currency.toUpperCase();
    return _routes[c] ??
        GatewayRoute(currency: c, recommended: flutterwave, supported: const [flutterwave], min: 1, max: 4500, reason: 'Global multi-currency coverage');
  }

  static String label(String gateway) => gateway == paystack ? 'Paystack' : 'Flutterwave';

  /// Sensible default amount to prefill the deposit field.
  static String defaultAmount(String currency) {
    final r = forCurrency(currency);
    if (r.min >= 100) return (r.min * 50).toStringAsFixed(0);
    return '50';
  }
}
