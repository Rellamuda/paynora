import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayNoraColors.surface,
      appBar: AppBar(
        title: const Text('Account & Compliance Vault', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18)),
        backgroundColor: PayNoraColors.primary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: PayNoraColors.primary,
                  child: const Text('EJ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Emeke John', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: PayNoraColors.primary)),
                      SizedBox(height: 4),
                      Text('emeke.john@paynora.com', style: TextStyle(color: Colors.black54, fontSize: 13)),
                      SizedBox(height: 4),
                      Text('Nigeria 🇳🇬 (+234)', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // KYC Status
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('KYC Verification Tier', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: PayNoraColors.primary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('● APPROVED', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Tier 3: Full International Money Movement, Multi-Currency Holding, and Currency Exchange active.', style: TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Security Features
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Security & Protocol', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: PayNoraColors.primary)),
                SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.fingerprint, color: PayNoraColors.primary),
                  title: Text('Biometric Authentication', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Enabled for transaction authorization', style: TextStyle(fontSize: 12)),
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.security, color: PayNoraColors.secondary),
                  title: Text('Deterministic Double-Entry Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Cryptographically signed transactions', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
