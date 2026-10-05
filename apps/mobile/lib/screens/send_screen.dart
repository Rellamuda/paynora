import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/design_tokens.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _nameController = TextEditingController(text: 'John Doe');
  final TextEditingController _amountController = TextEditingController(text: '250000');

  String _sourceCurrency = 'NGN';
  String _destCurrency = 'GBP';
  Map<String, dynamic>? _quote;
  bool _calculating = false;
  bool _sending = false;
  Map<String, dynamic>? _successTx;

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
      setState(() => _calculating = false);
    }
  }

  Future<void> _executeSend() async {
    setState(() => _sending = true);
    try {
      final idemp = 'mob_${DateTime.now().millisecondsSinceEpoch}';
      final res = await _api.createTransfer({
        'source_currency': _sourceCurrency,
        'source_amount': _amountController.text,
        'recipient_name': _nameController.text,
        'source_country': 'NG',
        'destination_country': _destCurrency == 'GBP' ? 'GB' : 'US',
        'recipient_currency_mode': 'CHOICE',
      }, idemp);

      setState(() {
        _successTx = res;
        _sending = false;
      });
    } catch (e) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transfer failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayNoraColors.surface,
      appBar: AppBar(
        title: const Text('Send Money Internationally', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18)),
        backgroundColor: PayNoraColors.primary,
        elevation: 0,
      ),
      body: _successTx != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text('Transfer Dispatched!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: PayNoraColors.primary)),
                    const SizedBox(height: 10),
                    Text(
                      'Ref: ${_successTx!['transfer_id']}\nAmount: ${_successTx!['source_amount']} ${_successTx!['source_currency']} to ${_successTx!['recipient_name']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PayNoraColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => setState(() => _successTx = null),
                      child: const Text('Send Another', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Recipient Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recipient Legal Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. John Doe',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Amount & Currencies
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transfer Amount & Currency', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _fetchQuote(),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: _sourceCurrency,
                              items: const [
                                DropdownMenuItem(value: 'NGN', child: Text('NGN')),
                                DropdownMenuItem(value: 'USD', child: Text('USD')),
                                DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _sourceCurrency = val);
                                  _fetchQuote();
                                }
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Recipient Receives Currency', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _destCurrency,
                        items: const [
                          DropdownMenuItem(value: 'GBP', child: Text('GBP — British Pound (£) 🇬🇧')),
                          DropdownMenuItem(value: 'USD', child: Text('USD — US Dollar (\$) 🇺🇸')),
                          DropdownMenuItem(value: 'EUR', child: Text('EUR — Euro (€) 🇪🇺')),
                          DropdownMenuItem(value: 'NGN', child: Text('NGN — Nigerian Naira (₦) 🇳🇬')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _destCurrency = val);
                            _fetchQuote();
                          }
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // FX Quote Preview
                if (_quote != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Guaranteed Exchange Rate', style: TextStyle(color: Colors.black54, fontSize: 13)),
                            Text('1 $_sourceCurrency = ${_quote!['exchange_rate']} $_destCurrency', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Network Fee', style: TextStyle(color: Colors.black54, fontSize: 13)),
                            Text('${_quote!['fee']} $_sourceCurrency', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recipient Receives', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: PayNoraColors.primary)),
                            Text('${_quote!['destination_amount']} $_destCurrency', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: PayNoraColors.secondary)),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PayNoraColors.secondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _sending ? null : _executeSend,
                    child: _sending
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirm & Authorize Transfer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
    );
  }
}
