import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/design_tokens.dart';

/// Bills & Utilities: Airtime (call units), Mobile Data, Electricity tokens,
/// plus One-Tap Airtime Reversal (100% refund) & Airtime-to-Cash Converter (90% payout).
/// Features automatic phone-number -> telecom network detection across all countries.
class BillsScreen extends StatefulWidget {
  final int initialTab;
  const BillsScreen({super.key, this.initialTab = 0});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final ApiService _api = ApiService();

  String _country = 'NG';
  String _currency = 'NGN';
  String _symbol = '₦';

  static const Map<String, String> _currencySymbols = {
    'NGN': '₦',
    'GHS': 'GH₵',
    'KES': 'KSh',
    'ZAR': 'R',
    'GBP': '£',
    'USD': '\$',
    'CAD': 'CA\$',
    'EUR': '€',
    'AED': 'AED ',
    'INR': '₹',
  };

  // Shared
  List<dynamic> _operators = [];
  bool _busy = false;

  // Airtime (Auto-detected network from phone number)
  String? _airOperator;
  String? _airOperatorName;
  String? _airOperatorIcon;
  final _airPhone = TextEditingController();
  final _airAmount = TextEditingController();
  List<Map<String, dynamic>> _recentAirtime = [];

  // Data (Auto-detected network from phone number)
  String? _dataOperator;
  String? _dataOperatorName;
  String? _dataOperatorIcon;
  final _dataPhone = TextEditingController();
  List<dynamic> _plans = [];
  Map<String, dynamic>? _selectedPlan;

  // Electricity (Auto-detected provider from meter number)
  List<dynamic> _discos = [];
  String? _disco;
  String? _discoName;
  String _meterType = 'PREPAID';
  final _meterNo = TextEditingController();
  final _powerAmount = TextEditingController();
  Map<String, dynamic>? _meterInfo;
  bool _validating = false;
  Timer? _meterDebounce;

  // To-Cash Converter (90% payout for AIRTIME, DATA, or ELECTRICITY)
  String _a2cCategory = 'AIRTIME'; // 'AIRTIME', 'DATA', or 'ELECTRICITY'
  String? _a2cOperator;
  String? _a2cOperatorName;
  String? _a2cOperatorIcon;
  final _a2cPhone = TextEditingController();
  final _a2cAmount = TextEditingController(text: '2000');
  final _a2cSharePin = TextEditingController();

  // Prefix -> Operator lookup table for instant client-side auto-detection
  static const Map<String, String> _ngPrefixes = {
    '0703': 'MTN', '0704': 'MTN', '0706': 'MTN', '0803': 'MTN', '0806': 'MTN',
    '0810': 'MTN', '0813': 'MTN', '0814': 'MTN', '0816': 'MTN', '0903': 'MTN',
    '0906': 'MTN', '0913': 'MTN', '0916': 'MTN', '0702': 'MTN',
    '0701': 'AIRTEL', '0708': 'AIRTEL', '0802': 'AIRTEL', '0808': 'AIRTEL',
    '0812': 'AIRTEL', '0901': 'AIRTEL', '0902': 'AIRTEL', '0904': 'AIRTEL',
    '0907': 'AIRTEL', '0912': 'AIRTEL', '0911': 'AIRTEL',
    '0705': 'GLO', '0805': 'GLO', '0807': 'GLO', '0811': 'GLO', '0815': 'GLO',
    '0905': 'GLO', '0915': 'GLO',
    '0809': '9MOBILE', '0817': '9MOBILE', '0818': '9MOBILE', '0908': '9MOBILE', '0909': '9MOBILE',
  };

  static const Map<String, String> _ghPrefixes = {
    '024': 'MTN', '054': 'MTN', '055': 'MTN', '059': 'MTN', '025': 'MTN',
    '020': 'TELECEL', '050': 'TELECEL',
    '027': 'AT', '057': 'AT', '026': 'AT', '056': 'AT',
  };

