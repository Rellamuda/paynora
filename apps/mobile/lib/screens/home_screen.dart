import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/design_tokens.dart';
import 'send_screen.dart';
import 'wallets_screen.dart';
import 'exchange_screen.dart';
import 'recipients_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _wallets = [];
  List<dynamic> _transfers = [];
  bool _loading = true;
  bool _hideBalance = false;

  final List<Map<String, String>> _corridors = [
    {'pair': 'GBP / NGN', 'rate': '₦1,923.08', 'spread': '0.5%', 'flag': '🇬🇧 ➔ 🇳🇬'},
    {'pair': 'USD / NGN', 'rate': '₦1,538.46', 'spread': '0.5%', 'flag': '🇺🇸 ➔ 🇳🇬'},
    {'pair': 'EUR / NGN', 'rate': '₦1,666.67', 'spread': '0.5%', 'flag': '🇪🇺 ➔ 🇳🇬'},
    {'pair': 'CAD / NGN', 'rate': '₦1,120.50', 'spread': '0.5%', 'flag': '🇨🇦 ➔ 🇳🇬'},
    {'pair': 'AED / NGN', 'rate': '₦418.90', 'spread': '0.5%', 'flag': '🇦🇪 ➔ 🇳🇬'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final wallets = await _api.getWallets();
      final transfers = await _api.getTransfers();
      setState(() {
        _wallets = wallets.isNotEmpty
            ? wallets
            : [
                {'currency': 'NGN', 'available_balance': '12500000.00', 'symbol': '₦'},
                {'currency': 'GBP', 'available_balance': '4250.00', 'symbol': '£'},
                {'currency': 'USD', 'available_balance': '5800.00', 'symbol': '\$'},
                {'currency': 'EUR', 'available_balance': '3100.00', 'symbol': '€'},
              ];
        _transfers = transfers;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _wallets = [
          {'currency': 'NGN', 'available_balance': '12500000.00', 'symbol': '₦'},
          {'currency': 'GBP', 'available_balance': '4250.00', 'symbol': '£'},
          {'currency': 'USD', 'available_balance': '5800.00', 'symbol': '\$'},
          {'currency': 'EUR', 'available_balance': '3100.00', 'symbol': '€'},
        ];
        _loading = false;
      });
    }
  }

  void _showTransactionDetails(Map<String, dynamic> tx) {
    final isDark = ThemeNotifier.instance.isDarkMode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? PayNoraColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaction Receipt',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: PayNoraColors.successBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '● DELIVERED',
                      style: TextStyle(color: PayNoraColors.success, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? PayNoraColors.darkCard : PayNoraColors.lightCardSubtle,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _receiptRow('Reference', tx['transfer_id'] ?? 'trf_08d31befd3c1'),
                    const Divider(height: 18),
                    _receiptRow('Recipient', tx['recipient_name'] ?? 'Mike Okafor'),
                    const Divider(height: 18),
                    _receiptRow('Amount Sent', '${tx['source_amount'] ?? '100,000'} ${tx['source_currency'] ?? 'NGN'}'),
                    const Divider(height: 18),
                    _receiptRow('Fee', '${tx['estimated_fee'] ?? '500.00'} ${tx['source_currency'] ?? 'NGN'}'),
                    const Divider(height: 18),
                    _receiptRow('Clearing Rail', 'Instant Faster Payments / NIBSS'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PayNoraColors.brandSecondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeNotifier.instance.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? PayNoraColors.darkSurface : PayNoraColors.brandPrimary,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/logo.png', width: 30, height: 30, errorBuilder: (_, __, ___) => const Icon(Icons.bolt, color: PayNoraColors.brandSecondary)),
            ),
            const SizedBox(width: 10),
            const Text(
              'PayNora',
              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 21, letterSpacing: -0.5),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: PayNoraColors.brandSecondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'GLOBAL',
                style: TextStyle(color: PayNoraColors.brandSecondary, fontSize: 9, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: [
          // Live Theme Toggle Button
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white),
            tooltip: 'Toggle Dark / Light Theme',
            onPressed: () {
              setState(() {
                ThemeNotifier.instance.toggleTheme();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PayNoraColors.brandSecondary))
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                children: [
                  // Total Net Worth Banner
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF131E3A), const Color(0xFF0F172A)]
                            : [PayNoraColors.brandPrimary, const Color(0xFF1E3A5F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: PayNoraColors.brandPrimary.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL MULTI-CURRENCY BALANCE',
                              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                _hideBalance ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _hideBalance = !_hideBalance),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _hideBalance ? '••••••••••' : '₦ 24,850,240.00',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: PayNoraColors.brandSecondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '≈ \$16,150.00 USD • £12,920.00 GBP',
                                style: TextStyle(color: PayNoraColors.brandSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Quick Action Buttons Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _actionButton(
                        icon: Icons.send_rounded,
                        label: 'Send',
                        color: PayNoraColors.brandSecondary,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SendScreen())),
                      ),
                      _actionButton(
                        icon: Icons.add_circle_outline,
                        label: 'Deposit',
                        color: isDark ? const Color(0xFF38BDF8) : PayNoraColors.brandPrimary,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletsScreen())),
                      ),
                      _actionButton(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Convert',
                        color: PayNoraColors.accentPurple,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExchangeScreen())),
                      ),
                      _actionButton(
                        icon: Icons.people_alt_outlined,
                        label: 'Recipients',
                        color: const Color(0xFFF59E0B),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipientsScreen())),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Multi-Currency Wallets Carousel Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Wallets',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? PayNoraColors.darkTextPrimary : PayNoraColors.lightTextPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletsScreen())),
                        child: const Text('View All', style: TextStyle(color: PayNoraColors.brandSecondary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Horizontal Wallets List
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _wallets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final w = _wallets[index];
                        final curr = w['currency'] ?? 'USD';
                        final bal = w['available_balance'] ?? '0.00';
                        return Container(
                          width: 170,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? PayNoraColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    curr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : PayNoraColors.brandPrimary,
                                    ),
                                  ),
                                  Text(_getCurrencyFlag(curr), style: const TextStyle(fontSize: 18)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Available Balance', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _hideBalance ? '••••' : '$bal $curr',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : PayNoraColors.lightTextPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Live Corridors Rate Ticker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Corridor FX Rates',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? PayNoraColors.darkTextPrimary : PayNoraColors.lightTextPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExchangeScreen())),
                        child: const Text('Convert', style: TextStyle(color: PayNoraColors.brandSecondary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _corridors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final c = _corridors[i];
                        return Container(
                          width: 150,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? PayNoraColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(c['flag']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(c['pair']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(c['rate']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: PayNoraColors.brandSecondary)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transfers & Clearing',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? PayNoraColors.darkTextPrimary : PayNoraColors.lightTextPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen())),
                        child: const Text('All Activity', style: TextStyle(color: PayNoraColors.brandSecondary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Recent Transactions List
                  ..._transfers.map((tx) {
                    final curr = tx['source_currency'] ?? 'NGN';
                    final amt = tx['source_amount'] ?? '0.00';
                    final recipient = tx['recipient_name'] ?? 'Recipient';
                    final id = tx['transfer_id'] ?? 'trf_001';

                    return Card(
                      color: isDark ? PayNoraColors.darkCard : Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => _showTransactionDetails(tx),
                        leading: CircleAvatar(
                          backgroundColor: isDark ? PayNoraColors.darkCardSubtle : PayNoraColors.lightCardSubtle,
                          child: const Icon(Icons.arrow_upward_rounded, color: PayNoraColors.brandSecondary, size: 20),
                        ),
                        title: Text(
                          recipient,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? Colors.white : PayNoraColors.lightTextPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '$id • Dispatched',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '-$amt $curr',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: isDark ? Colors.white : PayNoraColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: PayNoraColors.successBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DELIVERED',
                                style: TextStyle(color: PayNoraColors.success, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = ThemeNotifier.instance.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? PayNoraColors.darkTextPrimary : PayNoraColors.lightTextPrimary,
            ),
          ),
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
      default: return '🌐';
    }
  }
}
