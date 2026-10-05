import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/design_tokens.dart';
import 'send_screen.dart';

class RecipientsScreen extends StatefulWidget {
  const RecipientsScreen({super.key});

  @override
  State<RecipientsScreen> createState() => _RecipientsScreenState();
}

class _RecipientsScreenState extends State<RecipientsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _beneficiaries = [];
  bool _loading = true;
  String _filter = 'ALL'; // 'ALL', 'BANK', 'MOMO'

  final List<Map<String, dynamic>> _mockBeneficiaries = [
    {
      'id': 'ben_01',
      'name': 'Adeola Williams',
      'country_iso': 'NG',
      'currency': 'NGN',
      'type': 'BANK',
      'institution': 'Access Bank Plc',
      'account_number': '0129481920',
      'flag': '🇳🇬'
    },
    {
      'id': 'ben_02',
      'name': 'Oliver Smith',
      'country_iso': 'GB',
      'currency': 'GBP',
      'type': 'BANK',
      'institution': 'Barclays Bank UK',
      'account_number': 'GB29BARC2004153829104',
      'flag': '🇬🇧'
    },
    {
      'id': 'ben_03',
      'name': 'Kofi Mensah',
      'country_iso': 'GH',
      'currency': 'GHS',
      'type': 'MOMO',
      'institution': 'MTN Mobile Money',
      'account_number': '+233 24 123 4567',
      'flag': '🇬🇭'
    },
    {
      'id': 'ben_04',
      'name': 'Sophia Chen',
      'country_iso': 'CA',
      'currency': 'CAD',
      'type': 'BANK',
      'institution': 'Royal Bank of Canada (RBC)',
      'account_number': '003-10294-819',
      'flag': '🇨🇦'
    },
    {
      'id': 'ben_05',
      'name': 'Ahmed Al-Falasi',
      'country_iso': 'AE',
      'currency': 'AED',
      'type': 'BANK',
      'institution': 'Emirates NBD',
      'account_number': 'AE070260001029481920',
      'flag': '🇦🇪'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadBeneficiaries();
  }

  Future<void> _loadBeneficiaries() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getBeneficiaries();
      setState(() {
        _beneficiaries = res.isNotEmpty ? res : _mockBeneficiaries;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _beneficiaries = _mockBeneficiaries;
        _loading = false;
      });
    }
  }

  void _showAddBeneficiaryDialog() {
    final nameCtrl = TextEditingController();
    final accCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    String country = 'NG';
    String curr = 'NGN';
    String type = 'BANK';
    final isDark = ThemeNotifier.instance.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? PayNoraColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 16),
              const Text('Add Saved Beneficiary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Recipient Legal Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: country,
                      decoration: InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      dropdownColor: isDark ? PayNoraColors.darkSurface : Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'NG', child: Text('🇳🇬 Nigeria')),
                        DropdownMenuItem(value: 'GB', child: Text('🇬🇧 UK')),
                        DropdownMenuItem(value: 'US', child: Text('🇺🇸 USA')),
                        DropdownMenuItem(value: 'CA', child: Text('🇨🇦 Canada')),
                        DropdownMenuItem(value: 'AE', child: Text('🇦🇪 UAE')),
                        DropdownMenuItem(value: 'GH', child: Text('🇬🇭 Ghana')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            country = val;
                            curr = val == 'GB' ? 'GBP' : val == 'US' ? 'USD' : val == 'CA' ? 'CAD' : val == 'AE' ? 'AED' : val == 'GH' ? 'GHS' : 'NGN';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: type,
                      decoration: InputDecoration(
                        labelText: 'Payout Rail',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      dropdownColor: isDark ? PayNoraColors.darkSurface : Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'BANK', child: Text('Bank Account')),
                        DropdownMenuItem(value: 'MOMO', child: Text('Mobile Money')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => type = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accCtrl,
                decoration: InputDecoration(
                  labelText: type == 'BANK' ? 'Account Number / IBAN' : 'Mobile Phone Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bankCtrl,
                decoration: InputDecoration(
                  labelText: type == 'BANK' ? 'Bank / Financial Institution' : 'Telco Provider (MTN / M-Pesa / Airtel)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
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
                    if (nameCtrl.text.isEmpty) return;
                    Navigator.pop(context);
                    final newBen = {
                      'id': 'ben_${DateTime.now().millisecondsSinceEpoch}',
                      'name': nameCtrl.text,
                      'country_iso': country,
                      'currency': curr,
                      'type': type,
                      'institution': bankCtrl.text,
                      'account_number': accCtrl.text,
                      'flag': country == 'GB' ? '🇬🇧' : country == 'US' ? '🇺🇸' : country == 'CA' ? '🇨🇦' : country == 'AE' ? '🇦🇪' : country == 'GH' ? '🇬🇭' : '🇳🇬',
                    };
                    setState(() {
                      _beneficiaries.insert(0, newBen);
                    });
                    try {
                      await _api.createBeneficiary(nameCtrl.text, country, curr, {
                        'account_number': accCtrl.text,
                        'institution': bankCtrl.text,
                        'type': type,
                      });
                    } catch (_) {}
                  },
                  child: const Text('Save Beneficiary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeNotifier.instance.isDarkMode;

    final filteredList = _beneficiaries.where((b) {
      if (_filter == 'BANK') return b['type'] == 'BANK';
      if (_filter == 'MOMO') return b['type'] == 'MOMO';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Saved Recipients', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18)),
        backgroundColor: isDark ? PayNoraColors.darkSurface : PayNoraColors.brandPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            tooltip: 'Add Recipient',
            onPressed: _showAddBeneficiaryDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Filter Tabs
          Row(
            children: [
              _filterChip('ALL', 'All Beneficiaries (${_beneficiaries.length})', isDark),
              const SizedBox(width: 8),
              _filterChip('BANK', 'Banks', isDark),
              const SizedBox(width: 8),
              _filterChip('MOMO', 'Mobile Money', isDark),
            ],
          ),

          const SizedBox(height: 18),

          if (_loading)
            const Center(child: CircularProgressIndicator(color: PayNoraColors.brandSecondary))
          else if (filteredList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('No beneficiaries found in this category.', style: TextStyle(color: isDark ? Colors.grey : Colors.black54)),
              ),
            )
          else
            ...filteredList.map((ben) {
              final name = ben['name'] ?? 'Recipient';
              final flag = ben['flag'] ?? (ben['country_iso'] == 'GB' ? '🇬🇧' : '🇳🇬');
              final institution = ben['institution'] ?? (ben['account_details']?['institution'] ?? 'Financial Institution');
              final acc = ben['account_number'] ?? (ben['account_details']?['account_number'] ?? '0123456789');
              final curr = ben['currency'] ?? 'NGN';
              final type = ben['type'] ?? 'BANK';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? PayNoraColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isDark ? PayNoraColors.darkCardSubtle : PayNoraColors.lightCardSubtle,
                      child: Text(flag, style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : PayNoraColors.lightTextPrimary)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: type == 'MOMO' ? const Color(0xFFFEF3C7) : PayNoraColors.successBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  type == 'MOMO' ? 'MOMO' : 'BANK',
                                  style: TextStyle(
                                    color: type == 'MOMO' ? const Color(0xFFD97706) : PayNoraColors.success,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text('$institution • $acc', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('Receives in $curr', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PayNoraColors.brandSecondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SendScreen()));
                      },
                      child: const Text('Send', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _filterChip(String key, String label, bool isDark) {
    final isSelected = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? PayNoraColors.brandSecondary : (isDark ? PayNoraColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? PayNoraColors.brandSecondary : (isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
