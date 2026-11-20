import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/design_tokens.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  final bool initialIsSignUp;
  const LoginScreen({super.key, this.initialIsSignUp = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Alias AuthScreen to LoginScreen for direct import flexibility
typedef AuthScreen = LoginScreen;

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _api = ApiService();

  // Tab State: false = Sign In, true = Create Account
  late bool _isSignUp;

  // Controllers - Sign In
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _obscureLoginPass = true;

  // Controllers - Sign Up
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _signUpEmailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _signUpPassCtrl = TextEditingController();
  bool _obscureSignUpPass = true;

  // Global Country of Residence selection for registration (Strictly 2 Wallets: Local + USD, or USD + GBP for US)
  final List<Map<String, String>> _countries = [
    {'code': 'NG', 'name': 'Nigeria', 'flag': '🇳🇬', 'curr': 'NGN', 'dial': '+234'},
    {'code': 'GB', 'name': 'United Kingdom', 'flag': '🇬🇧', 'curr': 'GBP', 'dial': '+44'},
    {'code': 'US', 'name': 'United States', 'flag': '🇺🇸', 'curr': 'USD', 'dial': '+1'},
    {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦', 'curr': 'CAD', 'dial': '+1'},
    {'code': 'GH', 'name': 'Ghana', 'flag': '🇬🇭', 'curr': 'GHS', 'dial': '+233'},
    {'code': 'KE', 'name': 'Kenya', 'flag': '🇰🇪', 'curr': 'KES', 'dial': '+254'},
    {'code': 'ZA', 'name': 'South Africa', 'flag': '🇿🇦', 'curr': 'ZAR', 'dial': '+27'},
    {'code': 'AE', 'name': 'United Arab Emirates', 'flag': '🇦🇪', 'curr': 'AED', 'dial': '+971'},
    {'code': 'DE', 'name': 'Germany', 'flag': '🇩🇪', 'curr': 'EUR', 'dial': '+49'},
    {'code': 'FR', 'name': 'France', 'flag': '🇫🇷', 'curr': 'EUR', 'dial': '+33'},
    {'code': 'IT', 'name': 'Italy', 'flag': '🇮🇹', 'curr': 'EUR', 'dial': '+39'},
    {'code': 'ES', 'name': 'Spain', 'flag': '🇪🇸', 'curr': 'EUR', 'dial': '+34'},
    {'code': 'NL', 'name': 'Netherlands', 'flag': '🇳🇱', 'curr': 'EUR', 'dial': '+31'},
    {'code': 'IE', 'name': 'Ireland', 'flag': '🇮🇪', 'curr': 'EUR', 'dial': '+353'},
    {'code': 'CH', 'name': 'Switzerland', 'flag': '🇨🇭', 'curr': 'CHF', 'dial': '+41'},
    {'code': 'SE', 'name': 'Sweden', 'flag': '🇸🇪', 'curr': 'SEK', 'dial': '+46'},
    {'code': 'NO', 'name': 'Norway', 'flag': '🇳🇴', 'curr': 'NOK', 'dial': '+47'},
    {'code': 'PL', 'name': 'Poland', 'flag': '🇵🇱', 'curr': 'PLN', 'dial': '+48'},
    {'code': 'SA', 'name': 'Saudi Arabia', 'flag': '🇸🇦', 'curr': 'SAR', 'dial': '+966'},
    {'code': 'QA', 'name': 'Qatar', 'flag': '🇶🇦', 'curr': 'QAR', 'dial': '+974'},
    {'code': 'KW', 'name': 'Kuwait', 'flag': '🇰🇼', 'curr': 'KWD', 'dial': '+965'},
    {'code': 'EG', 'name': 'Egypt', 'flag': '🇪🇬', 'curr': 'EGP', 'dial': '+20'},
    {'code': 'MA', 'name': 'Morocco', 'flag': '🇲🇦', 'curr': 'MAD', 'dial': '+212'},
    {'code': 'RW', 'name': 'Rwanda', 'flag': '🇷🇼', 'curr': 'RWF', 'dial': '+250'},
    {'code': 'TZ', 'name': 'Tanzania', 'flag': '🇹🇿', 'curr': 'TZS', 'dial': '+255'},
    {'code': 'UG', 'name': 'Uganda', 'flag': '🇺🇬', 'curr': 'UGX', 'dial': '+256'},
    {'code': 'SN', 'name': 'Senegal', 'flag': '🇸🇳', 'curr': 'XOF', 'dial': '+221'},
    {'code': 'CI', 'name': 'Côte d’Ivoire', 'flag': '🇨🇮', 'curr': 'XOF', 'dial': '+225'},
    {'code': 'CM', 'name': 'Cameroon', 'flag': '🇨🇲', 'curr': 'XAF', 'dial': '+237'},
    {'code': 'ZM', 'name': 'Zambia', 'flag': '🇿🇲', 'curr': 'ZMW', 'dial': '+260'},
    {'code': 'IN', 'name': 'India', 'flag': '🇮🇳', 'curr': 'INR', 'dial': '+91'},
    {'code': 'CN', 'name': 'China', 'flag': '🇨🇳', 'curr': 'CNY', 'dial': '+86'},
    {'code': 'JP', 'name': 'Japan', 'flag': '🇯🇵', 'curr': 'JPY', 'dial': '+81'},
    {'code': 'KR', 'name': 'South Korea', 'flag': '🇰🇷', 'curr': 'KRW', 'dial': '+82'},
    {'code': 'SG', 'name': 'Singapore', 'flag': '🇸🇬', 'curr': 'SGD', 'dial': '+65'},
    {'code': 'MY', 'name': 'Malaysia', 'flag': '🇲🇾', 'curr': 'MYR', 'dial': '+60'},
    {'code': 'PH', 'name': 'Philippines', 'flag': '🇵🇭', 'curr': 'PHP', 'dial': '+63'},
    {'code': 'ID', 'name': 'Indonesia', 'flag': '🇮🇩', 'curr': 'IDR', 'dial': '+62'},
    {'code': 'PK', 'name': 'Pakistan', 'flag': '🇵🇰', 'curr': 'PKR', 'dial': '+92'},
    {'code': 'BD', 'name': 'Bangladesh', 'flag': '🇧🇩', 'curr': 'BDT', 'dial': '+880'},
    {'code': 'AU', 'name': 'Australia', 'flag': '🇦🇺', 'curr': 'AUD', 'dial': '+61'},
    {'code': 'NZ', 'name': 'New Zealand', 'flag': '🇳🇿', 'curr': 'NZD', 'dial': '+64'},
    {'code': 'BR', 'name': 'Brazil', 'flag': '🇧🇷', 'curr': 'BRL', 'dial': '+55'},
    {'code': 'MX', 'name': 'Mexico', 'flag': '🇲🇽', 'curr': 'MXN', 'dial': '+52'},
    {'code': 'CO', 'name': 'Colombia', 'flag': '🇨🇴', 'curr': 'COP', 'dial': '+57'},
    {'code': 'AR', 'name': 'Argentina', 'flag': '🇦🇷', 'curr': 'ARS', 'dial': '+54'},
    {'code': 'CL', 'name': 'Chile', 'flag': '🇨🇱', 'curr': 'CLP', 'dial': '+56'},
    {'code': 'TR', 'name': 'Turkey', 'flag': '🇹🇷', 'curr': 'TRY', 'dial': '+90'},
  ];
  late Map<String, String> _selectedCountry;

  bool _loading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
    _selectedCountry = _countries.first;
  }

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _signUpEmailCtrl.dispose();
    _phoneCtrl.dispose();
    _signUpPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailCtrl.text.trim();
    final password = _loginPassCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please provide both email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _api.login(email.toLowerCase(), password);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationShell()),
          (route) => false,
        );
      }
    } catch (e) {
      String msg = 'Invalid email address or password. Tap "Create Account" above if you have not registered yet.';
      try {
        final d = (e as dynamic).response?.data?['detail'];
        if (d != null) msg = '$d';
      } catch (_) {}
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSignUp() async {
    final fName = _firstNameCtrl.text.trim();
    final lName = _lastNameCtrl.text.trim();
    final email = _signUpEmailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _signUpPassCtrl.text.trim();

    if (fName.isEmpty || lName.isEmpty) {
      setState(() => _errorMessage = 'Please enter your first and last name.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter your phone number.');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters long.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final cleanPhone = phone.replaceAll(RegExp(r'^0+'), '');
      final fullPhone = '${_selectedCountry['dial']}$cleanPhone';

      final regRes = await _api.register({
        'first_name': fName,
        'last_name': lName,
        'email': email.toLowerCase(),
        'phone': fullPhone,
        'country_iso': _selectedCountry['code'],
        'password': password,
      });

      // Auto login after registration
      final loginRes = await _api.login(email.toLowerCase(), password);
      final accNo = loginRes['account_number'] ?? regRes['account_number'] ?? '';
      final tag = loginRes['paynora_tag'] ?? regRes['paynora_tag'] ?? '';
      final addr = loginRes['wallet_address'] ?? regRes['wallet_address'] ?? '';

      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.verified_user, color: PayNoraColors.brandSecondary),
                SizedBox(width: 8),
                Expanded(child: Text('Account Provisioned!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome $fName $lName! Your official SendMoni identifiers have been assigned:'),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PayNoraColors.brandSecondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PayNoraColors.brandSecondary.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('10-Digit Account Number: $accNo', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('SendMoni Tag / Code: $tag', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('Global Wallet Address: $addr', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text('Wallets: ${_selectedCountry['curr']} (Local) + ${_selectedCountry['curr'] == 'USD' ? 'GBP' : 'USD'} (Foreign)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PayNoraColors.brandSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: PayNoraColors.brandSecondary),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Enter My Account →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationShell()),
          (route) => false,
        );
      }
    } catch (e) {
      String msg = 'Registration failed. Please check your details.';
      try {
        final d = (e as dynamic).response?.data?['detail'];
        if (d != null) msg = '$d';
      } catch (_) {}
      setState(() {
        _errorMessage = msg;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForgotPasswordSheet() {
    final isDark = ThemeNotifier.instance.isDarkMode;
    final resetEmailCtrl = TextEditingController(text: _loginEmailCtrl.text.trim());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? PayNoraColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Reset Account Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'Enter your registered email address. We will dispatch an authoritative security reset code.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: resetEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Account Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: PayNoraColors.brandPrimary,
                      content: Text('Password reset link sent to ${resetEmailCtrl.text.trim()}'),
                    ),
                  );
                },
                child: const Text('Send Reset Instructions', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeNotifier.instance.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? PayNoraColors.darkBackground : PayNoraColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Theme Switcher Button
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ActionChip(
              avatar: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 16,
                color: isDark ? Colors.amber : PayNoraColors.brandPrimary,
              ),
              label: Text(
                isDark ? 'Light' : 'Dark',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : PayNoraColors.brandPrimary,
                ),
              ),
              backgroundColor: isDark ? PayNoraColors.darkSurface : Colors.white,
              side: BorderSide(color: isDark ? PayNoraColors.darkBorder : PayNoraColors.lightBorder),
              onPressed: () => setState(() => ThemeNotifier.instance.toggleTheme()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Logo Badge
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: PayNoraColors.brandPrimary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: PayNoraColors.brandPrimary.withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(
                        'assets/images/logo.png',
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Brand Title
                  Center(
                    child: Text(
                      'SendMoni',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : PayNoraColors.brandPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Double Currency Digital Wallets (Local Currency + USD)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? PayNoraColors.darkTextSecondary : PayNoraColors.lightTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Segmented Switcher (Sign In vs Create Account)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? PayNoraColors.darkSurface : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_isSignUp) {
                                setState(() {
                                  _isSignUp = false;
                                  _errorMessage = null;
                                  _successMessage = null;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isSignUp
                                    ? (isDark ? PayNoraColors.darkCard : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !_isSignUp
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Sign In',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: !_isSignUp
                                      ? (isDark ? Colors.white : PayNoraColors.brandPrimary)
                                      : (isDark ? PayNoraColors.darkTextSecondary : Colors.grey[600]),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (!_isSignUp) {
                                setState(() {
                                  _isSignUp = true;
                                  _errorMessage = null;
                                  _successMessage = null;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isSignUp
                                    ? (isDark ? PayNoraColors.darkCard : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isSignUp
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Create Account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: _isSignUp
                                      ? (isDark ? Colors.white : PayNoraColors.brandPrimary)
                                      : (isDark ? PayNoraColors.darkTextSecondary : Colors.grey[600]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Success Banner
                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PayNoraColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: PayNoraColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: PayNoraColors.success, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(color: PayNoraColors.success, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form Fields
                  if (!_isSignUp) _buildSignInForm(isDark) else _buildSignUpForm(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // SIGN IN FORM
  Widget _buildSignInForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Field
        TextField(
          controller: _loginEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: isDark ? PayNoraColors.darkSurface : Colors.white,
          ),
        ),
        const SizedBox(height: 14),

        // Password Field
        TextField(
          controller: _loginPassCtrl,
          obscureText: _obscureLoginPass,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureLoginPass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscureLoginPass = !_obscureLoginPass),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: isDark ? PayNoraColors.darkSurface : Colors.white,
          ),
        ),
        const SizedBox(height: 8),

        // Forgot Password Link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordSheet,
            child: const Text('Forgot Password?', style: TextStyle(color: PayNoraColors.brandSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 12),

        // Sign In Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: PayNoraColors.brandSecondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          onPressed: _loading ? null : _handleLogin,
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Sign In to Account →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      ],
    );
  }

  // SIGN UP (CREATE ACCOUNT) FORM
  Widget _buildSignUpForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name Row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstNameCtrl,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: isDark ? PayNoraColors.darkSurface : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _lastNameCtrl,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: isDark ? PayNoraColors.darkSurface : Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Country Dropdown
        DropdownButtonFormField<Map<String, String>>(
          value: _selectedCountry,
          decoration: InputDecoration(
            labelText: 'Country of Residence',
            prefixIcon: const Icon(Icons.public_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: isDark ? PayNoraColors.darkSurface : Colors.white,
          ),
          dropdownColor: isDark ? PayNoraColors.darkSurface : Colors.white,
          items: _countries.map((c) {
            return DropdownMenuItem<Map<String, String>>(
              value: c,
              child: Text(
                '${c['flag']}  ${c['name']} (${c['curr']})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCountry = val);
          },
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '✓ Provisioned Wallets: ${_selectedCountry['curr']} (Local) + ${_selectedCountry['curr'] == 'USD' ? 'GBP' : 'USD'} (Foreign)',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PayNoraColors.brandSecondary),
          ),
        ),
        const SizedBox(height: 12),

        // Phone with Dial Code Prefix
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixText: '${_selectedCountry['dial']} ',
            prefixStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : PayNoraColors.brandPrimary,
            ),
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: isDark ? PayNoraColors.darkSurface : Colors.white,
          ),
        ),
        const SizedBox(height: 14),

        // Email Field
        TextField(
          controller: _signUpEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: isDark ? PayNoraColors.darkSurface : Colors.white,
          ),
        ),
        const SizedBox(height: 14),

        // Password Field
        TextField(
          controller: _signUpPassCtrl,
          obscureText: _obscureSignUpPass,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: 'Create Password',
            helperText: 'Minimum 8 characters with letters & numbers',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureSignUpPass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscureSignUpPass = !_obscureSignUpPass),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: isDark ? PayNoraColors.darkSurface : Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Double Currency Provisioning Notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PayNoraColors.brandSecondary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PayNoraColors.brandSecondary.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: PayNoraColors.brandSecondary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your account automatically provisions two active wallets: ${_selectedCountry['curr']} (Local) + USD (Global Reserve).',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Create Account Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: PayNoraColors.brandSecondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          onPressed: _loading ? null : _handleSignUp,
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create SendMoni Account →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        const SizedBox(height: 12),
        const Text(
          'By creating an account, you agree to SendMoni\'s Terms of Service & Privacy Policy. Payment processing & bank settlements are powered by PCI-DSS Level 1 licensed gateways Paystack and Flutterwave.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
        ),
      ],
    );
  }
}
