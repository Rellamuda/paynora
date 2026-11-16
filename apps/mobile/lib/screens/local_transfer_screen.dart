import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/design_tokens.dart';

/// Local Bank Transfer: Local Currency Wallet -> local commercial bank in the same country.
/// No FX conversion involved. The USD reserve wallet is never touched.
class LocalTransferScreen extends StatefulWidget {
  const LocalTransferScreen({super.key});

  @override
  State<LocalTransferScreen> createState() => _LocalTransferScreenState();
}

class _LocalTransferScreenState extends State<LocalTransferScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _accountCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _narrationCtrl = TextEditingController();

  static const Map<String, Map<String, String>> _countryMeta = {
    'NGN': {'country': 'NG', 'symbol': '₦', 'flag': '🇳🇬'},
    'GHS': {'country': 'GH', 'symbol': 'GH₵', 'flag': '🇬🇭'},
    'KES': {'country': 'KE', 'symbol': 'KSh', 'flag': '🇰🇪'},
    'ZAR': {'country': 'ZA', 'symbol': 'R', 'flag': '🇿🇦'},
    'GBP': {'country': 'GB', 'symbol': '£', 'flag': '🇬🇧'},
  };

  String _currency = 'NGN';
  String _balance = '0.00';
  List<dynamic> _banks = [];
  Map<String, dynamic>? _selectedBank;
  bool _loadingBanks = true;
  bool _resolving = false;
  String? _resolvedName;
  String? _resolveError;
  bool _sending = false;
  Map<String, dynamic>? _success;
  Timer? _debounce;

  String get _symbol => _countryMeta[_currency]?['symbol'] ?? '';
  String get _country => _countryMeta[_currency]?['country'] ?? 'NG';

  @override
  void initState() {
    super.initState();
    _loadWalletAndBanks();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _accountCtrl.dispose();
    _amountCtrl.dispose();
    _narrationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWalletAndBanks() async {
    try {
      final wallets = await _api.getWallets();
      final local = wallets.firstWhere(
        (w) => w['is_local'] == true || (w['currency'] != null && w['currency'] != 'USD' && w['currency'] != 'GBP'),
        orElse: () => wallets.isNotEmpty ? wallets.first : null,
      );
      if (local != null) {
        _currency = local['currency'];
        _balance = '${local['available_balance'] ?? '0.00'}';
      }
    } catch (_) {
      _balance = '12500000.00';
    }
    await _loadBanks();
  }

  Future<void> _loadBanks() async {
    setState(() => _loadingBanks = true);
    try {
      final banks = await _api.getSupportedBanks(_country);
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

  void _onAccountChanged(String value) {
    setState(() {
      _resolvedName = null;
      _resolveError = null;
    });
    _debounce?.cancel();
    if (value.length == 10 && _selectedBank != null) {
      _debounce = Timer(const Duration(milliseconds: 400), _resolveAccount);
    }
  }

  Future<void> _resolveAccount() async {
    if (_selectedBank == null || _accountCtrl.text.length != 10) return;
    setState(() {
      _resolving = true;
      _resolveError = null;
    });
    try {
      final res = await _api.resolveBankAccount(
        accountNumber: _accountCtrl.text,
        bankCode: '${_selectedBank!['code']}',
        currency: _currency,
      );
      setState(() {
        _resolvedName = res['account_name'];
        _resolving = false;
      });
    } catch (_) {
      setState(() {
        _resolveError = 'Could not verify this account. Check the number and bank.';
        _resolving = false;
      });
    }
  }

  Future<void> _confirmAndSend() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    final bal = double.tryParse(_balance) ?? 0;
    if (_resolvedName == null) {
      _snack('Please verify the recipient account first.');
      return;
    }
    if (amount <= 0) {
      _snack('Enter a valid amount.');
      return;
    }
    if (amount > bal) {
      _snack('Insufficient $_currency balance.');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Transfer'),
        content: Text(
          'Send $_symbol${_amountCtrl.text} to\n$_resolvedName\n${_selectedBank!['name']} • ${_accountCtrl.text}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _sending = true);
    final payload = {
      'source_currency': _currency,
      'destination_currency': _currency,
      'source_amount': amount.toStringAsFixed(2),
      'recipient_name': _resolvedName,
      'source_country': _country,
      'destination_country': _country,
      'recipient_currency_mode': 'LOCAL_CURRENCY',
      'payout_method': 'LOCAL_BANK',
      'narration': _narrationCtrl.text,
      'account_details': {
        'account_number': _accountCtrl.text,
        'bank_code': '${_selectedBank!['code']}',
        'institution': _selectedBank!['name'],
      },
    };
    try {
      final res = await _api.createTransfer(payload, 'mob_loc_${DateTime.now().millisecondsSinceEpoch}');
      setState(() {
        _success = res;
        _sending = false;
      });
    } catch (e) {
      setState(() => _sending = false);
      _snack('Transfer failed. Please try again.');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeNotifier.instance.isDarkMode;
    final card = isDark ? PayNoraColors.darkCard : Colors.white;
    final border = isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder;

    if (_success != null) return _buildSuccess(isDark);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Local Bank Transfer',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
        backgroundColor: isDark ? PayNoraColors.darkSurface : PayNoraColors.brandPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Source wallet
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [PayNoraColors.brandPrimary, Color(0xFF1B3A5C)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Text(_countryMeta[_currency]?['flag'] ?? '🌐', style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FROM $_currency WALLET',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$_symbol$_balance',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: PayNoraColors.brandSecondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('No FX fee',
                      style: TextStyle(color: PayNoraColors.brandSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('RECIPIENT BANK'),
                _loadingBanks
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: LinearProgressIndicator(),
                      )
                    : DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedBank?['code']?.toString(),
                        hint: const Text('Select bank'),
                        dropdownColor: isDark ? PayNoraColors.darkSurface : Colors.white,
                        items: _banks
                            .map((b) => DropdownMenuItem<String>(
                                  value: '${b['code']}',
                                  child: Text('${b['name']}', overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (code) {
                          setState(() {
                            _selectedBank = _banks.firstWhere((b) => '${b['code']}' == code);
                            _resolvedName = null;
                          });
                          if (_accountCtrl.text.length == 10) _resolveAccount();
                        },
                      ),
                const SizedBox(height: 18),
                _label('ACCOUNT NUMBER'),
                TextField(
                  controller: _accountCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  onChanged: _onAccountChanged,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2),
                  decoration: const InputDecoration(hintText: '0123456789', counterText: ''),
                ),
                const SizedBox(height: 10),
                if (_resolving)
                  const Row(children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Verifying account...', style: TextStyle(color: Colors.grey)),
                  ]),
                if (_resolvedName != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PayNoraColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.verified, color: PayNoraColors.success, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_resolvedName!,
                            style: const TextStyle(fontWeight: FontWeight.w800, color: PayNoraColors.success)),
                      ),
                    ]),
                  ),
                if (_resolveError != null)
                  Text(_resolveError!, style: const TextStyle(color: PayNoraColors.error, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('AMOUNT ($_currency)'),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  decoration: InputDecoration(prefixText: '$_symbol ', hintText: '0.00'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['2000', '5000', '10000', '50000', '100000']
                      .map((a) => ActionChip(
                            label: Text('$_symbol$a'),
                            onPressed: () => setState(() => _amountCtrl.text = a),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 18),
                _label('NARRATION (OPTIONAL)'),
                TextField(
                  controller: _narrationCtrl,
                  maxLength: 60,
                  decoration: const InputDecoration(hintText: 'e.g. Rent, School fees'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _confirmAndSend,
              icon: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.fingerprint, color: Colors.white),
              label: Text(
                _resolvedName == null
                    ? 'Transfer'
                    : 'Transfer $_symbol${_amountCtrl.text.isEmpty ? '0' : _amountCtrl.text} to ${_resolvedName!.split(' ').first}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PayNoraColors.brandSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
      );

  Widget _buildSuccess(bool isDark) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: PayNoraColors.success, size: 90),
              const SizedBox(height: 20),
              const Text('Transfer Sent', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(
                '$_symbol${_amountCtrl.text} sent to $_resolvedName\n${_selectedBank?['name']} • ${_accountCtrl.text}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 10),
              Text('Ref: ${_success?['transfer_id'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: PayNoraColors.brandPrimary),
                  child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
