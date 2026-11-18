import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/design_tokens.dart';

/// Bills & Utilities: Airtime (call units), Mobile Data, Electricity tokens.
/// All payments are charged to the user's Local Currency Wallet.
class BillsScreen extends StatefulWidget {
  final int initialTab;
  const BillsScreen({super.key, this.initialTab = 0});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final ApiService _api = ApiService();
  final String _country = 'NG';
  final String _symbol = '₦';

  // Shared
  List<dynamic> _operators = [];
  bool _busy = false;

  // Airtime
  String? _airOperator;
  final _airPhone = TextEditingController();
  final _airAmount = TextEditingController();

  // Data
  String? _dataOperator;
  final _dataPhone = TextEditingController();
  List<dynamic> _plans = [];
  Map<String, dynamic>? _selectedPlan;

  // Electricity
  List<dynamic> _discos = [];
  String? _disco;
  String _meterType = 'PREPAID';
  final _meterNo = TextEditingController();
  final _powerAmount = TextEditingController();
  Map<String, dynamic>? _meterInfo;
  bool _validating = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _loadCatalog();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _airPhone.dispose();
    _airAmount.dispose();
    _dataPhone.dispose();
    _meterNo.dispose();
    _powerAmount.dispose();
    super.dispose();
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
          {'name': 'MTN Nigeria', 'code': 'MTN', 'icon': '🟡'},
          {'name': 'Airtel Nigeria', 'code': 'AIRTEL', 'icon': '🔴'},
          {'name': 'Globacom (Glo)', 'code': 'GLO', 'icon': '🟢'},
          {'name': '9mobile', 'code': '9MOBILE', 'icon': '🟢'},
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

