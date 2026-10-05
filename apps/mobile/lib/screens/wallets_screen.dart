import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/design_tokens.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _wallets = [];
  bool _loading = true;

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
        _wallets = res;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showDepositDialog(String currency) {
    final controller = TextEditingController(text: '100000');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deposit to $currency Wallet', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount to Deposit'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PayNoraColors.primary),
            onPressed: () async {
              Navigator.pop(context);
              await _api.fundWallet(currency, controller.text);
              _loadWallets();
            },
            child: const Text('Confirm Deposit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayNoraColors.surface,
      appBar: AppBar(
        title: const Text('Digital Currency Wallets', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18)),
        backgroundColor: PayNoraColors.primary,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PayNoraColors.primary))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _wallets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final w = _wallets[index];
                final curr = w['currency'];
                final bal = w['available_balance'];

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$curr Wallet', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: PayNoraColors.primary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: PayNoraColors.secondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(w['status'] ?? 'ACTIVE', style: const TextStyle(color: PayNoraColors.secondary, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${curr == 'NGN' ? '₦' : curr == 'GBP' ? '£' : '\$'}$bal',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 28, color: PayNoraColors.primary),
                      ),
                      const SizedBox(height: 6),
                      const Text('Settled on Double-Entry Ledger', style: TextStyle(color: Colors.black38, fontSize: 11)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: PayNoraColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _showDepositDialog(curr),
                              child: const Text('+ Deposit', style: TextStyle(color: PayNoraColors.primary, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