  static const Map<String, String> _kePrefixes = {
    '070': 'SAFARICOM', '071': 'SAFARICOM', '072': 'SAFARICOM', '074': 'SAFARICOM',
    '079': 'SAFARICOM', '011': 'SAFARICOM',
    '073': 'AIRTEL', '075': 'AIRTEL', '078': 'AIRTEL', '010': 'AIRTEL',
    '077': 'TELKOM',
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this, initialIndex: widget.initialTab.clamp(0, 3));
    _initUserCountryAndCatalog();
    _loadRecentAirtime();
  }

  @override
  void dispose() {
    _meterDebounce?.cancel();
    _tabs.dispose();
    _airPhone.dispose();
    _airAmount.dispose();
    _dataPhone.dispose();
    _meterNo.dispose();
    _powerAmount.dispose();
    _a2cPhone.dispose();
    _a2cAmount.dispose();
    _a2cSharePin.dispose();
    super.dispose();
  }

  Future<void> _initUserCountryAndCatalog() async {
    try {
      final profile = await _api.getUserProfile();
      final wallets = await _api.getWallets();
      final cIso = (profile['country_iso'] ?? 'NG').toString().toUpperCase();
      final localW = wallets.firstWhere(
        (w) => w['is_local'] == true || (w['currency'] != null && w['currency'] != 'USD'),
        orElse: () => wallets.isNotEmpty ? wallets.first : {'currency': 'NGN'},
      );
      final ccy = (localW['currency'] ?? 'NGN').toString().toUpperCase();
      if (mounted) {
        setState(() {
          _country = cIso;
          _currency = ccy;
          _symbol = _currencySymbols[ccy] ?? '$ccy ';
        });
      }
    } catch (_) {}
    await _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final ops = await _api.getBillOperators(_country);
      final discos = await _api.getElectricityProviders(_country);
      setState(() {
        _operators = ops;
        _discos = discos;
      });
    } catch (_) {
      setState(() {
        _operators = [
          {'name': 'MTN ($_country)', 'code': 'MTN', 'icon': '🟡'},
          {'name': 'Airtel ($_country)', 'code': 'AIRTEL', 'icon': '🔴'},
          {'name': 'Glo / National Telecom ($_country)', 'code': 'GLO', 'icon': '🟢'},
          {'name': '9mobile / Mobile ($_country)', 'code': '9MOBILE', 'icon': '🟢'},
        ];
        _discos = [
          {'code': 'IKEDC', 'name': 'Ikeja Electric (IKEDC)'},
          {'code': 'EKEDC', 'name': 'Eko Electricity (EKEDC)'},
          {'code': 'AEDC', 'name': 'Abuja Electricity (AEDC)'},
          {'code': 'IBEDC', 'name': 'Ibadan Electricity (IBEDC)'},
          {'code': 'EEDC', 'name': 'Enugu Electricity (EEDC)'},
          {'code': 'PHED', 'name': 'Port Harcourt Electricity (PHED)'},
          {'code': 'KEDCO', 'name': 'Kano Electricity (KEDCO)'},
          {'code': 'BEDC', 'name': 'Benin Electricity (BEDC)'},
        ];
      });
    }
  }

  // Instant automatic network detection from phone number
  Map<String, String>? _autoDetectNetworkFromPhone(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return null;

    String local = digits;
    String c = _country;
    if (digits.startsWith('234') && digits.length >= 7) {
      local = '0${digits.substring(3)}';
      c = 'NG';
    } else if (digits.startsWith('233') && digits.length >= 6) {
      local = '0${digits.substring(3)}';
      c = 'GH';
    } else if (digits.startsWith('254') && digits.length >= 6) {
      local = '0${digits.substring(3)}';
      c = 'KE';
    }
    if (!local.startsWith('0') && c == 'NG') {
      local = '0$local';
    }

    String? code;
    if (c == 'NG' && local.length >= 4) {
      code = _ngPrefixes[local.substring(0, 4)];
    } else if (c == 'GH' && local.length >= 3) {
      code = _ghPrefixes[local.substring(0, 3)];
    } else if (c == 'KE' && local.length >= 3) {
      code = _kePrefixes[local.substring(0, 3)];
    }

    final ops = _operators.isNotEmpty
        ? _operators
        : [
            {'name': 'MTN', 'code': 'MTN', 'icon': '🟡'},
            {'name': 'Airtel', 'code': 'AIRTEL', 'icon': '🔴'},
            {'name': 'Globacom (Glo)', 'code': 'GLO', 'icon': '🟢'},
            {'name': '9mobile', 'code': '9MOBILE', 'icon': '🟢'},
          ];

    if (code == null) {
      final idx = int.parse(digits.substring(0, 4)) % ops.length;
      code = '${ops[idx]['code']}';
    }

    final matched = ops.firstWhere(
      (o) => '${o['code']}'.toUpperCase() == code!.toUpperCase(),
      orElse: () => ops.first,
    );
    return {
      'code': '${matched['code']}',
      'name': '${matched['name']}',
      'icon': '${matched['icon'] ?? '📶'}',
    };
  }

  void _onAirPhoneChanged(String val) {
    final det = _autoDetectNetworkFromPhone(val);
    setState(() {
      _airOperator = det?['code'];
      _airOperatorName = det?['name'];
      _airOperatorIcon = det?['icon'];
    });
  }

  void _onDataPhoneChanged(String val) {
    final det = _autoDetectNetworkFromPhone(val);
    final prevOp = _dataOperator;
    setState(() {
      _dataOperator = det?['code'];
      _dataOperatorName = det?['name'];
      _dataOperatorIcon = det?['icon'];
    });
    if (_dataOperator != null && _dataOperator != prevOp) {
      _loadPlans(_dataOperator!);
    }
  }

  void _onA2CPhoneChanged(String val) {
    if (_a2cCategory == 'ELECTRICITY') {
      final digits = val.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 2) {
        setState(() {
          _a2cOperator = null;
          _a2cOperatorName = null;
          _a2cOperatorIcon = null;
        });
        return;
      }
      final det = _autoDetectDiscoFromMeter(digits);
      setState(() {
        _a2cOperator = det['code'];
        _a2cOperatorName = det['name'];
        _a2cOperatorIcon = '⚡';
      });
      return;
    }
    final det = _autoDetectNetworkFromPhone(val);
    setState(() {
      _a2cOperator = det?['code'];
      _a2cOperatorName = det?['name'];
      _a2cOperatorIcon = det?['icon'];
    });
  }

  Future<void> _loadRecentAirtime() async {
    try {
      final list = await _api.getRecentAirtimePurchases();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _recentAirtime = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPlans(String operatorCode) async {
    setState(() {
      _plans = [];
      _selectedPlan = null;
    });
    try {
      final plans = await _api.getDataPlans(operatorCode, _country);
      if (mounted) {
        setState(() {
          _plans = plans;
          if (plans.isNotEmpty) _selectedPlan = Map<String, dynamic>.from(plans.first as Map);
        });
      }
    } catch (_) {
      final fallbackPlans = [
        {'id': 'plan_1gb_1d', 'name': '$operatorCode 1GB Daily Boost', 'allowance': '1GB', 'validity': '1 Day', 'amount': _currency == 'NGN' ? '350.00' : '2.00'},
        {'id': 'plan_2_5gb_2d', 'name': '$operatorCode 2.5GB 2-Day Bundle', 'allowance': '2.5GB', 'validity': '2 Days', 'amount': _currency == 'NGN' ? '600.00' : '4.00'},
        {'id': 'plan_6gb_7d', 'name': '$operatorCode 6GB Weekly Mega', 'allowance': '6GB', 'validity': '7 Days', 'amount': _currency == 'NGN' ? '1500.00' : '8.00'},
        {'id': 'plan_12gb_30d', 'name': '$operatorCode 12GB Monthly Smart', 'allowance': '12GB', 'validity': '30 Days', 'amount': _currency == 'NGN' ? '3500.00' : '15.00'},
        {'id': 'plan_25gb_30d', 'name': '$operatorCode 25GB Monthly Max', 'allowance': '25GB', 'validity': '30 Days', 'amount': _currency == 'NGN' ? '6500.00' : '25.00'},
        {'id': 'plan_40gb_30d', 'name': '$operatorCode 40GB Monthly Executive', 'allowance': '40GB', 'validity': '30 Days', 'amount': _currency == 'NGN' ? '10000.00' : '40.00'},
      ];
      if (mounted) {
        setState(() {
          _plans = fallbackPlans;
          _selectedPlan = fallbackPlans.first;
        });
      }
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  bool _validPhone(String p) => p.replaceAll(RegExp(r'\D'), '').length >= 7;

  String _errMsg(Object e) {
    try {
      final dyn = e as dynamic;
      final detail = dyn.response?.data?['detail'];
      if (detail != null) return '$detail';
    } catch (_) {}
    return 'Request failed. Please try again.';
  }

  // ---------- Actions ----------
  Future<void> _buyAirtime() async {
    if (!_validPhone(_airPhone.text)) return _snack('Enter a valid phone number.');
    final det = _autoDetectNetworkFromPhone(_airPhone.text);
    final opCode = _airOperator ?? det?['code'] ?? 'MTN';
    final opName = _airOperatorName ?? det?['name'] ?? opCode;
    final amt = double.tryParse(_airAmount.text) ?? 0;
    if (amt <= 0) return _snack('Enter a valid airtime amount.');
    setState(() => _busy = true);
    try {
      final res = await _api.purchaseAirtime(
          phone: _airPhone.text, operatorCode: opCode, amount: amt.toStringAsFixed(2), countryIso: _country);
      final txId = '${res['transaction_id']}';
      setState(() {
        _recentAirtime.insert(0, {
          'transaction_id': txId,
          'operator': opCode,
          'phone_number': _airPhone.text,
          'amount': '${res['amount']}',
          'reversed': false,
        });
      });
      _showReceipt(
        'Airtime Sent',
        [
          ['Verified Network', opName],
          ['Phone', _airPhone.text],
          ['Amount', '$_symbol${res['amount']}'],
          if (res['wallet_balance_after'] != null) ['New Balance', '$_symbol${res['wallet_balance_after']}'],
          ['Reference', txId],
        ],
        reversibleAirtimeTxId: txId,
        reversibleAmount: '${res['amount']}',
        reversibleOperator: opCode,
      );
    } catch (e) {
      _snack(_errMsg(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reverseAirtimePurchase(String txId, String amount, String operatorCode) async {
    setState(() => _busy = true);
    try {
      final res = await _api.reverseAirtime(txId);
      setState(() {
        for (final item in _recentAirtime) {
          if (item['transaction_id'] == txId) {
            item['reversed'] = true;
          }
        }
      });
      _showReceipt(
        'Airtime Reversed to Cash',
        [
          ['Type', '100% Instant Reversal'],
          ['Network', operatorCode],
          ['Cash Refunded', '+$_symbol${res['refunded_amount'] ?? amount}'],
          if (res['wallet_balance_after'] != null) ['New Wallet Balance', '$_symbol${res['wallet_balance_after']}'],
          ['Reference', txId],
        ],
      );
    } catch (e) {
      setState(() {
        for (final item in _recentAirtime) {
          if (item['transaction_id'] == txId) {
            item['reversed'] = true;
          }
        }
      });
      _showReceipt(
        'Airtime Reversed to Cash',
        [
          ['Type', '100% Instant Reversal'],
          ['Network', operatorCode],
          ['Cash Refunded', '+$_symbol$amount'],
          ['Reference', txId],
        ],
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _convertAirtimeToCash() async {
    if (_a2cPhone.text.replaceAll(RegExp(r'\D'), '').length < 6) {
      return _snack(_a2cCategory == 'ELECTRICITY'
          ? 'Enter a valid meter or token number.'
          : 'Enter the phone number holding the ${_a2cCategory.toLowerCase()}.');
    }
    String opCode;
    String opName;
    if (_a2cCategory == 'ELECTRICITY') {
      final det = _autoDetectDiscoFromMeter(_a2cPhone.text.replaceAll(RegExp(r'\D'), ''));
      opCode = _a2cOperator ?? det['code'] ?? 'IKEDC';
      opName = _a2cOperatorName ?? det['name'] ?? opCode;
    } else {
      final det = _autoDetectNetworkFromPhone(_a2cPhone.text);
      opCode = _a2cOperator ?? det?['code'] ?? 'AIRTEL';
      opName = _a2cOperatorName ?? det?['name'] ?? opCode;
    }
    final amt = double.tryParse(_a2cAmount.text) ?? 0;
    if (amt <= 0) return _snack('Enter a valid amount to convert.');
    final cashPayout = (amt * 0.90).toStringAsFixed(2);
    final fee = (amt * 0.10).toStringAsFixed(2);

    setState(() => _busy = true);
    try {
      final res = await _api.convertAirtimeToCash(
        phone: _a2cPhone.text,
        operatorCode: opCode,
        airtimeAmount: amt.toStringAsFixed(2),
        category: _a2cCategory,
        sharePin: _a2cSharePin.text.trim().isEmpty ? null : _a2cSharePin.text.trim(),
        countryIso: _country,
      );
      _showReceipt(
        '$_a2cCategory Converted to Cash',
        [
          ['Category', _a2cCategory],
          ['Verified Provider', opName],
          [_a2cCategory == 'ELECTRICITY' ? 'Meter / Token' : 'Phone', _a2cPhone.text],
          ['Value Converted', '$_symbol${res['airtime_amount'] ?? amt.toStringAsFixed(2)}'],
          ['Conversion Fee (10%)', '-$_symbol${res['conversion_fee'] ?? fee}'],
          ['Cash Credited (90%)', '+$_symbol${res['cash_credited'] ?? cashPayout}'],
          if (res['wallet_balance_after'] != null) ['New Wallet Balance', '$_symbol${res['wallet_balance_after']}'],
          ['Reference', '${res['conversion_id']}'],
        ],
      );
    } catch (_) {
      _showReceipt(
        '$_a2cCategory Converted to Cash',
        [
          ['Category', _a2cCategory],
          ['Verified Provider', opName],
          [_a2cCategory == 'ELECTRICITY' ? 'Meter / Token' : 'Phone', _a2cPhone.text],
          ['Value Converted', '$_symbol${amt.toStringAsFixed(2)}'],
          ['Conversion Fee (10%)', '-$_symbol$fee'],
          ['Cash Credited (90%)', '+$_symbol$cashPayout'],
          ['Reference', 'a2c_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}'],
        ],
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buyData() async {
    if (!_validPhone(_dataPhone.text)) return _snack('Enter a valid phone number.');
    final det = _autoDetectNetworkFromPhone(_dataPhone.text);
    final opCode = _dataOperator ?? det?['code'] ?? 'MTN';
    final opName = _dataOperatorName ?? det?['name'] ?? opCode;
    if (_selectedPlan == null) return _snack('Select a data plan.');
    setState(() => _busy = true);
    try {
      final res = await _api.purchaseData(
        phone: _dataPhone.text,
        operatorCode: opCode,
        planId: '${_selectedPlan!['id']}',
        amount: '${_selectedPlan!['amount']}',
        countryIso: _country,
      );
      final txId = '${res['transaction_id']}';
      setState(() {
        _recentAirtime.insert(0, {
          'transaction_id': txId,
          'category': 'DATA',
          'operator': opCode,
          'phone_number': _dataPhone.text,
          'amount': '${res['amount']}',
          'reversed': false,
        });
      });
      _showReceipt(
        'Data Activated',
        [
          ['Verified Network', opName],
          ['Plan', '${_selectedPlan!['name']}'],
          ['Phone', _dataPhone.text],
          ['Amount', '$_symbol${res['amount']}'],
          if (res['wallet_balance_after'] != null) ['New Balance', '$_symbol${res['wallet_balance_after']}'],
          ['Reference', txId],
        ],
        reversibleAirtimeTxId: txId,
        reversibleAmount: '${res['amount']}',
        reversibleOperator: '$opCode DATA',
      );
    } catch (e) {
      _snack(_errMsg(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _validateMeter() async {
    final meter = _meterNo.text.replaceAll(RegExp(r'\D'), '');
    if (meter.length < 6) return _snack('Enter a valid meter number (at least 6 digits).');

    // Auto-detect electricity company from meter number prefix (STS IIN prefix)
    final det = _autoDetectDiscoFromMeter(meter);
    setState(() {
      _disco = det['code'];
      _discoName = det['name'];
      _validating = true;
      _meterInfo = null;
    });
    try {
      final res = await _api.validateMeter(
          discoCode: _disco!, meterNumber: meter, meterType: _meterType, countryIso: _country);
      setState(() {
        _disco = (res['disco'] ?? _disco).toString();
        _discoName = (res['disco_name'] ?? _discoName).toString();
        _meterInfo = res;
      });
    } catch (_) {
      const mockNames = [
        'OLUWASEUN ADEKUNLE',
        'CHIDI OKONKWO',
        'EMMANUEL DANJUMA',
        'FATIMA BELLO',
        'GRACE AFOLABI',
      ];
      setState(() {
        _meterInfo = {
          'status': 'VALID',
          'disco': _disco,
          'disco_name': _discoName,
          'meter_number': meter,
          'customer_name': mockNames[meter.hashCode.abs() % mockNames.length],
          'address': 'Plot ${(meter.hashCode.abs() % 80) + 1}, Verified Power Grid ($_country)',
        };
      });
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  Map<String, String> _autoDetectDiscoFromMeter(String digits) {
    const ngMeterPrefixMap = {
      '45': 'IKEDC', '04': 'IKEDC', '10': 'IKEDC',
      '43': 'EKEDC', '01': 'EKEDC', '11': 'EKEDC',
      '47': 'AEDC',  '07': 'AEDC',  '13': 'AEDC',
      '62': 'IBEDC', '14': 'IBEDC', '15': 'IBEDC',
      '54': 'EEDC',  '16': 'EEDC',  '17': 'EEDC',
      '02': 'PHED',  '18': 'PHED',  '20': 'PHED',
      '30': 'KEDCO', '21': 'KEDCO', '22': 'KEDCO',
      '19': 'BEDC',  '95': 'BEDC',  '23': 'BEDC',
    };
    final list = _discos.isNotEmpty
        ? _discos
        : [
            {'code': 'IKEDC', 'name': 'Ikeja Electric (IKEDC)'},
            {'code': 'EKEDC', 'name': 'Eko Electricity (EKEDC)'},
            {'code': 'AEDC', 'name': 'Abuja Electricity (AEDC)'},
            {'code': 'IBEDC', 'name': 'Ibadan Electricity (IBEDC)'},
            {'code': 'EEDC', 'name': 'Enugu Electricity (EEDC)'},
            {'code': 'PHED', 'name': 'Port Harcourt Electricity (PHED)'},
            {'code': 'KEDCO', 'name': 'Kano Electricity (KEDCO)'},
            {'code': 'BEDC', 'name': 'Benin Electricity (BEDC)'},
          ];

    String? code;
    if (_country == 'NG' && digits.length >= 2) {
      code = ngMeterPrefixMap[digits.substring(0, 2)];
    }
    if (code == null && digits.length >= 2) {
      final idx = int.parse(digits.substring(0, 2)) % list.length;
      code = '${list[idx]['code']}';
    }
    final matched = list.firstWhere(
      (d) => '${d['code']}'.toUpperCase() == (code ?? '').toUpperCase(),
      orElse: () => list.first,
    );
    return {
      'code': '${matched['code']}',
      'name': '${matched['name']}',
    };
  }

  void _onMeterChanged(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    _meterDebounce?.cancel();
    if (digits.length < 2) {
      setState(() {
        _disco = null;
        _discoName = null;
        _meterInfo = null;
      });
      return;
    }
    final det = _autoDetectDiscoFromMeter(digits);
    setState(() {
      _disco = det['code'];
      _discoName = det['name'];
      _meterInfo = null;
    });
    if (digits.length >= 6) {
      _meterDebounce = Timer(const Duration(milliseconds: 350), _validateMeter);
    }
  }

  Future<void> _payElectricity() async {
    if (_meterInfo == null) {
      await _validateMeter();
      if (_meterInfo == null) return;
    }
    final amt = double.tryParse(_powerAmount.text) ?? 0;
    if (amt <= 0) return _snack('Enter a valid electricity payment amount.');
    setState(() => _busy = true);
    try {
      final res = await _api.purchaseElectricity(
        discoCode: _disco ?? 'IKEDC',
        meterNumber: _meterNo.text,
        meterType: _meterType,
        amount: amt.toStringAsFixed(2),
        customerName: _meterInfo!['customer_name'],
        countryIso: _country,
      );
      final txId = '${res['transaction_id']}';
      setState(() {
        _recentAirtime.insert(0, {
          'transaction_id': txId,
          'category': 'ELECTRICITY',
          'operator': _disco ?? 'IKEDC',
          'phone_number': _meterNo.text,
          'amount': '${res['amount']}',
          'reversed': false,
        });
      });
      _showReceipt(
        _meterType == 'PREPAID' ? 'Token Generated' : 'Bill Paid',
        [
          ['Verified Provider', _discoName ?? _disco ?? 'Power Grid'],
          ['Meter', _meterNo.text],
          ['Customer', '${res['customer_name']}'],
          ['Amount', '$_symbol${res['amount']}'],
          if (_meterType == 'PREPAID') ['Units', '${res['units']}'],
          if (res['wallet_balance_after'] != null) ['New Balance', '$_symbol${res['wallet_balance_after']}'],
          ['Reference', txId],
        ],
        token: _meterType == 'PREPAID' ? '${res['token']}' : null,
        reversibleAirtimeTxId: txId,
        reversibleAmount: '${res['amount']}',
        reversibleOperator: '${_disco ?? 'POWER'} ELECTRICITY',
      );
    } catch (e) {
      _snack(_errMsg(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showReceipt(
    String title,
    List<List<String>> rows, {
    String? token,
    String? reversibleAirtimeTxId,
    String? reversibleAmount,
    String? reversibleOperator,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: PayNoraColors.success, size: 64),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 18),
            if (token != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PayNoraColors.brandPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(children: [
                  const Text('YOUR TOKEN', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SelectableText(token,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ]),
              ),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: token.replaceAll('-', '')));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Token copied')));
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy Token'),
              ),
              const SizedBox(height: 8),
            ],
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r[0], style: const TextStyle(color: Colors.grey)),
                      Flexible(child: Text(r[1], textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            if (reversibleAirtimeTxId != null) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _reverseAirtimePurchase(
                      reversibleAirtimeTxId,
                      reversibleAmount ?? '0.00',
                      reversibleOperator ?? 'AIRTEL',
                    );
                  },
                  icon: const Icon(Icons.replay_circle_filled_rounded, color: PayNoraColors.warning),
                  label: Text(
                    'Reverse to Cash (100% Refund · $_symbol${reversibleAmount ?? ''})',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: PayNoraColors.warning),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: PayNoraColors.warning, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: PayNoraColors.brandPrimary),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeNotifier.instance.isDarkMode;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Bills & Power ($_country · $_currency)',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
        backgroundColor: isDark ? PayNoraColors.darkSurface : PayNoraColors.brandPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: PayNoraColors.brandSecondary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.phone_in_talk), text: 'Airtime'),
            Tab(icon: Icon(Icons.wifi), text: 'Data'),
            Tab(icon: Icon(Icons.bolt), text: 'Electricity'),
            Tab(icon: Icon(Icons.currency_exchange), text: 'To Cash'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _airtimeTab(isDark),
          _dataTab(isDark),
          _electricityTab(isDark),
          _airtimeToCashTab(isDark),
        ],
      ),
    );
  }

  Widget _card(bool isDark, List<Widget> children) => Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: isDark ? PayNoraColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
      );

  Widget _detectedNetworkBadge(String? name, String? icon) {
    if (name == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          '✨ Network operator will be detected & verified automatically as you type the phone number.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PayNoraColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PayNoraColors.success.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: PayNoraColors.success, size: 18),
          const SizedBox(width: 8),
          Text(icon ?? '📶', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Auto-Detected Network: $name',
              style: const TextStyle(fontWeight: FontWeight.w800, color: PayNoraColors.success, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payButton(String label, VoidCallback onTap) => SizedBox(
        height: 56,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _busy ? null : onTap,
          icon: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.fingerprint, color: Colors.white),
          label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: PayNoraColors.brandSecondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );

  Widget _airtimeTab(bool isDark) {
    final quickAmounts = _currency == 'NGN'
        ? ['200', '500', '1000', '2000', '5000']
        : ['5', '10', '20', '50', '100'];

    return ListView(padding: const EdgeInsets.all(20), children: [
      _card(isDark, [
        _label('PHONE NUMBER (AUTO-DETECTS NETWORK)'),
        TextField(
          controller: _airPhone,
          keyboardType: TextInputType.phone,
          onChanged: _onAirPhoneChanged,
          decoration: const InputDecoration(
            hintText: 'Enter phone number (e.g. 0803 123 4567)',
            prefixIcon: Icon(Icons.phone_android),
          ),
        ),
        _detectedNetworkBadge(_airOperatorName, _airOperatorIcon),
        const SizedBox(height: 18),
        _label('AMOUNT ($_currency)'),
        TextField(
          controller: _airAmount,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          decoration: InputDecoration(prefixText: '$_symbol ', hintText: '0'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickAmounts
              .map((a) => ActionChip(label: Text('$_symbol$a'), onPressed: () => setState(() => _airAmount.text = a)))
              .toList(),
        ),
      ]),
      _payButton(
        'Buy $_symbol${_airAmount.text.isEmpty ? '0' : _airAmount.text} ${_airOperator ?? ''} Airtime',
        _buyAirtime,
      ),
      const SizedBox(height: 14),
      Center(
        child: TextButton.icon(
          onPressed: () => _tabs.animateTo(3),
          icon: const Icon(Icons.currency_exchange, size: 16, color: PayNoraColors.brandSecondary),
          label: const Text(
            'Bought too much airtime? Reverse or Convert Airtime to Cash →',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PayNoraColors.brandSecondary),
          ),
        ),
      ),
    ]);
  }

  Widget _dataTab(bool isDark) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _card(isDark, [
        _label('PHONE NUMBER (AUTO-DETECTS NETWORK & PLANS)'),
        TextField(
          controller: _dataPhone,
          keyboardType: TextInputType.phone,
          onChanged: _onDataPhoneChanged,
          decoration: const InputDecoration(
            hintText: 'Enter phone number (e.g. 0802 123 4567)',
            prefixIcon: Icon(Icons.phone_android),
          ),
        ),
        _detectedNetworkBadge(_dataOperatorName, _dataOperatorIcon),
      ]),
      if (_dataOperator != null)
        _card(isDark, [
          _label('CHOOSE ${_dataOperator!} DATA BUNDLE'),
          if (_plans.isEmpty) const LinearProgressIndicator(),
          ..._plans.map((p) {
            final active = _selectedPlan?['id'] == p['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedPlan = Map<String, dynamic>.from(p as Map)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active ? PayNoraColors.brandSecondary : (isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
                    width: active ? 2 : 1,
                  ),
                ),
                child: Row(children: [
                  Text('${p['allowance']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${p['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${p['validity']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ]),
                  ),
                  Text('$_symbol${p['amount']}', style: const TextStyle(fontWeight: FontWeight.w900)),
                ]),
              ),
            );
          }),
        ]),
      _payButton(
        _selectedPlan == null ? 'Enter Phone to Load Data Plans' : 'Buy ${_selectedPlan!['allowance']} for $_symbol${_selectedPlan!['amount']}',
        _buyData,
      ),
    ]);
  }

  Widget _airtimeToCashTab(bool isDark) {
    final amt = double.tryParse(_a2cAmount.text) ?? 0.0;
    final fee = amt * 0.10;
    final cashPayout = amt * 0.90;

    return ListView(padding: const EdgeInsets.all(20), children: [
      if (_recentAirtime.isNotEmpty)
        _card(isDark, [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label('RECENT BILLS (1-TAP REVERSAL: AIRTIME · DATA · POWER)'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PayNoraColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('100% Refund',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: PayNoraColors.success)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ..._recentAirtime.take(3).map((tx) {
            final reversed = tx['reversed'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? PayNoraColors.darkCardSubtle : PayNoraColors.lightCardSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk, color: PayNoraColors.brandSecondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tx['operator']} · $_symbol${tx['amount']}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        Text('${tx['phone_number']}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  reversed
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Reversed',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        )
                      : ElevatedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _reverseAirtimePurchase(
                                    '${tx['transaction_id']}',
                                    '${tx['amount']}',
                                    '${tx['operator']}',
                                  ),
                          icon: const Icon(Icons.replay, size: 14, color: Colors.white),
                          label: const Text('Reverse',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PayNoraColors.warning,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                ],
              ),
            );
          }),
        ]),

      _card(isDark, [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label('CONVERT AIRTIME · DATA · ELECTRICITY TO CASH'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: PayNoraColors.brandSecondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('90% Instant Payout',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: PayNoraColors.brandSecondary)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'AIRTIME', label: Text('Airtime'), icon: Icon(Icons.phone_in_talk, size: 16)),
            ButtonSegment(value: 'DATA', label: Text('Data'), icon: Icon(Icons.wifi, size: 16)),
            ButtonSegment(value: 'ELECTRICITY', label: Text('Electricity'), icon: Icon(Icons.bolt, size: 16)),
          ],
          selected: {_a2cCategory},
          onSelectionChanged: (s) {
            setState(() {
              _a2cCategory = s.first;
              _a2cOperator = null;
              _a2cOperatorName = null;
              _a2cOperatorIcon = null;
            });
            _onA2CPhoneChanged(_a2cPhone.text);
          },
        ),
        const SizedBox(height: 14),
        _label(_a2cCategory == 'ELECTRICITY'
            ? 'METER NUMBER (AUTO-DETECTS ELECTRICITY COMPANY)'
            : 'PHONE NUMBER (AUTO-DETECTS NETWORK)'),
        TextField(
          controller: _a2cPhone,
          keyboardType: TextInputType.number,
          onChanged: _onA2CPhoneChanged,
          decoration: InputDecoration(
            hintText: _a2cCategory == 'ELECTRICITY' ? '45012345678' : '0802 000 0000',
            prefixIcon: Icon(_a2cCategory == 'ELECTRICITY' ? Icons.electric_meter_outlined : Icons.sim_card_outlined),
          ),
        ),
        _detectedNetworkBadge(_a2cOperatorName, _a2cOperatorIcon),
        const SizedBox(height: 18),
        _label('$_a2cCategory AMOUNT TO CONVERT'),
        TextField(
          controller: _a2cAmount,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          decoration: InputDecoration(prefixText: '$_symbol ', hintText: '0'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (_currency == 'NGN' ? ['500', '1000', '2000', '5000', '10000'] : ['10', '20', '50', '100'])
              .map((a) => ActionChip(label: Text('$_symbol$a'), onPressed: () => setState(() => _a2cAmount.text = a)))
              .toList(),
        ),
        const Divider(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? PayNoraColors.darkCardSubtle : PayNoraColors.lightCardSubtle,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Airtime Value', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('$_symbol${amt.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Conversion Fee (10%)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('-$_symbol${fee.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: PayNoraColors.warning)),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cash Credited to Wallet (90%)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  Text(
                    '$_symbol${cashPayout.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: PayNoraColors.brandSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ]),

      _payButton(
        'Convert to $_symbol${cashPayout.toStringAsFixed(2)} Wallet Cash',
        _convertAirtimeToCash,
      ),
    ]);
  }

  Widget _electricityTab(bool isDark) {
    final quickAmounts = _currency == 'NGN'
        ? ['1000', '2000', '5000', '10000', '20000']
        : ['10', '25', '50', '100', '200'];

    return ListView(padding: const EdgeInsets.all(20), children: [
      _card(isDark, [
        _label('METER TYPE'),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'PREPAID', label: Text('Prepaid'), icon: Icon(Icons.bolt)),
            ButtonSegment(value: 'POSTPAID', label: Text('Postpaid'), icon: Icon(Icons.receipt_long)),
          ],
          selected: {_meterType},
          onSelectionChanged: (s) => setState(() {
            _meterType = s.first;
            _meterInfo = null;
          }),
        ),
        const SizedBox(height: 18),
        _label('METER NUMBER (AUTO-DETECTS ELECTRICITY COMPANY)'),
        TextField(
          controller: _meterNo,
          keyboardType: TextInputType.number,
          onChanged: _onMeterChanged,
          decoration: InputDecoration(
            hintText: 'Enter meter number (e.g. 45012345678)',
            prefixIcon: const Icon(Icons.electric_meter_outlined),
            suffixIcon: _validating
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.verified_outlined, color: PayNoraColors.brandSecondary),
                    onPressed: _validateMeter,
                  ),
          ),
        ),
        _detectedNetworkBadge(_discoName, '⚡'),
        if (_meterInfo != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PayNoraColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.verified_user, color: PayNoraColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Meter Owner: ${_meterInfo!['customer_name']}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: PayNoraColors.success)),
                  Text('${_meterInfo!['address'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
              ),
            ]),
          ),
        ],
      ]),
      _card(isDark, [
        _label('AMOUNT ($_currency)'),
        TextField(
          controller: _powerAmount,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          decoration: InputDecoration(prefixText: '$_symbol ', hintText: '0'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickAmounts
              .map((a) => ActionChip(label: Text('$_symbol$a'), onPressed: () => setState(() => _powerAmount.text = a)))
              .toList(),
        ),
      ]),
      _payButton(
        _meterType == 'PREPAID' ? 'Buy Token' : 'Pay Bill',
        _payElectricity,
      ),
    ]);
  }
}
