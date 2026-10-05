import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'screens/send_screen.dart';
import 'screens/wallets_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/design_tokens.dart';

void main() {
  runApp(const ProviderScope(child: PayNoraApp()));
}

class PayNoraApp extends StatelessWidget {
  const PayNoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayNora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        primaryColor: PayNoraColors.primary,
        scaffoldBackgroundColor: PayNoraColors.surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: PayNoraColors.primary,
          primary: PayNoraColors.primary,
          secondary: PayNoraColors.secondary,
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SendScreen(),
    WalletsScreen(),
    AIScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: PayNoraColors.primary,
        unselectedItemColor: Colors.black45,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.send_rounded), label: 'Send'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallets'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
