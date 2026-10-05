import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/design_tokens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _wallets = [];
  List<dynamic> _transfers = [];
  bool _loading = true;

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
        _wallets = wallets;
        _transfers = transfers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayNoraColors.surface,
      appBar: AppBar(
        backgroundColor: PayNoraColors.primary,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'PayNora',
              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 22),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: PayNoraColors.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'CORE',
                style: TextStyle(color: PayNoraColors.secondary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PayNoraColors.primary))
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Total Net Worth Banner
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: PayNoraColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: PayNoraColors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL MULTI-CURRENCY BALANCE',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '₦2,450,000.00',
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: PayNoraColors.secondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '● KYC APPROVED',
                                style: TextStyle(color: PayNoraColors.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              '+4 Currencies Active',
                              style: TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Wallets Row Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Active Digital Wallets',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PayNoraColors.primary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Horizontal Wallets Carousel
                  SizedBox(
                    height: 130,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _wallets.isNotEmpty ? _wallets.length : 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final w = _wallets.isNotEmpty ? _wallets[index] : null;
                        final curr = w != null ? w['currency'] : (index == 0 ? 'NGN' : index == 1 ? 'GBP' : 'USD');
                        final bal = w != null ? w['available_balance'] : (index == 0 ? '500,000.00' : index == 1 ? '1,250.00' : '1,500.00');

                        return Container(
                          width: 180,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
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
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: PayNoraColors.primary),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: PayNoraColors.secondary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('ACTIVE', style: TextStyle(color: PayNoraColors.secondary, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              Text(
                                '${curr == 'NGN' ? '₦' : curr == 'GBP' ? '£' : '\$'}$bal',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: PayNoraColors.primary),
                              ),
                              const Text('Settled on Ledger', style: TextStyle(color: Colors.black38, fontSize: 10)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Recent Activity Header
                  const Text(
                    'Recent Money Movement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PayNoraColors.primary),
                  ),

                  const SizedBox(height: 14),

                  // Transactions List
                  if (_transfers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Center(
                        child: Text('No transfers yet. Dispatch your first cross-border transfer!', style: TextStyle(color: Colors.black45)),
                      ),
                    )
                  else
                    ..._transfers.take(5).map((tx) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: PayNoraColors.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_upward, color: PayNoraColors.primary, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'To: ${tx['recipient_name'] ?? 'Recipient'}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: PayNoraColors.primary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tx['source_country']} ➔ ${tx['destination_country']} • ${tx['transfer_id']}',
                                      style: const TextStyle(color: Colors.black45, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${tx['source_amount']} ${tx['source_currency']}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: PayNoraColors.primary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tx['state'] ?? 'PROCESSING',
                                    style: TextStyle(
                                      color: tx['state'] == 'COMPLETED' ? PayNoraColors.secondary : Colors.deepPurple,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
