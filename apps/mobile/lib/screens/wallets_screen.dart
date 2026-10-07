import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../config/gateway_routing.dart';
import '../theme/design_tokens.dart';
import 'exchange_screen.dart';
import 'payment_webview_screen.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _wallets = [];
  bool _loading = true;

  final List<Map<String, String>> _availableCurrencies = [
    {'curr': 'NGN', 'name': 'Nigerian Naira', 'flag': '🇳🇬'},
    {'curr': 'GBP', 'name': 'British Pound', 'flag': '🇬🇧'},
    {'curr': 'USD', 'name': 'US Dollar', 'flag': '🇺🇸'},
    {'curr': 'EUR', 'name': 'Euro', 'flag': '🇪🇺'},
    {'curr': 'CAD', 'name': 'Canadian Dollar', 'flag': '🇨🇦'},
    {'curr': 'AED', 'name': 'UAE Dirham', 'flag': '🇦🇪'},
    {'curr': 'GHS', 'name': 'Ghanaian Cedi', 'flag': '🇬🇭'},
    {'curr': 'ZAR', 'name': 'South African Rand', 'flag': '🇿🇦'},
    {'curr': 'CNY', 'name': 'Chinese Yuan', 'flag': '🇨🇳'},
    {'curr': 'SAR', 'name': 'Saudi Riyal', 'flag': '🇸🇦'},
  ];

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getWallets();
      setState(() {
        _wallets = res.isNotEmpty
            ? res
            : [
                {'currency': 'NGN', 'available_balance': '12500000.00'},
                {'currency': 'USD', 'available_balance': '5800.00'},
              ];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _wallets = [
          {'currency': 'NGN', 'available_balance': '12500000.00'},
          {'currency': 'USD', 'available_balance': '5800.00'},
        ];
        _loading = false;
      });
    }
  }

  Widget _gatewayTile({
    required String gateway,
    required GatewayRoute route,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    final enabled = route.supports(gateway);
    final isSelected = selected == gateway;
    final isBest = route.recommended == gateway;
    final color = gateway == GatewayRouting.paystack ? const Color(0xFF00C3F7) : const Color(0xFFFB9129);
    final title = gateway == GatewayRouting.paystack ? '⚡ Paystack' : '🌍 Flutterwave';
    final subtitle = !enabled
        ? 'Not available for ${route.currency}'
        : (gateway == GatewayRouting.paystack ? 'Cards, USSD, Bank' : 'Global, USD, MoMo');

    return Expanded(
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: GestureDetector(
          onTap: enabled ? () => onSelect(gateway) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? color : Colors.grey.withOpacity(0.3), width: isSelected ? 2 : 1),
            ),
            child: Column(
              children: [
                if (isBest)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: PayNoraColors.brandSecondary, borderRadius: BorderRadius.circular(4)),
                    child: Text('BEST FOR ${route.currency}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDepositDialog(String currency) {
    final route = GatewayRouting.forCurrency(currency);
    final controller = TextEditingController(text: GatewayRouting.defaultAmount(currency));
    String chosenGateway = route.recommended;
    String? amountError = route.validate(controller.text);
    final isDark = ThemeNotifier.instance.isDarkMode;
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? PayNoraColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Deposit into $currency Wallet', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: PayNoraColors.brandSecondary.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: const Text('LIVE RAILS', style: TextStyle(color: PayNoraColors.brandSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => setModalState(() => amountError = route.validate(v)),
                decoration: InputDecoration(
                  labelText: 'Amount ($currency)',
                  helperText: route.limitsLabel,
                  errorText: amountError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Payment Gateway (Smart Routing)', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _gatewayTile(
                    gateway: GatewayRouting.paystack,
                    route: route,
                    selected: chosenGateway,
                    onSelect: (g) => setModalState(() => chosenGateway = g),
                  ),
                  const SizedBox(width: 8),
                  _gatewayTile(
                    gateway: GatewayRouting.flutterwave,
                    route: route,
                    selected: chosenGateway,
                    onSelect: (g) => setModalState(() => chosenGateway = g),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: PayNoraColors.brandSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${GatewayRouting.label(route.recommended)} selected automatically · ${route.reason}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PayNoraColors.brandSecondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (isProcessing || amountError != null) ? null : () async {
                    setModalState(() => isProcessing = true);
                    try {
                      final initRes = await _api.initializeDeposit(
                        currency: currency,
                        amount: controller.text,
                        gateway: chosenGateway,
                      );

                      if (initRes['status'] == 'SUCCESS' && initRes['checkout_url'] != null) {
                        Navigator.pop(context);
                        final String checkoutUrl = initRes['checkout_url'];
                        final String reference = initRes['reference'];
                        final String gateway = initRes['gateway'];
                        final String amount = (initRes['amount'] ?? controller.text).toString();

                        if (initRes['failover_from'] != null) {
                          ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                            content: Text('${GatewayRouting.label(initRes['failover_from'])} unavailable for $currency — switched to ${GatewayRouting.label(gateway)} automatically.'),
                          ));
                        }

                        // Open in-app dedicated checkout WebView directly inside PayNora
                        final bool? completed = await Navigator.push<bool>(
                          this.context,
                          MaterialPageRoute(
                            builder: (_) => PaymentWebviewScreen(
                              checkoutUrl: checkoutUrl,
                              gateway: gateway,
                              reference: reference,
                              currency: currency,
                              amount: amount,
                            ),
                          ),
                        );

                        if (!mounted) return;
                        if (completed == true) {
                          await _confirmDeposit(reference: reference, gateway: gateway, currency: currency, amount: amount, checkoutUrl: checkoutUrl);
                        } else {
                          _showCheckoutBottomSheet(
                            checkoutUrl: checkoutUrl,
                            reference: reference,
                            gateway: gateway,
                            currency: currency,
                            amount: amount,
                          );
                        }
                      } else {
                        setModalState(() {
                          isProcessing = false;
                          if (initRes['code'] == 'AMOUNT_OUT_OF_RANGE') amountError = initRes['message'];
                        });
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text(initRes['message'] ?? 'Could not initialize payment.')),
                        );
                      }
                    } catch (e) {
                      setModalState(() => isProcessing = false);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Could not reach the payment server. Check your connection and try again.')),
                      );
                    }
                  },
                  child: isProcessing
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Proceed with ${GatewayRouting.label(chosenGateway)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeposit({
    required String reference,
    required String gateway,
    required String currency,
    required String amount,
    required String checkoutUrl,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text('Verifying payment with ${GatewayRouting.label(gateway)}...'), duration: const Duration(seconds: 2)));
    try {
      final res = await _api.verifyDeposit(reference: reference, gateway: gateway, currency: currency);
      if (!mounted) return;
      if (res['status'] == 'SUCCESS') {
        final credited = res['verification']?['amount'] ?? amount;
        await _loadWallets();
        messenger.showSnackBar(SnackBar(content: Text('Deposit of $credited $currency confirmed and credited!')));
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('Payment not confirmed yet. Complete checkout, then tap "I Have Completed Payment".')));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Could not verify payment right now. Please try again.')));
    }
    _showCheckoutBottomSheet(checkoutUrl: checkoutUrl, reference: reference, gateway: gateway, currency: currency, amount: amount);
  }

  void _showCheckoutBottomSheet({
    required String checkoutUrl,
    required String reference,
    required String gateway,
    required String currency,
    required String amount,
  }) {
    final isDark = ThemeNotifier.instance.isDarkMode;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: isDark ? PayNoraColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Icon(Icons.shield_outlined, size: 48, color: PayNoraColors.brandSecondary),
            const SizedBox(height: 12),
            Text('$gateway Secure Checkout', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 8),
            Text('Transaction Ref: $reference', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text('Amount: $amount $currency', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: PayNoraColors.brandSecondary)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: PayNoraColors.brandPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Complete your card or bank transfer on the official $gateway checkout page.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open Payment Portal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PayNoraColors.brandPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentWebviewScreen(
                        checkoutUrl: checkoutUrl,
                        gateway: gateway,
                        reference: reference,
                        currency: currency,
                        amount: amount,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await _confirmDeposit(reference: reference, gateway: gateway, currency: currency, amount: amount, checkoutUrl: checkoutUrl);
                },
                child: const Text('I Have Completed Payment', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivateWalletDialog() {
    final isDark = ThemeNotifier.instance.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? PayNoraColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 16),
            const Text('Activate New Currency Wallet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            const Text('Enable accounts across our 11 active launch jurisdictions.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: _availableCurrencies.length,
                separatorBuilder: (_, __) => const Divider(height: 8),
                itemBuilder: (context, i) {
                  final c = _availableCurrencies[i];
                  final isAlreadyActive = _wallets.any((w) => w['currency'] == c['curr']);
                  return ListTile(
                    leading: Text(c['flag']!, style: const TextStyle(fontSize: 24)),
                    title: Text('${c['curr']} • ${c['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    trailing: isAlreadyActive
                        ? const Text('Active', style: TextStyle(color: PayNoraColors.brandSecondary, fontWeight: FontWeight.bold, fontSize: 12))
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PayNoraColors.brandPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              await _api.activateWallet(c['curr']!);
                              _loadWallets();
                            },
                            child: const Text('Activate', style: TextStyle(fontSize: 12)),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeNotifier.instance.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Double Currency Wallets', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18)),
        backgroundColor: isDark ? PayNoraColors.darkSurface : PayNoraColors.brandPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Balances',
            onPressed: _loadWallets,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PayNoraColors.brandSecondary))
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // Top Info Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? PayNoraColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: PayNoraColors.brandSecondary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: PayNoraColors.brandSecondary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Double Currency Digital Wallets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 2),
                            Text('Authoritative Local Currency + USD • Zero negative balance drift', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Wallets List
                ..._wallets.map((w) {
                  final curr = w['currency'] ?? 'USD';
                  final bal = w['available_balance'] ?? '0.00';
                  final flag = _getCurrencyFlag(curr);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? PayNoraColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(flag, style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$curr Digital Wallet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : PayNoraColors.brandPrimary)),
                                    const Text('Authoritative Core Account', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: PayNoraColors.successBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('ACTIVE', style: TextStyle(color: PayNoraColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Available Funds', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 3),
                                Text(
                                  '$bal $curr',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    color: isDark ? Colors.white : PayNoraColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: PayNoraColors.brandSecondary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _showDepositDialog(curr),
                                  child: const Text('+ Deposit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? Colors.white : PayNoraColors.brandPrimary,
                                    side: BorderSide(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExchangeScreen()));
                                  },
                                  child: const Text('Convert', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 20),
              ],
            ),
    );
  }

  String _getCurrencyFlag(String currency) {
    switch (currency) {
      case 'NGN': return '🇳🇬';
      case 'GBP': return '🇬🇧';
      case 'USD': return '🇺🇸';
      case 'EUR': return '🇪🇺';
      case 'CAD': return '🇨🇦';
      case 'AED': return '🇦🇪';
      case 'GHS': return '🇬🇭';
      case 'ZAR': return '🇿🇦';
      case 'CNY': return '🇨🇳';
      case 'SAR': return '🇸🇦';
      default: return '🌐';
    }
  }
}
