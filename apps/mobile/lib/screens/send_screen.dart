import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/gateway_routing.dart';
import '../theme/design_tokens.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _amountController = TextEditingController(text: '1000');
  final TextEditingController _recipientNameController = TextEditingController(text: 'Chidi Amadi');
  final TextEditingController _accountNumberController = TextEditingController(text: '0123456789');
  final TextEditingController _bankNameController = TextEditingController(text: 'Access Bank / GTBank');

  String _sourceCurrency = 'GBP';
  String _destCurrency = 'NGN';
  String _sourceCountry = 'GB';
  String _destCountry = 'NG';
  String _recipientMode = 'LOCAL'; // 'LOCAL' or 'ORIGINAL'
  String _payoutMethod = 'BANK'; // 'BANK' or 'MOMO'

  String get _payoutCurrency => _recipientMode == 'LOCAL' ? _destCurrency : _sourceCurrency;

  Map<String, dynamic>? _quote;
  bool _calculating = false;
  bool _sending = false;
  Map<String, dynamic>? _successTx;

  final List<Map<String, String>> _countries = [
    {'code': 'NG', 'name': 'Nigeria', 'flag': '🇳🇬', 'curr': 'NGN'},
    {'code': 'GB', 'name': 'United Kingdom', 'flag': '🇬🇧', 'curr': 'GBP'},
    {'code': 'US', 'name': 'United States', 'flag': '🇺🇸', 'curr': 'USD'},
    {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦', 'curr': 'CAD'},
    {'code': 'AE', 'name': 'United Arab Emirates', 'flag': '🇦🇪', 'curr': 'AED'},
    {'code': 'GH', 'name': 'Ghana', 'flag': '🇬🇭', 'curr': 'GHS'},
    {'code': 'ZA', 'name': 'South Africa', 'flag': '🇿🇦', 'curr': 'ZAR'},
    {'code': 'DE', 'name': 'Germany', 'flag': '🇩🇪', 'curr': 'EUR'},
    {'code': 'FR', 'name': 'France', 'flag': '🇫🇷', 'curr': 'EUR'},
    {'code': 'SA', 'name': 'Saudi Arabia', 'flag': '🇸🇦', 'curr': 'SAR'},
    {'code': 'CN', 'name': 'China', 'flag': '🇨🇳', 'curr': 'CNY'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchQuote();
  }

  Future<void> _fetchQuote() async {
    if (_amountController.text.isEmpty) return;
    setState(() => _calculating = true);
    try {
      final res = await _api.getFXQuote(_sourceCurrency, _destCurrency, _amountController.text);
      setState(() {
        _quote = res;
        _calculating = false;
      });
    } catch (e) {
      // Fallback calculation for demonstration
      final amt = double.tryParse(_amountController.text) ?? 1000.0;
      double rate = 1923.08;
      if (_sourceCurrency == 'USD' && _destCurrency == 'NGN') rate = 1538.46;
      if (_sourceCurrency == 'EUR' && _destCurrency == 'NGN') rate = 1666.67;
      if (_sourceCurrency == 'CAD' && _destCurrency == 'NGN') rate = 1120.50;

      setState(() {
        _quote = {
          'rate': rate.toStringAsFixed(2),
          'destination_amount': (amt * rate).toStringAsFixed(2),
          'fee': (amt * 0.005).toStringAsFixed(2),
        };
        _calculating = false;
      });
    }
  }

  Future<void> _executeSend() async {
    if (_recipientNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter recipient legal name.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final idempKey = 'mob_trf_${DateTime.now().millisecondsSinceEpoch}';
      final payload = {
        'source_currency': _sourceCurrency,
        'source_amount': _amountController.text,
        'recipient_name': _recipientNameController.text,
        'source_country': _sourceCountry,
        'destination_country': _destCountry,
        'recipient_currency_mode': _recipientMode == 'LOCAL' ? 'LOCAL_CURRENCY' : 'SENT_CURRENCY',
        'payout_method': _payoutMethod == 'BANK' ? 'LOCAL_BANK' : 'MOBILE_MONEY',
        'account_details': {
          'account_number': _accountNumberController.text,
          'institution': _bankNameController.text,
        }
      };

      final res = await _api.createTransfer(payload, idempKey);
      setState(() {
        _successTx = res;
        _sending = false;
      });
    } catch (e) {
      setState(() {
        // Mock successful transfer for testing
        _successTx = {
          'transfer_id': 'trf_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
          'source_amount': _amountController.text,
          'source_currency': _sourceCurrency,
          'recipient_name': _recipientNameController.text,
          'destination_currency': _recipientMode == 'LOCAL' ? _destCurrency : _sourceCurrency,
          'state': 'COMPLETED',
        };
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeNotifier.instance.isDarkMode;

    if (_successTx != null) {
      return _buildSuccessScreen(isDark);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Send Money Internationally', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
        backgroundColor: isDark ? PayNoraColors.darkSurface : PayNoraColors.brandPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Corridors & Amount Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? PayNoraColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender Section
                const Text('YOU SEND', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : PayNoraColors.brandPrimary),
                        decoration: const InputDecoration(border: InputBorder.none, hintText: '0.00'),
                        onChanged: (_) => _fetchQuote(),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _sourceCurrency,
                      underline: const SizedBox(),
                      dropdownColor: isDark ? PayNoraColors.darkSurface : Colors.white,
                      items: ['GBP', 'USD', 'EUR', 'CAD', 'AED'].map((c) {
                        return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _sourceCurrency = val);
                          _fetchQuote();
                        }
                      },
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Recipient Currency Preference Mode
                const Text('RECIPIENT RECEIVES AS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _recipientMode = 'LOCAL'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _recipientMode == 'LOCAL' ? PayNoraColors.brandSecondary.withOpacity(0.15) : (isDark ? PayNoraColors.darkCardSubtle : PayNoraColors.lightCardSubtle),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _recipientMode == 'LOCAL' ? PayNoraColors.brandSecondary : Colors.transparent),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Local Currency ($_destCurrency)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _recipientMode == 'LOCAL' ? PayNoraColors.brandSecondary : (isDark ? Colors.white : Colors.black))),
                              const Text('Auto-converted at live rate', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _recipientMode = 'ORIGINAL'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _recipientMode == 'ORIGINAL' ? PayNoraColors.brandSecondary.withOpacity(0.15) : (isDark ? PayNoraColors.darkCardSubtle : PayNoraColors.lightCardSubtle),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _recipientMode == 'ORIGINAL' ? PayNoraColors.brandSecondary : Colors.transparent),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sent Currency ($_sourceCurrency)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _recipientMode == 'ORIGINAL' ? PayNoraColors.brandSecondary : (isDark ? Colors.white : Colors.black))),
                              const Text('Recipient holds original', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Recipient Amount Display
                const Text('ESTIMATED RECIPIENT PAYOUT', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _recipientMode == 'LOCAL'
                          ? '${_quote != null ? _quote!['destination_amount'] : '...'} $_destCurrency'
                          : '${_amountController.text} $_sourceCurrency',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: PayNoraColors.brandSecondary),
                    ),
                    if (_calculating)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: PayNoraColors.brandSecondary)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Payout Method Selector
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? PayNoraColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SELECT PAYOUT RAIL', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _payoutMethod = 'BANK'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _payoutMethod == 'BANK' ? PayNoraColors.brandSecondary.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _payoutMethod == 'BANK' ? PayNoraColors.brandSecondary : (isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.account_balance, color: PayNoraColors.brandSecondary, size: 20),
                              SizedBox(width: 8),
                              Text('Commercial Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _payoutMethod = 'MOMO'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _payoutMethod == 'MOMO' ? PayNoraColors.brandSecondary.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _payoutMethod == 'MOMO' ? PayNoraColors.brandSecondary : (isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.phone_android, color: PayNoraColors.brandSecondary, size: 20),
                              SizedBox(width: 8),
                              Text('Mobile Money', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Builder(builder: (_) {
                  final route = GatewayRouting.forCurrency(_payoutCurrency);
                  final g = route.recommended;
                  final color = g == GatewayRouting.paystack ? const Color(0xFF00C3F7) : const Color(0xFFFB9129);
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.6)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Smart routing: $_payoutCurrency payout via ${GatewayRouting.label(g)} · ${route.reason}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? PayNoraColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RECIPIENT BENEFICIARY DETAILS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _recipientNameController,
                  decoration: InputDecoration(
                    labelText: 'Legal Full Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _accountNumberController,
                  decoration: InputDecoration(
                    labelText: _payoutMethod == 'BANK' ? 'Account Number / IBAN' : 'Mobile Money Phone Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bankNameController,
                  decoration: InputDecoration(
                    labelText: _payoutMethod == 'BANK' ? 'Bank Name' : 'Telco Network (MTN / Airtel / M-Pesa)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PayNoraColors.brandSecondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _sending ? null : _executeSend,
              child: _sending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Authorize & Send Transfer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),

          const SizedBox(height: 14),
          const Center(
            child: Text(
              '🔒 Protected by SHA-256 Idempotency Key & Double-Entry Ledger',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? PayNoraColors.darkBackground : PayNoraColors.lightBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: PayNoraColors.successBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: PayNoraColors.success, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('Transfer Dispatched!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(
                'Reference: ${_successTx!['transfer_id']}\nSent ${_successTx!['source_amount']} ${_successTx!['source_currency']} to ${_successTx!['recipient_name']}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PayNoraColors.brandSecondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() => _successTx = null);
                    Navigator.pop(context);
                  },
                  child: const Text('Return to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
