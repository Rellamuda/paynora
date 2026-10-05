import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _twoFactorEnabled = true;
  bool _biometricsEnabled = true;

  void _showKYCModal() {
    final isDark = ThemeNotifier.instance.isDarkMode;
    String docType = 'PASSPORT';
    final docNumberCtrl = TextEditingController(text: 'A19482019');

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
              const Text('Identity Verification & KYC Tier', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 4),
              const Text('Verify regulatory identity under CBN, FCA & FinCEN compliance.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: docType,
                decoration: InputDecoration(
                  labelText: 'Document Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                dropdownColor: isDark ? PayNoraColors.darkSurface : Colors.white,
                items: const [
                  DropdownMenuItem(value: 'PASSPORT', child: Text('International Passport')),
                  DropdownMenuItem(value: 'NATIONAL_ID', child: Text('National Identity Number / Card')),
                  DropdownMenuItem(value: 'DRIVERS_LICENSE', child: Text("Driver's License")),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => docType = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: docNumberCtrl,
                decoration: InputDecoration(
                  labelText: 'Document Number',
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
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Identity verified successfully! Tier 3 active.')),
                    );
                  },
                  child: const Text('Submit Document for Instant Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

    return Scaffold(
      backgroundColor: isDark ? PayNoraColors.darkBackground : PayNoraColors.lightBackground,
      appBar: AppBar(
        title: const Text('Account, Theme & Compliance', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18)),
        backgroundColor: isDark ? PayNoraColors.darkSurface : PayNoraColors.brandPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? PayNoraColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: PayNoraColors.brandPrimary,
                  child: const Text('EJ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emeke John', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: isDark ? Colors.white : PayNoraColors.lightTextPrimary)),
                      const SizedBox(height: 2),
                      const Text('emeke.john@paynora.com', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 2),
                      const Text('Nigeria 🇳🇬 (+234)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // THEME SWITCHER CARD
          Container(
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
                    Text('Appearance & Theme', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : PayNoraColors.brandPrimary)),
                    Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: PayNoraColors.brandSecondary, size: 20),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Choose your preferred color theme across the application.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 14),

                Row(
                  children: [
                    // Light Theme Option
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (isDark) {
                            setState(() {
                              ThemeNotifier.instance.setTheme(ThemeMode.light);
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: !isDark ? PayNoraColors.brandSecondary.withOpacity(0.12) : (isDark ? PayNoraColors.darkCardSubtle : PayNoraColors.lightCardSubtle),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: !isDark ? PayNoraColors.brandSecondary : Colors.transparent, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('☀️ Light Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  if (!isDark) const Icon(Icons.check_circle, color: PayNoraColors.brandSecondary, size: 16),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text('Clean slate daytime', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Dark Theme Option
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!isDark) {
                            setState(() {
                              ThemeNotifier.instance.setTheme(ThemeMode.dark);
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? PayNoraColors.brandSecondary.withOpacity(0.15) : (isDark ? PayNoraColors.darkCardSubtle : PayNoraColors.lightCardSubtle),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? PayNoraColors.brandSecondary : Colors.transparent, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('🌙 Pure Dark (OLED)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  if (isDark) const Icon(Icons.check_circle, color: PayNoraColors.brandSecondary, size: 16),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text('Pitch black aesthetic', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // KYC Status Card
          Container(
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
                    Text('KYC Verification Tier', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : PayNoraColors.brandPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: PayNoraColors.successBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('● APPROVED', style: TextStyle(color: PayNoraColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Tier 3: Full International Money Movement, Multi-Currency Holding, and Currency Exchange active.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PayNoraColors.brandSecondary,
                    side: const BorderSide(color: PayNoraColors.brandSecondary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _showKYCModal,
                  child: const Text('Update Verification Documents', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Security Settings Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? PayNoraColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Security & Biometrics', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : PayNoraColors.brandPrimary)),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Two-Factor Authentication (2FA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Required for dispatches above \$1,000', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  activeColor: PayNoraColors.brandSecondary,
                  value: _twoFactorEnabled,
                  onChanged: (val) => setState(() => _twoFactorEnabled = val),
                ),
                const Divider(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Biometric FaceID / Fingerprint Lock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Quick app authentication with hardware enclave', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  activeColor: PayNoraColors.brandSecondary,
                  value: _biometricsEnabled,
                  onChanged: (val) => setState(() => _biometricsEnabled = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text('PayNora Mobile Core v1.0.0 • Build 2026.10', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