  Future<void> _loadPlans(String operatorCode) async {
    setState(() {
      _plans = [];
      _selectedPlan = null;
    });
    try {
      final plans = await _api.getDataPlans(operatorCode);
      setState(() => _plans = plans);
    } catch (_) {
      _snack('Could not load data plans.');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  bool _validPhone(String p) => p.replaceAll(RegExp(r'\D'), '').length >= 10;

  String _errMsg(Object e) {
    try {
      final dyn = e as dynamic;
      final detail = dyn.response?.data?['detail'];
      if (detail != null) return '$detail';
    } catch (_) {}
    return 'Payment failed. Please try again.';
  }

  // ---------- Actions ----------
  Future<void> _buyAirtime() async {
    if (_airOperator == null) return _snack('Select a network.');
    if (!_validPhone(_airPhone.text)) return _snack('Enter a valid phone number.');
    final amt = double.tryParse(_airAmount.text) ?? 0;
    if (amt < 50) return _snack('Minimum airtime is ${_symbol}50.');
    setState(() => _busy = true);
    try {
      final res = await _api.purchaseAirtime(
          phone: _airPhone.text, operatorCode: _airOperator!, amount: amt.toStringAsFixed(2), countryIso: _country);
      _showReceipt('Airtime Sent', [
        ['Network', _airOperator!],
        ['Phone', _airPhone.text],
        ['Amount', '$_symbol${res['amount']}'],
        if (res['wallet_balance_after'] != null) ['New Balance', '$_symbol${res['wallet_balance_after']}'],
        ['Reference', '${res['transaction_id']}'],
      ]);
    } catch (e) {
      _snack(_errMsg(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buyData() async {
    if (_dataOperator == null) return _snack('Select a network.');
    if (_selectedPlan == null) return _snack('Select a data plan.');
    if (!_validPhone(_dataPhone.text)) return _snack('Enter a valid phone number.');
    setState(() => _busy = true);
    try {
      final res = await _api.purchaseData(
        phone: _dataPhone.text,
        operatorCode: _dataOperator!,
        planId: '${_selectedPlan!['id']}',
        amount: '${_selectedPlan!['amount']}',
        countryIso: _country,
      );
      _showReceipt('Data Activated', [
        ['Network', _dataOperator!],
        ['Plan', '${_selectedPlan!['name']}'],
        ['Phone', _dataPhone.text],
        ['Amount', '$_symbol${res['amount']}'],
        if (res['wallet_balance_after'] != null) ['New Balance', '$_symbol${res['wallet_balance_after']}'],
        ['Reference', '${res['transaction_id']}'],
      ]);
    } catch (e) {
      _snack(_errMsg(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _validateMeter() async {
    if (_disco == null) return _snack('Select your distribution company.');
    if (_meterNo.text.length < 8) return _snack('Enter a valid meter number.');
    setState(() {
      _validating = true;
      _meterInfo = null;
    });
    try {
      final res = await _api.validateMeter(
          discoCode: _disco!, meterNumber: _meterNo.text, meterType: _meterType, countryIso: _country);
      setState(() => _meterInfo = res);
    } catch (e) {
      _snack(_errMsg(e));
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  Future<void> _payElectricity() async {
    if (_meterInfo == null) return _snack('Verify the meter first.');
    final amt = double.tryParse(_powerAmount.text) ?? 0;
    if (amt < 500) return _snack('Minimum payment is ${_symbol}500.');
    setState(() => _busy = true);
    try {
      final res = await _api.purchaseElectricity(
        discoCode: _disco!,
        meterNumber: _meterNo.text,
        meterType: _meterType,
        amount: amt.toStringAsFixed(2),
        customerName: _meterInfo!['customer_name'],
        countryIso: _country,
      );
      _showReceipt(
        _meterType == 'PREPAID' ? 'Token Generated' : 'Bill Paid',
        [
          ['Disco', _disco!],
          ['Meter', _meterNo.text],
          ['Customer', '${res['customer_name']}'],
          ['Amount', '$_symbol${res['amount']}'],
          if (_meterType == 'PREPAID') ['Units', '${res['units']}'],
          if (res['wallet_balance_after'] != null) ['New Balance', '$_symbol${res['wallet_balance_after']}'],
          ['Reference', '${res['transaction_id']}'],
        ],
        token: _meterType == 'PREPAID' ? '${res['token']}' : null,
      );
    } catch (e) {
      _snack(_errMsg(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showReceipt(String title, List<List<String>> rows, {String? token}) {
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bills & Power', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
        backgroundColor: isDark ? PayNoraColors.darkSurface : PayNoraColors.brandPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: PayNoraColors.brandSecondary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabs: const [
            Tab(icon: Icon(Icons.phone_in_talk), text: 'Airtime'),
            Tab(icon: Icon(Icons.wifi), text: 'Data'),
            Tab(icon: Icon(Icons.bolt), text: 'Electricity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_airtimeTab(isDark), _dataTab(isDark), _electricityTab(isDark)],
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

  Widget _operatorPicker(String? selected, ValueChanged<String> onPick) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _operators.map((op) {
        final code = '${op['code']}';
        final active = code == selected;
        return ChoiceChip(
          label: Text('${op['icon'] ?? ''} ${op['name']}'),
          selected: active,
          selectedColor: PayNoraColors.brandSecondary.withOpacity(0.25),
          onSelected: (_) => onPick(code),
        );
      }).toList(),
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
    return ListView(padding: const EdgeInsets.all(20), children: [
      _card(isDark, [
        _label('SELECT NETWORK'),
        _operatorPicker(_airOperator, (c) => setState(() => _airOperator = c)),
      ]),
      _card(isDark, [
        _label('PHONE NUMBER'),
        TextField(
          controller: _airPhone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '0803 000 0000', prefixIcon: Icon(Icons.phone_android)),
        ),
        const SizedBox(height: 18),
        _label('AMOUNT'),
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
          children: ['100', '200', '500', '1000', '2000', '5000']
              .map((a) => ActionChip(label: Text('$_symbol$a'), onPressed: () => setState(() => _airAmount.text = a)))
              .toList(),
        ),
      ]),
      _payButton('Buy ${_symbol}${_airAmount.text.isEmpty ? '0' : _airAmount.text} Airtime', _buyAirtime),
    ]);
  }

  Widget _dataTab(bool isDark) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _card(isDark, [
        _label('SELECT NETWORK'),
        _operatorPicker(_dataOperator, (c) {
          setState(() => _dataOperator = c);
          _loadPlans(c);
        }),
      ]),
      if (_dataOperator != null)
        _card(isDark, [
          _label('CHOOSE BUNDLE'),
          if (_plans.isEmpty) const LinearProgressIndicator(),
          ..._plans.map((p) {
            final active = _selectedPlan?['id'] == p['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedPlan = Map<String, dynamic>.from(p)),
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
      _card(isDark, [
        _label('PHONE NUMBER'),
        TextField(
          controller: _dataPhone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '0803 000 0000', prefixIcon: Icon(Icons.phone_android)),
        ),
      ]),
      _payButton(
        _selectedPlan == null ? 'Buy Data' : 'Buy ${_selectedPlan!['allowance']} for $_symbol${_selectedPlan!['amount']}',
        _buyData,
      ),
    ]);
  }

  Widget _electricityTab(bool isDark) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _card(isDark, [
        _label('DISTRIBUTION COMPANY'),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _disco,
          hint: const Text('Select Disco'),
          dropdownColor: isDark ? PayNoraColors.darkSurface : Colors.white,
          items: _discos
              .map((d) => DropdownMenuItem<String>(
                    value: '${d['code']}',
                    child: Text('${d['name']}', overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) => setState(() {
            _disco = v;
            _meterInfo = null;
          }),
        ),
        const SizedBox(height: 18),
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
        _label('METER NUMBER'),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _meterNo,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() => _meterInfo = null),
              decoration: const InputDecoration(hintText: '45012345678'),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: _validating ? null : _validateMeter,
            child: _validating
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Verify'),
          ),
        ]),
        if (_meterInfo != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PayNoraColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.verified, color: PayNoraColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_meterInfo!['customer_name']}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: PayNoraColors.success)),
                  Text('${_meterInfo!['address'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
              ),
            ]),
          ),
        ],
      ]),
      _card(isDark, [
        _label('AMOUNT'),
        TextField(
          controller: _powerAmount,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          decoration: InputDecoration(prefixText: '$_symbol ', hintText: 'Min 500'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['1000', '2000', '5000', '10000', '20000']
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
