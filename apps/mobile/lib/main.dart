import 'package:flutter/material.dart';
import 'theme/design_tokens.dart';

void main() {
  runApp(const PayNoraApp());
}

class PayNoraApp extends StatelessWidget {
  const PayNoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayNora Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: PayNoraColors.backgroundDefault,
        colorScheme: ColorScheme.fromSeed(
          seedColor: PayNoraColors.brandPrimary,
          primary: PayNoraColors.brandPrimary,
          secondary: PayNoraColors.brandSecondary,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PayNoraColors.brandPrimary,
        title: const Text(
          'PayNora Global',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: PayNoraColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10.0)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Multi-Currency Balance',
                      style: TextStyle(color: PayNoraColors.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('₦2,500,000.00',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: PayNoraColors.brandPrimary)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: PayNoraColors.brandPrimary),
                        child: const Text('Send Money',
                            style: TextStyle(color: Colors.white)),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Exchange'),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text('Initial 11 Active Operating Countries',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: PayNoraColors.brandPrimary)),
            const SizedBox(height: 12),
            const ListTile(
              leading: Text('🇳🇬', style: TextStyle(fontSize: 24)),
              title: Text('Nigeria (NGN)'),
              subtitle: Text('Corridor: Active ↔ GB, US, CA'),
            ),
            const ListTile(
              leading: Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: Text('United Kingdom (GBP)'),
              subtitle: Text('Corridor: Active ↔ NG, US, EU'),
            ),
          ],
        ),
      ),
    );
  }
}
