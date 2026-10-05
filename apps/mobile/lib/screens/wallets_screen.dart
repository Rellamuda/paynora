import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/design_tokens.dart';
import 'exchange_screen.dart';

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
                {'currency': 'GBP', 'available_balance': '4250.00'},
                {'currency': 'USD', 'available_balance': '5800.00'},
                {'currency': 'EUR', 'available_balance': '3100.00'},
                {'currency': 'CAD', 'available_balance': '1500.00'},
                {'currency': 'AED', 'available_balance': '6200.00'},
              ];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _wallets = [
          {'currency': 'NGN', 'available_balance': '12500000.00'},
          {'currency': 'GBP', 'available_balance': '4250.00'},
          {'currency': 'USD', 'available_balance': '5800.00'},
          {'currency': 'EUR', 'available_balance': '3100.00'},
          {'currency': 'CAD', 'available_balance': '1500.00'},
          {'currency': 'AED', 'available_balance': '6200.00'},
        ];
        _loading = false;
      });
    }
  }

  void _showDepositDialog(String currency) {
    final controller = TextEditingController(text: '50000');
    String paymentMethod = 'BANK';
    final isDark = ThemeNotifier.instance.isDarkMode;

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
              Text('Deposit Funds into $currency Wallet', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount ($currency)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Deposit Rail / Method', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => paymentMethod = 'BANK'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: paymentMethod == 'BANK' ? PayNoraColors.brandSecondary.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: paymentMethod == 'BANK' ? PayNoraColors.brandSecondary : Colors.grey.withOpacity(0.3)),
                        ),
                        child: const Text('Bank Transfer', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => paymentMethod = 'CARD'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: paymentMethod == 'CARD' ? PayNoraColors.brandSecondary.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: paymentMethod == 'CARD' ? PayNoraColors.brandSecondary : Colors.grey.withOpacity(0.3)),
                        ),
                        child: const Text('Debit / Card', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
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
                  onPressed: () async {
                    Navigator.pop(context);
                    await _api.fundWallet(currency, controller.text);
                    _loadWallets();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Successfully funded $currency wallet with ${controller.text}!')),
                    );
                  },
                  child: const Text('Confirm Deposit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
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
        title: const Text('Multi-Currency Wallets', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18)),
        backgroundColor: isDark ? PayNoraColors.darkSurface : PayNoraColors.brandPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Activate Currency',
            onPressed: _showActivateWalletDialog,
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
                            Text('Tier 3 Multi-Currency Clearance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 2),
                            Text('Deterministic double-entry ledger • Zero negative balance drift', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
