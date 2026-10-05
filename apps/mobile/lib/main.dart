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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.instance,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'PayNora',
          debugShowCheckedModeBanner: false,
          theme: PayNoraThemes.lightTheme,
          darkTheme: PayNoraThemes.darkTheme,
          themeMode: themeMode,
          home: const MainNavigationShell(),
        );
      },
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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),
      const SendScreen(),
      const WalletsScreen(),
      const AIScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.instance,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? PayNoraColors.darkSurface : Colors.white,
            selectedItemColor: PayNoraColors.brandPrimary,
            unselectedItemColor: isDark ? PayNoraColors.darkTextSecondary : Colors.black45,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.send_rounded), label: 'Send'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallets'),
              BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Nora AI'),
              BottomNavigationBarItem(icon: Icon(Icons.tune_rounded), label: 'Settings'),
            ],
          ),
        );
      },
    );
  }
}
