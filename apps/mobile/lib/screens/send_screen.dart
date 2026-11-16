import 'dart:async';
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
  final TextEditingController _amountController = TextEditingController(text: '500');
  final TextEditingController _p2pLookupController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _recipientNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();

  // Default foreign currencies are USD and GBP
  String _sourceCurrency = 'USD';
  String _destCountry = 'NG';
  String _destCurrency = 'NGN';

  // 'P2P' (PayNora-to-PayNora, default), 'BANK' (Commercial Bank), 'MOMO' (Mobile Money)
  String _payoutMethod = 'P2P';

  // Only applicable to P2P: 'LOCAL' (recipient's local currency) or 'ORIGINAL' (keep USD/GBP)
  String _recipientMode = 'LOCAL';

  // Wallet balances loaded from backend
  Map<String, String> _walletBalances = {
    'USD': '1250.00',
    'GBP': '800.00',
    'NGN': '500000.00',
  };

  // P2P lookup state
  Map<String, dynamic>? _p2pRecipient;
  bool _lookingUpP2P = false;
  String? _p2pLookupError;
  Timer? _lookupDebounce;

  // Bank resolution state (for BANK payout rail)
  List<dynamic> _banks = [];
  Map<String, dynamic>? _selectedBank;
  bool _loadingBanks = false;
  bool _resolvingBank = false;
  String? _resolvedBankAccountName;
  String? _bankResolveError;
  Timer? _bankDebounce;

  // Mobile Money state
  String _momoProvider = 'MTN MoMo';

  // Quote & transfer state
  Map<String, dynamic>? _quote;
  bool _calculating = false;
  bool _sending = false;
  Map<String, dynamic>? _successTx;

  final List<Map<String, String>> _countries = const [
    {'code': 'NG', 'name': 'Nigeria', 'flag': '🇳🇬', 'curr': 'NGN'},
    {'code': 'GH', 'name': 'Ghana', 'flag': '🇬🇭', 'curr': 'GHS'},
    {'code': 'KE', 'name': 'Kenya', 'flag': '🇰🇪', 'curr': 'KES'},
    {'code': 'ZA', 'name': 'South Africa', 'flag': '🇿🇦', 'curr': 'ZAR'},
    {'code': 'GB', 'name': 'United Kingdom', 'flag': '🇬🇧', 'curr': 'GBP'},
    {'code': 'US', 'name': 'United States', 'flag': '🇺🇸', 'curr': 'USD'},
    {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦', 'curr': 'CAD'},
    {'code': 'AE', 'name': 'United Arab Emirates', 'flag': '🇦🇪', 'curr': 'AED'},
    {'code': 'DE', 'name': 'Germany', 'flag': '🇩🇪', 'curr': 'EUR'},
  ];

  // Cross-rates via USD (units per 1 USD) for instant fallback quotes
  static const Map<String, double> _usdRates = {
    'USD': 1.0,
    'GBP': 0.78125,
    'EUR': 0.92,
    'NGN': 1500.0,
    'GHS': 15.40,
    'KES': 129.0,
    'ZAR': 18.20,
    'CAD': 1.37,
    'AED': 3.6725,
  };

  String get _effectiveDestCurrency {
    if (_payoutMethod == 'P2P') {
      final recipientLocal = (_p2pRecipient?['local_currency'] as String?) ?? _destCurrency;
      return _recipientMode == 'LOCAL' ? recipientLocal : _sourceCurrency;
    }
    // Bank & Mobile Money always pay out in destination country's local currency
    return _destCurrency;
  }

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _loadBanks();
    _fetchQuote();
  }

  @override
  void dispose() {
    _lookupDebounce?.cancel();
    _bankDebounce?.cancel();
    _amountController.dispose();
    _p2pLookupController.dispose();
    _noteController.dispose();
    _recipientNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    try {
      final list = await _api.getWallets();
      if (list.isNotEmpty) {
        final map = <String, String>{};
        for (final w in list) {
          final c = w['currency']?.toString();
          if (c != null) {
            map[c] = (w['available_balance'] ?? '0.00').toString();
          }
        }
        // Ensure default foreign currencies USD & GBP are always selectable
        map.putIfAbsent('USD', () => '0.00');
        map.putIfAbsent('GBP', () => '0.00');
        setState(() => _walletBalances = map);
      }
    } catch (_) {}
  }

  Future<void> _loadBanks() async {
    setState(() {
      _loadingBanks = true;
      _selectedBank = null;
      _resolvedBankAccountName = null;
    });
    try {
      final banks = await _api.getSupportedBanks(_destCountry);
      setState(() {
        _banks = banks;
        _loadingBanks = false;
      });
    } catch (_) {
      setState(() {
        _banks = [
          {'code': '044', 'name': 'Access Bank'},
          {'code': '058', 'name': 'Guaranty Trust Bank (GTBank)'},
          {'code': '057', 'name': 'Zenith Bank'},
          {'code': '011', 'name': 'First Bank of Nigeria'},
          {'code': '033', 'name': 'United Bank for Africa (UBA)'},
          {'code': '50211', 'name': 'Kuda Bank'},
          {'code': '999991', 'name': 'OPay Digital Services'},
          {'code': '999992', 'name': 'PalmPay'},
        ];
        _loadingBanks = false;
      });
    }
  }

  void _onP2PQueryChanged(String value) {
    setState(() {
      _p2pRecipient = null;
      _p2pLookupError = null;
    });
    _lookupDebounce?.cancel();
    if (value.trim().length >= 3) {
      _lookupDebounce = Timer(const Duration(milliseconds: 350), () => _lookupP2PUser(value.trim()));
    }
  }

  Future<void> _lookupP2PUser(String query) async {
    setState(() {
      _lookingUpP2P = true;
      _p2pLookupError = null;
    });
    try {
      final res = await _api.lookupP2PUser(query);
      if (res['found'] == true) {
        setState(() {
          _p2pRecipient = res;
          _destCountry = (res['country_iso'] ?? 'NG').toString();
          _destCurrency = (res['local_currency'] ?? 'NGN').toString();
          _lookingUpP2P = false;
        });
        _fetchQuote();
      } else {
        setState(() {
          _p2pRecipient = null;
          _p2pLookupError = 'No PayNora user found for "$query". Switch to Bank or Mobile Money to pay outside the app.';
          _lookingUpP2P = false;
        });
      }
    } catch (_) {
      // Offline/fallback demo lookup for @chidi, @sarah, @kwame or any phone/email
      final q = query.toLowerCase();
      Map<String, dynamic>? mock;
      if (q.contains('chidi') || q.contains('8031234567')) {
        mock = {
          'found': true,
          'user_id': 'usr_demo_chidi',
          'display_name': 'CHIDI AMADI',
          'tag': '@chidi',
          'country_iso': 'NG',
          'local_currency': 'NGN',
          'verified': true,
        };
      } else if (q.contains('sarah') || q.contains('7700900123')) {
        mock = {
          'found': true,
          'user_id': 'usr_demo_sarah',
          'display_name': 'SARAH THOMPSON',
          'tag': '@sarah',
          'country_iso': 'GB',
          'local_currency': 'GBP',
          'verified': true,
        };
      } else if (q.contains('kwame') || q.contains('241234567')) {
        mock = {
          'found': true,
          'user_id': 'usr_demo_kwame',
          'display_name': 'KWAME MENSAH',
          'tag': '@kwame',
          'country_iso': 'GH',
          'local_currency': 'GHS',
          'verified': true,
        };
      }
      setState(() {
        _p2pRecipient = mock;
        if (mock != null) {
          _destCountry = mock['country_iso'];
          _destCurrency = mock['local_currency'];
        } else {
          _p2pLookupError = 'User not found on PayNora. Try @chidi, @sarah, @kwame, or switch to Bank payout.';
        }
        _lookingUpP2P = false;
      });
      if (mock != null) _fetchQuote();
    }
  }

  void _onBankAccountChanged(String val) {
    setState(() {
      _resolvedBankAccountName = null;
      _bankResolveError = null;
    });
    _bankDebounce?.cancel();
    if (val.trim().length >= 10 && _selectedBank != null) {
      _bankDebounce = Timer(const Duration(milliseconds: 400), _resolveBankAccount);
    }
  }

  Future<void> _resolveBankAccount() async {
    if (_selectedBank == null || _accountNumberController.text.trim().length < 10) return;
    setState(() {
      _resolvingBank = true;
      _bankResolveError = null;
    });
    try {
      final res = await _api.resolveBankAccount(
        accountNumber: _accountNumberController.text.trim(),
        bankCode: '${_selectedBank!['code']}',
        currency: _destCurrency,
      );
      setState(() {
        _resolvedBankAccountName = res['account_name']?.toString();
        if (_resolvedBankAccountName != null) {
          _recipientNameController.text = _resolvedBankAccountName!;
        }
        _resolvingBank = false;
      });
    } catch (_) {
      setState(() {
        _bankResolveError = 'Could not auto-verify account. Please confirm recipient name below.';
        _resolvingBank = false;
      });
    }
  }

  Future<void> _fetchQuote() async {
    final amt = double.tryParse(_amountController.text) ?? 0.0;
    if (amt <= 0) return;
    final dst = _effectiveDestCurrency;

    // If recipient receives the exact same currency in P2P wallet, 1:1 with 0 fee
    if (_sourceCurrency == dst) {
      setState(() {
        _quote = {
          'rate': '1.0000',
          'destination_amount': amt.toStringAsFixed(2),
          'fee': '0.00',
        };
        _calculating = false;
      });
      return;
    }

    setState(() => _calculating = true);
    try {
      if (_payoutMethod == 'P2P' && _p2pRecipient != null) {
        final res = await _api.getP2PQuote(
          recipientUserId: '${_p2pRecipient!['user_id']}',
          sourceCurrency: _sourceCurrency,
          amount: _amountController.text,
          receiveMode: _recipientMode,
        );
        setState(() {
          _quote = {
            'rate': res['exchange_rate'],
            'destination_amount': res['destination_amount'],
            'fee': res['fee'],
          };
          _calculating = false;
        });
        return;
      }
      final res = await _api.getFXQuote(_sourceCurrency, dst, _amountController.text);
      setState(() {
        _quote = res;
        _calculating = false;
      });
    } catch (_) {
      final srcUsd = _usdRates[_sourceCurrency] ?? 1.0;
      final dstUsd = _usdRates[dst] ?? 1.0;
      final rate = dstUsd / srcUsd;
      final feeRate = _payoutMethod == 'P2P' ? 0.003 : 0.005;
      final fee = amt * feeRate;
      final net = amt - fee;
      setState(() {
        _quote = {
          'rate': rate.toStringAsFixed(4),
          'destination_amount': (net * rate).toStringAsFixed(2),
          'fee': fee.toStringAsFixed(2),
        };
        _calculating = false;
      });
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _executeSend() async {
    final amt = double.tryParse(_amountController.text) ?? 0.0;
    if (amt <= 0) {
      _snack('Please enter a valid amount.');
      return;
    }

    final idempKey = 'mob_${_payoutMethod.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';

    if (_payoutMethod == 'P2P') {
      if (_p2pRecipient == null) {
        _snack('Please enter and verify a PayNora recipient (@tag, phone, or email).');
        return;
      }
      setState(() => _sending = true);
      try {
        final res = await _api.createP2PTransfer(
          recipientUserId: '${_p2pRecipient!['user_id']}',
          sourceCurrency: _sourceCurrency,
          amount: amt.toStringAsFixed(2),
          receiveMode: _recipientMode,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          idempotencyKey: idempKey,
        );
        await _loadWallets();
        setState(() {
          _successTx = res;
          _sending = false;
        });
      } catch (e) {
        String msg = 'Transfer failed.';
        try {
          final d = (e as dynamic).response?.data?['detail'];
          if (d != null) msg = '$d';
        } catch (_) {}
        setState(() => _sending = false);
        _snack(msg);
      }
      return;
    }

    // Bank or Mobile Money payout rail (always local currency of destination country)
    final recipientName = _resolvedBankAccountName ?? _recipientNameController.text.trim();
    if (recipientName.isEmpty) {
      _snack('Please verify the account or enter recipient legal name.');
      return;
    }
    if (_accountNumberController.text.trim().isEmpty) {
      _snack(_payoutMethod == 'BANK'
          ? 'Please enter the recipient bank account number.'
          : 'Please enter the recipient mobile money phone number.');
      return;
    }

    setState(() => _sending = true);
    try {
      final payload = {
        'source_currency': _sourceCurrency,
        'destination_currency': _destCurrency,
        'source_amount': amt.toStringAsFixed(2),
        'recipient_name': recipientName,
        'source_country': _sourceCurrency == 'GBP' ? 'GB' : 'US',
        'destination_country': _destCountry,
        'recipient_currency_mode': 'LOCAL_CURRENCY',
        'payout_method': _payoutMethod == 'BANK' ? 'LOCAL_BANK' : 'MOBILE_MONEY',
        'account_details': {
          'account_number': _accountNumberController.text.trim(),
          'institution': _payoutMethod == 'BANK'
              ? (_selectedBank?['name'] ?? 'Commercial Bank')
              : _momoProvider,
          if (_selectedBank != null) 'bank_code': '${_selectedBank!['code']}',
        }
      };

      final res = await _api.createTransfer(payload, idempKey);
      setState(() {
        _successTx = res;
        _sending = false;
      });
    } catch (_) {
      setState(() {
        _successTx = {
          'transfer_id': 'trf_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
          'source_amount': amt.toStringAsFixed(2),
          'source_currency': _sourceCurrency,
          'recipient_name': recipientName,
          'destination_currency': _destCurrency,
          'destination_amount': _quote?['destination_amount'] ?? '',
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

    final currencyOptions = <String>{'USD', 'GBP', ..._walletBalances.keys}.toList();
    final currentBal = _walletBalances[_sourceCurrency] ?? '0.00';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Send Money Internationally',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
        backgroundColor: isDark ? PayNoraColors.darkSurface : PayNoraColors.brandPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Delivery Rail Selector (PayNora P2P default vs Bank vs Mobile Money)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? PayNoraColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HOW SHOULD RECIPIENT RECEIVE?',
                    style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _railButton(
                      id: 'P2P',
                      icon: Icons.bolt_rounded,
                      title: 'PayNora App',
                      subtitle: 'Instant · Lowest fee',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _railButton(
                      id: 'BANK',
                      icon: Icons.account_balance_rounded,
                      title: 'Bank Account',
                      subtitle: 'Local currency',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _railButton(
                      id: 'MOMO',
                      icon: Icons.phone_android_rounded,
                      title: 'Mobile Money',
                      subtitle: 'MoMo / M-Pesa',
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Recipient Card (adapts to P2P vs Bank vs MoMo)
          if (_payoutMethod == 'P2P')
            _buildP2PRecipientCard(isDark)
          else
            _buildExternalRecipientCard(isDark),

          const SizedBox(height: 16),

          // 3. Amount & Currency Card (Default Foreign Currencies: USD & GBP)
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('YOU SEND',
                        style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('Balance: $_sourceCurrency $currentBal',
                        style: const TextStyle(
                            color: PayNoraColors.brandSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : PayNoraColors.brandPrimary),
                        decoration: const InputDecoration(border: InputBorder.none, hintText: '0.00'),
                        onChanged: (_) => _fetchQuote(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? PayNoraColors.darkCardSubtle : PayNoraColors.lightCardSubtle,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: _sourceCurrency,
                        underline: const SizedBox(),
                        dropdownColor: isDark ? PayNoraColors.darkSurface : Colors.white,
                        items: currencyOptions.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c, style: const TextStyle(fontWeight: FontWeight.w900)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _sourceCurrency = val);
                            _fetchQuote();
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // In P2P mode, recipient has a PayNora multi-currency wallet (Local + USD + GBP),
                // so sender can choose whether they receive Local Currency or hold Sent Currency (USD/GBP).
                // In Bank/MoMo mode, local banks only accept local currency.
                const Text('RECIPIENT RECEIVES AS',
                    style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (_payoutMethod == 'P2P')
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _recipientMode = 'LOCAL');
                            _fetchQuote();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: _recipientMode == 'LOCAL'
                                  ? PayNoraColors.brandSecondary.withOpacity(0.15)
                                  : (isDark ? PayNoraColors.darkCardSubtle : PayNoraColors.lightCardSubtle),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _recipientMode == 'LOCAL'
                                      ? PayNoraColors.brandSecondary
                                      : Colors.transparent),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Local Currency (${_p2pRecipient?['local_currency'] ?? _destCurrency})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _recipientMode == 'LOCAL'
                                        ? PayNoraColors.brandSecondary
                                        : (isDark ? Colors.white : Colors.black),
                                  ),
                                ),
                                const Text('Auto-converted into local wallet',
                                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _recipientMode = 'ORIGINAL');
                            _fetchQuote();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: _recipientMode == 'ORIGINAL'
                                  ? PayNoraColors.brandSecondary.withOpacity(0.15)
                                  : (isDark ? PayNoraColors.darkCardSubtle : PayNoraColors.lightCardSubtle),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _recipientMode == 'ORIGINAL'
                                      ? PayNoraColors.brandSecondary
                                      : Colors.transparent),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sent Currency ($_sourceCurrency)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _recipientMode == 'ORIGINAL'
                                        ? PayNoraColors.brandSecondary
                                        : (isDark ? Colors.white : Colors.black),
                                  ),
                                ),
                                const Text('0 fee · Holds in PayNora wallet',
                                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PayNoraColors.brandSecondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PayNoraColors.brandSecondary.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: PayNoraColors.brandSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Local Currency ($_destCurrency) — Bank & Mobile Money payouts settle directly in local currency. Use PayNora App-to-App if the recipient wants to hold USD or GBP.',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Estimated Recipient Payout
                const Text('ESTIMATED RECIPIENT PAYOUT',
                    style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_quote != null ? _quote!['destination_amount'] : '...'} $_effectiveDestCurrency',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900, color: PayNoraColors.brandSecondary),
                    ),
                    if (_calculating)
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: PayNoraColors.brandSecondary)),
                  ],
                ),
                if (_quote != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Rate: 1 $_sourceCurrency = ${_quote!['rate'] ?? _quote!['exchange_rate'] ?? '1.0'} $_effectiveDestCurrency  ·  Fee: ${_quote!['fee'] ?? '0.00'} $_sourceCurrency',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. Action Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: PayNoraColors.brandSecondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _sending ? null : _executeSend,
              icon: _sending
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.fingerprint),
              label: Text(
                _payoutMethod == 'P2P'
                    ? 'Send Instantly via PayNora'
                    : 'Authorize & Send to ${_payoutMethod == 'BANK' ? 'Bank' : 'Mobile Money'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
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

  Widget _railButton({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    final active = _payoutMethod == id;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _payoutMethod = id;
            if (id != 'P2P') _recipientMode = 'LOCAL';
          });
          _fetchQuote();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: active ? PayNoraColors.brandSecondary.withOpacity(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? PayNoraColors.brandSecondary
                  : (isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
              width: active ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: active ? PayNoraColors.brandSecondary : Colors.grey, size: 22),
              const SizedBox(height: 6),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: active ? PayNoraColors.brandSecondary : null)),
              const SizedBox(height: 2),
              Text(subtitle,
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildP2PRecipientCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? PayNoraColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PAYNORA RECIPIENT (APP-TO-APP)',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _p2pLookupController,
            onChanged: _onP2PQueryChanged,
            decoration: InputDecoration(
              hintText: '@tag, phone number, or email',
              prefixIcon: const Icon(Icons.alternate_email),
              suffixIcon: _lookingUpP2P
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _lookupP2PUser(_p2pLookupController.text.trim()),
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              {'tag': '@chidi', 'label': '🇳🇬 @chidi'},
              {'tag': '@sarah', 'label': '🇬🇧 @sarah'},
              {'tag': '@kwame', 'label': '🇬🇭 @kwame'},
            ].map((demo) {
              return ActionChip(
                label: Text(demo['label']!, style: const TextStyle(fontSize: 11)),
                onPressed: () {
                  _p2pLookupController.text = demo['tag']!;
                  _lookupP2PUser(demo['tag']!);
                },
              );
            }).toList(),
          ),
          if (_p2pRecipient != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PayNoraColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: PayNoraColors.success, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_p2pRecipient!['display_name']} (${_p2pRecipient!['tag'] ?? 'Verified'})',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: PayNoraColors.success),
                        ),
                        Text(
                          'Country: ${_p2pRecipient!['country_iso']} · Local Wallet: ${_p2pRecipient!['local_currency']} · Foreign Wallets: USD, GBP',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_p2pLookupError != null) ...[
            const SizedBox(height: 8),
            Text(_p2pLookupError!, style: const TextStyle(color: PayNoraColors.error, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Note (Optional)',
              hintText: 'e.g. Family support, Invoice',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalRecipientCard(bool isDark) {
    final route = GatewayRouting.forCurrency(_destCurrency);
    final g = route.recommended;
    final color = g == GatewayRouting.paystack ? const Color(0xFF00C3F7) : const Color(0xFFFB9129);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? PayNoraColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DESTINATION COUNTRY',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _destCountry,
            isExpanded: true,
            dropdownColor: isDark ? PayNoraColors.darkSurface : Colors.white,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: _countries.map((c) {
              return DropdownMenuItem<String>(
                value: c['code'],
                child: Text('${c['flag']} ${c['name']} (${c['curr']})'),
              );
            }).toList(),
            onChanged: (code) {
              if (code != null) {
                final country = _countries.firstWhere((c) => c['code'] == code);
                setState(() {
                  _destCountry = code;
                  _destCurrency = country['curr']!;
                });
                _loadBanks();
                _fetchQuote();
              }
            },
          ),
          const SizedBox(height: 16),
          if (_payoutMethod == 'BANK') ...[
            const Text('RECIPIENT BANK',
                style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _loadingBanks
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedBank?['code']?.toString(),
                    hint: const Text('Select recipient bank'),
                    dropdownColor: isDark ? PayNoraColors.darkSurface : Colors.white,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: _banks
                        .map((b) => DropdownMenuItem<String>(
                              value: '${b['code']}',
                              child: Text('${b['name']}', overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (code) {
                      setState(() {
                        _selectedBank = _banks.firstWhere((b) => '${b['code']}' == code);
                        _resolvedBankAccountName = null;
                      });
                      if (_accountNumberController.text.trim().length >= 10) {
                        _resolveBankAccount();
                      }
                    },
                  ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              onChanged: _onBankAccountChanged,
              decoration: InputDecoration(
                labelText: 'Account Number / IBAN',
                suffixIcon: _resolvingBank
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_resolvedBankAccountName != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PayNoraColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: PayNoraColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _resolvedBankAccountName!,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: PayNoraColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_bankResolveError != null) ...[
              const SizedBox(height: 6),
              Text(_bankResolveError!, style: const TextStyle(fontSize: 11, color: Colors.orange)),
            ],
          ] else ...[
            const Text('MOBILE MONEY NETWORK',
                style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _momoProvider,
              dropdownColor: isDark ? PayNoraColors.darkSurface : Colors.white,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: ['MTN MoMo', 'M-Pesa (Safaricom)', 'Airtel Money', 'Telecel Cash']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _momoProvider = v ?? 'MTN MoMo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile Money Phone Number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _recipientNameController,
            decoration: InputDecoration(
              labelText: 'Recipient Legal Full Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
                    'Smart routing: $_destCurrency payout via ${GatewayRouting.label(g)} · ${route.reason}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen(bool isDark) {
    final isP2P = _successTx!['type'] == 'APP_TO_APP';
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
              Text(isP2P ? 'Instant PayNora Transfer Sent!' : 'Transfer Dispatched!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(
                'Reference: ${_successTx!['transfer_id']}\n'
                'Sent ${_successTx!['source_amount']} ${_successTx!['source_currency']} to ${_successTx!['recipient_name']}\n'
                'Recipient gets: ${_successTx!['destination_amount'] ?? ''} ${_successTx!['destination_currency'] ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
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
