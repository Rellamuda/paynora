import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/design_tokens.dart';

/// Bills & Utilities (Nigeria Only): Airtime, Mobile Data, and Electricity tokens.
/// Uses live backend network verification (ported-number safe) and live Flutterwave meter validation.
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
  bool _profileLoaded = false;
  final String _currency = 'NGN';
  final String _symbol = '₦';

  // Shared
  List<Map<String, String>> _operators = [
    {'name': 'MTN Nigeria', 'code': 'MTN', 'icon': '🟡'},
    {'name': 'Airtel Nigeria', 'code': 'AIRTEL', 'icon': '🔴'},
    {'name': 'Globacom (Glo)', 'code': 'GLO', 'icon': '🟢'},
    {'name': '9mobile', 'code': '9MOBILE', 'icon': '🟢'},
  ];
  bool _busy = false;

  // Airtime
  String? _airOperator;
  String? _airOperatorName;
  String? _airOperatorIcon;
  bool _airVerified = false;
  bool? _airPorted;
  String? _airDetectMsg;
  bool _airDetecting = false;
  Timer? _airDebounce;
  final _airPhone = TextEditingController();
  final _airAmount = TextEditingController();

  // Data
  String? _dataOperator;
  String? _dataOperatorName;
  String? _dataOperatorIcon;
  bool _dataVerified = false;
  bool? _dataPorted;
  String? _dataDetectMsg;
  bool _dataDetecting = false;
  Timer? _dataDebounce;
  final _dataPhone = TextEditingController();
  List<dynamic> _plans = [];
  Map<String, dynamic>? _selectedPlan;

  // Electricity (Live utility validation — no hardcoded mock names)
  List<dynamic> _discos = [];
  String? _manualDisco;
  String? _disco;
  String? _discoName;
  String _meterType = 'PREPAID';
  final _meterNo = TextEditingController();
  final _powerAmount = TextEditingController();
  Map<String, dynamic>? _meterInfo;
  String? _meterError;
  bool _validating = false;
  Timer? _meterDebounce;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));
    _initUserCountryAndCatalog();
  }

  @override
  void dispose() {
    _airDebounce?.cancel();
    _dataDebounce?.cancel();
    _meterDebounce?.cancel();
    _tabs.dispose();
    _airPhone.dispose();
    _airAmount.dispose();
    _dataPhone.dispose();
    _meterNo.dispose();
    _powerAmount.dispose();
    super.dispose();
  }

  Future<void> _initUserCountryAndCatalog() async {
    try {
      final profile = await _api.getUserProfile();
      final cIso = (profile['country_iso'] ?? 'NG').toString().toUpperCase();
      if (mounted) {
        setState(() {
          _country = cIso;
          _profileLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _profileLoaded = true);
    }
    if (_country == 'NG') {
      await _loadCatalog();
    }
  }

  Future<void> _loadCatalog() async {
    try {
      final ops = await _api.getBillOperators('NG');
      final discos = await _api.getElectricityProviders('NG');
      if (mounted) {
        setState(() {
          if (ops.isNotEmpty) {
            _operators = ops
                .map((e) => {
                      'name': '${e['name']}',
                      'code': '${e['code']}',
                      'icon': '${e['icon'] ?? '📶'}',
                    })
                .toList();
          }
          _discos = discos;
        });
      }
    } catch (_) {}
  }

  // ---------- Live Backend Mobile Network Detection (Ported-Number Safe) ----------
  Future<void> _detectNetworkRemote({
    required String rawPhone,
    required void Function(Map<String, dynamic> res) onResult,
    required void Function(bool loading) onLoading,
  }) async {
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return;
    onLoading(true);
    try {
      final res = await _api.detectOperator(rawPhone.trim(), 'NG');
      if (!mounted) return;
      onResult(res);
    } catch (e) {
      if (!mounted) return;
      onResult({
        'detected': false,
        'verified': false,
        'message': _errMsg(e),
      });
    } finally {
      if (mounted) onLoading(false);
    }
  }

  void _onAirPhoneChanged(String val) {
    _airDebounce?.cancel();
    final digits = val.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      setState(() {
        _airOperator = null;
        _airOperatorName = null;
        _airOperatorIcon = null;
        _airVerified = false;
        _airPorted = null;
        _airDetectMsg = null;
        _airDetecting = false;
      });
      return;
    }
    _airDebounce = Timer(const Duration(milliseconds: 350), () {
      _detectNetworkRemote(
        rawPhone: val,
        onLoading: (l) => setState(() => _airDetecting = l),
        onResult: (res) {
          setState(() {
            if (res['detected'] == true) {
              _airOperator = res['operator_code']?.toString();
              _airOperatorName = res['operator_name']?.toString();
              _airOperatorIcon = res['icon']?.toString() ?? '📶';
              _airVerified = res['verified'] == true;
              _airPorted = res['ported'] is bool ? res['ported'] as bool : null;
              _airDetectMsg = res['message']?.toString();
            } else {
              _airOperator = null;
              _airOperatorName = null;
              _airVerified = false;
              _airPorted = null;
              _airDetectMsg = res['message']?.toString() ?? 'Could not auto-detect network. Tap Change to select.';
            }
          });
        },
      );
    });
  }

  void _onDataPhoneChanged(String val) {
    _dataDebounce?.cancel();
    final digits = val.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      setState(() {
        _dataOperator = null;
        _dataOperatorName = null;
        _dataOperatorIcon = null;
        _dataVerified = false;
        _dataPorted = null;
        _dataDetectMsg = null;
        _dataDetecting = false;
        _plans = [];
        _selectedPlan = null;
      });
      return;
    }
    _dataDebounce = Timer(const Duration(milliseconds: 350), () {
      _detectNetworkRemote(
        rawPhone: val,
        onLoading: (l) => setState(() => _dataDetecting = l),
        onResult: (res) {
          final prevOp = _dataOperator;
          setState(() {
            if (res['detected'] == true) {
              _dataOperator = res['operator_code']?.toString();
              _dataOperatorName = res['operator_name']?.toString();
              _dataOperatorIcon = res['icon']?.toString() ?? '📶';
              _dataVerified = res['verified'] == true;
              _dataPorted = res['ported'] is bool ? res['ported'] as bool : null;
              _dataDetectMsg = res['message']?.toString();
            } else {
              _dataOperator = null;
              _dataOperatorName = null;
              _dataVerified = false;
              _dataPorted = null;
              _dataDetectMsg = res['message']?.toString() ?? 'Could not auto-detect network. Tap Change to select.';
            }
          });
          if (_dataOperator != null && _dataOperator != prevOp) {
            _loadPlans(_dataOperator!);
          }
        },
      );
    });
  }

  Future<void> _pickNetworkManually({
    required void Function(String code, String name, String icon) onPicked,
  }) async {
    final isDark = ThemeNotifier.instance.isDarkMode;
    final picked = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: isDark ? PayNoraColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Current Mobile Network', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'If this number was ported to another carrier, choose its current Nigerian network.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            ..._operators.map((op) => ListTile(
                  leading: Text(op['icon'] ?? '📶', style: const TextStyle(fontSize: 22)),
                  title: Text(op['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(ctx, op),
                )),
          ],
        ),
      ),
    );
    if (picked != null) {
      onPicked(picked['code']!, picked['name']!, picked['icon'] ?? '📶');
    }
  }

  Future<void> _loadPlans(String operatorCode) async {
    setState(() {
      _plans = [];
      _selectedPlan = null;
    });
    try {
      final plans = await _api.getDataPlans(operatorCode, 'NG');
      if (mounted) {
        setState(() {
          _plans = plans;
          if (plans.isNotEmpty) _selectedPlan = Map<String, dynamic>.from(plans.first as Map);
        });
      }
    } catch (e) {
      if (mounted) _snack(_errMsg(e));
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  bool _validNigerianPhone(String p) {
    final d = p.replaceAll(RegExp(r'\D'), '');
    return d.length == 11 || (d.startsWith('234') && d.length == 13);
  }

  String _errMsg(Object e) {
    try {
      final dyn = e as dynamic;
      final detail = dyn.response?.data?['detail'];
      if (detail != null) return '$detail';
    } catch (_) {}
    return 'Request failed. Please check your connection and try again.';
  }

  // ---------- Actions ----------
  Future<void> _buyAirtime() async {
    if (!_validNigerianPhone(_airPhone.text)) {
      return _snack('Enter a valid 11-digit Nigerian phone number (e.g. 0803 123 4567).');
    }
    if (_airOperator == null) {
      await _detectNetworkRemote(
        rawPhone: _airPhone.text,
        onLoading: (l) => setState(() => _airDetecting = l),
        onResult: (res) {
          if (res['detected'] == true) {
            _airOperator = res['operator_code']?.toString();
            _airOperatorName = res['operator_name']?.toString();
            _airOperatorIcon = res['icon']?.toString() ?? '📶';
            _airVerified = res['verified'] == true;
          }
        },
      );
    }
    if (_airOperator == null) {
      return _snack('Please verify or select the mobile network first.');
    }
    final amt = double.tryParse(_airAmount.text) ?? 0;
    if (amt < 50) return _snack('Minimum airtime amount is ₦50.');
    setState(() => _busy = true);
    try {
      final res = await _api.purchaseAirtime(
        phone: _airPhone.text.trim(),
        operatorCode: _airOperator!,
        amount: amt.toStringAsFixed(2),
        countryIso: 'NG',
      );
      final txId = '${res['transaction_id']}';
      final usedOp = '${res['operator'] ?? _airOperator}';
      final usedName = '${res['operator_name'] ?? _airOperatorName ?? usedOp}';
      _showReceipt(
        'Airtime Sent',
        [
          ['Verified Network', usedName],
          if (res['operator_corrected'] == true) ['Ported Check', 'Corrected automatically before purchase'],
          ['Phone', _airPhone.text],
          ['Amount', '$_symbol${res['amount']}'],
          if (res['wallet_balance_after'] != null) ['New Balance', '$_symbol${res['wallet_balance_after']}'],
          ['Reference', txId],
        ],
      );
    } catch (e) {
      _snack(_errMsg(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buyData() async {
    if (!_validNigerianPhone(_dataPhone.text)) {
      return _snack('Enter a valid 11-digit Nigerian phone number (e.g. 0802 123 4567).');
    }
    if (_dataOperator == null) {
      return _snack('Please verify or select the mobile network first.');
    }
    if (_selectedPlan == null) return _snack('Select a data plan.');
    setState(() => _busy = true);
    try {
      final res = await _api.purchaseData(
        phone: _dataPhone.text.trim(),
        operatorCode: _dataOperator!,
        planId: '${_selectedPlan!['id']}',
        amount: '${_selectedPlan!['amount']}',
        countryIso: 'NG',
      );
      final txId = '${res['transaction_id']}';
      final usedOp = '${res['operator'] ?? _dataOperator}';
      final usedName = '${res['operator_name'] ?? _dataOperatorName ?? usedOp}';
      _showReceipt(
        'Data Activated',
        [
          ['Verified Network', usedName],
          ['Plan', '${_selectedPlan!['name']}'],
          ['Phone', _dataPhone.text],
          ['Amount', '$_symbol${res['amount']}'],
          if (res['wallet_balance_after'] != null) ['New Balance', '$_symbol${res['wallet_balance_after']}'],
          ['Reference', txId],
        ],
      );
    } catch (e) {
      _snack(_errMsg(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- Live Electricity Meter Verification (NO hardcoded mock names) ----------
  Future<void> _validateMeter() async {
    final meter = _meterNo.text.replaceAll(RegExp(r'\D'), '');
    if (meter.length < 10 || meter.length > 13) {
      setState(() {
        _meterInfo = null;
        _disco = null;
        _discoName = null;
        _meterError = 'Nigerian meter numbers are 10–13 digits. Please check the number.';
      });
      return;
    }

    setState(() {
      _validating = true;
      _meterInfo = null;
      _meterError = null;
      _disco = null;
      _discoName = null;
    });
    try {
      final res = await _api.validateMeter(
        discoCode: _manualDisco,
        meterNumber: meter,
        meterType: _meterType,
        countryIso: 'NG',
      );
      if (!mounted) return;
      setState(() {
        _disco = (res['disco'] ?? res['biller_code'])?.toString();
        _discoName = (res['disco_name'] ?? res['biller_name'])?.toString();
        _meterInfo = res;
        _meterError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _meterInfo = null;
        _disco = null;
        _discoName = null;
        _meterError = _errMsg(e);
      });
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  void _onMeterChanged(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    _meterDebounce?.cancel();
    setState(() {
      _disco = null;
      _discoName = null;
      _meterInfo = null;
      _meterError = null;
    });
    if (digits.length >= 10) {
      _meterDebounce = Timer(const Duration(milliseconds: 500), _validateMeter);
    }
  }

  Future<void> _payElectricity() async {
    if (_meterInfo == null) {
      await _validateMeter();
      if (_meterInfo == null) return;
    }
    final amt = double.tryParse(_powerAmount.text) ?? 0;
    if (amt < 500) return _snack('Minimum electricity payment is ₦500.');
    setState(() => _busy = true);
    try {
      final res = await _api.purchaseElectricity(
        discoCode: _disco,
        meterNumber: _meterNo.text.trim(),
        meterType: _meterType,
        amount: amt.toStringAsFixed(2),
        customerName: _meterInfo!['customer_name']?.toString(),
        countryIso: 'NG',
      );
      final txId = '${res['transaction_id']}';
      final usedDisco = '${res['disco'] ?? _disco ?? 'POWER'}';
      final usedDiscoName = '${res['disco_name'] ?? _discoName ?? usedDisco}';
      _showReceipt(
        _meterType == 'PREPAID' ? 'Token Generated' : 'Bill Paid',
        [
          ['Verified Provider', usedDiscoName],
          ['Meter', _meterNo.text],
          ['Customer', '${res['customer_name']}'],
          ['Amount', '$_symbol${res['amount']}'],
          if (_meterType == 'PREPAID' && (res['units'] ?? '').toString().isNotEmpty) ['Units', '${res['units']}'],
          if (res['wallet_balance_after'] != null) ['New Balance', '$_symbol${res['wallet_balance_after']}'],
          ['Reference', txId],
        ],
        token: _meterType == 'PREPAID' ? '${res['token']}' : null,
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
    final lockedOutsideNigeria = _profileLoaded && _country != 'NG';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bills & Power (Nigeria 🇳🇬 · NGN)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
        backgroundColor: isDark ? PayNoraColors.darkSurface : PayNoraColors.brandPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: lockedOutsideNigeria
            ? null
            : TabBar(
                controller: _tabs,
                indicatorColor: PayNoraColors.brandSecondary,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                tabs: const [
                  Tab(icon: Icon(Icons.phone_in_talk), text: 'Airtime'),
                  Tab(icon: Icon(Icons.wifi), text: 'Data'),
                  Tab(icon: Icon(Icons.bolt), text: 'Electricity'),
                ],
              ),
      ),
      body: lockedOutsideNigeria
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? PayNoraColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 54, color: PayNoraColors.warning),
                      const SizedBox(height: 14),
                      const Text(
                        'Nigeria Only Service',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Airtime, Mobile Data, and Electricity bill payments are currently locked to Nigerian (NG / NGN) accounts only.\n\nYour account country is $_country.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : TabBarView(
              controller: _tabs,
              children: [
                _airtimeTab(isDark),
                _dataTab(isDark),
                _electricityTab(isDark),
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

  Widget _networkStatusBadge({
    required String? name,
    required String? icon,
    required bool verified,
    required bool? ported,
    required bool detecting,
    required String? message,
    required VoidCallback onChangeNetwork,
  }) {
    if (detecting) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Row(
          children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Checking live network & porting status...', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }
    if (name == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message ?? 'Enter an 11-digit Nigerian phone number to detect its current network.',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: onChangeNetwork,
              child: const Text('Select Network', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    final color = verified ? PayNoraColors.success : PayNoraColors.warning;
    final badgeTitle = verified
        ? (ported == true ? 'Live Verified (Ported): $name' : 'Live Verified Network: $name')
        : 'Prefix Detected: $name (Tap Change if ported)';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(verified ? Icons.verified : Icons.sim_card_alert_outlined, color: color, size: 18),
          const SizedBox(width: 8),
          Text(icon ?? '📶', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badgeTitle,
                  style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 12),
                ),
                if (message != null && message.isNotEmpty)
                  Text(message, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          TextButton(
            onPressed: onChangeNetwork,
            child: const Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
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
    final quickAmounts = ['200', '500', '1000', '2000', '5000'];

    return ListView(padding: const EdgeInsets.all(20), children: [
      _card(isDark, [
        _label('NIGERIAN PHONE NUMBER (LIVE NETWORK CHECK)'),
        TextField(
          controller: _airPhone,
          keyboardType: TextInputType.phone,
          onChanged: _onAirPhoneChanged,
          decoration: const InputDecoration(
            hintText: 'Enter 11-digit number (e.g. 0803 123 4567)',
            prefixIcon: Icon(Icons.phone_android),
          ),
        ),
        _networkStatusBadge(
          name: _airOperatorName,
          icon: _airOperatorIcon,
          verified: _airVerified,
          ported: _airPorted,
          detecting: _airDetecting,
          message: _airDetectMsg,
          onChangeNetwork: () => _pickNetworkManually(
            onPicked: (code, name, icon) => setState(() {
              _airOperator = code;
              _airOperatorName = name;
              _airOperatorIcon = icon;
              _airVerified = true;
              _airPorted = false;
              _airDetectMsg = 'Network confirmed manually by you.';
            }),
          ),
        ),
        const SizedBox(height: 18),
        _label('AMOUNT (NGN)'),
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
    ]);
  }

  Widget _dataTab(bool isDark) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _card(isDark, [
        _label('NIGERIAN PHONE NUMBER (LIVE NETWORK & PLANS)'),
        TextField(
          controller: _dataPhone,
          keyboardType: TextInputType.phone,
          onChanged: _onDataPhoneChanged,
          decoration: const InputDecoration(
            hintText: 'Enter 11-digit number (e.g. 0802 123 4567)',
            prefixIcon: Icon(Icons.phone_android),
          ),
        ),
        _networkStatusBadge(
          name: _dataOperatorName,
          icon: _dataOperatorIcon,
          verified: _dataVerified,
          ported: _dataPorted,
          detecting: _dataDetecting,
          message: _dataDetectMsg,
          onChangeNetwork: () => _pickNetworkManually(
            onPicked: (code, name, icon) {
              final changed = _dataOperator != code;
              setState(() {
                _dataOperator = code;
                _dataOperatorName = name;
                _dataOperatorIcon = icon;
                _dataVerified = true;
                _dataPorted = false;
                _dataDetectMsg = 'Network confirmed manually by you.';
              });
              if (changed) _loadPlans(code);
            },
          ),
        ),
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
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${p['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      if ((p['validity'] ?? '').toString().isNotEmpty)
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

  Widget _electricityTab(bool isDark) {
    final quickAmounts = ['1000', '2000', '5000', '10000', '20000'];

    return ListView(padding: const EdgeInsets.all(20), children: [
      _card(isDark, [
        _label('METER TYPE'),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'PREPAID', label: Text('Prepaid'), icon: Icon(Icons.bolt)),
            ButtonSegment(value: 'POSTPAID', label: Text('Postpaid'), icon: Icon(Icons.receipt_long)),
          ],
          selected: {_meterType},
          onSelectionChanged: (s) {
            setState(() {
              _meterType = s.first;
              _meterInfo = null;
              _disco = null;
              _discoName = null;
              _meterError = null;
            });
            if (_meterNo.text.replaceAll(RegExp(r'\D'), '').length >= 10) {
              _validateMeter();
            }
          },
        ),
        const SizedBox(height: 18),
        _label('NIGERIAN METER NUMBER (LIVE UTILITY VERIFICATION)'),
        TextField(
          controller: _meterNo,
          keyboardType: TextInputType.number,
          onChanged: _onMeterChanged,
          decoration: InputDecoration(
            hintText: 'Enter 10–13 digit meter number',
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
        if (_discos.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _manualDisco,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Electricity Company (Auto-detected, or choose)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Auto-Detect Live from Meter')),
              ..._discos.map((d) => DropdownMenuItem<String?>(
                    value: '${d['code']}',
                    child: Text('${d['name']}'),
                  )),
            ],
            onChanged: (val) {
              setState(() => _manualDisco = val);
              if (_meterNo.text.replaceAll(RegExp(r'\D'), '').length >= 10) {
                _validateMeter();
              }
            },
          ),
        ],
        if (_validating)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Verifying meter live across Nigerian electricity distribution companies...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        if (_meterError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_meterError!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
        if (_meterInfo != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PayNoraColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PayNoraColors.success.withOpacity(0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.verified_user, color: PayNoraColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Company: ${_discoName ?? _disco ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: PayNoraColors.success, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Meter Owner: ${_meterInfo!['customer_name']}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  if ((_meterInfo!['address'] ?? '').toString().isNotEmpty)
                    Text('${_meterInfo!['address']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
              ),
            ]),
          ),
        ],
      ]),
      _card(isDark, [
        _label('AMOUNT (NGN)'),
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
