import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 45),
    headers: {'Content-Type': 'application/json'},
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> setAuthToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: 'saved_login_email', value: email);
    await _storage.write(key: 'saved_login_password', value: password);
  }

  Future<Map<String, String>> getSavedCredentials() async {
    final email = await _storage.read(key: 'saved_login_email') ?? '';
    final password = await _storage.read(key: 'saved_login_password') ?? '';
    return {'email': email, 'password': password};
  }

  Future<void> clearSavedCredentials() async {
    await _storage.delete(key: 'saved_login_email');
    await _storage.delete(key: 'saved_login_password');
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    final headers = await _authHeaders();
    try {
      final res = await _dio.delete('/auth/account', options: Options(headers: headers));
      await logout();
      await clearSavedCredentials();
      return res.data;
    } catch (_) {
      await logout();
      await clearSavedCredentials();
      return {'status': 'DELETED'};
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAuthToken();
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  // Health & Catalog
  Future<Map<String, dynamic>> checkHealth() async {
    final res = await _dio.get('/health');
    return res.data;
  }

  Future<List<dynamic>> getActiveCountries() async {
    final res = await _dio.get('/countries/active');
    return res.data['countries'] ?? [];
  }

  Future<List<dynamic>> getCorridors() async {
    final res = await _dio.get('/corridors');
    return res.data['corridors'] ?? [];
  }

  Future<List<dynamic>> getCurrencies() async {
    final res = await _dio.get('/currencies');
    return res.data['currencies'] ?? [];
  }

  // Auth & Onboarding
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await _dio.post('/auth/register', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> verifyOTP(String email, String otpCode) async {
    final res = await _dio.post('/auth/verify-otp', data: {
      'email': email,
      'otp_code': otpCode,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    if (res.data['access_token'] != null) {
      await setAuthToken(res.data['access_token']);
      await saveCredentials(email, password);
    }
    return res.data;
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final headers = await _authHeaders();
    final res = await _dio.get('/users/me', options: Options(headers: headers));
    return res.data;
  }

  Future<Map<String, dynamic>> getKYCStatus() async {
    final headers = await _authHeaders();
    final res = await _dio.get('/kyc/status', options: Options(headers: headers));
    return res.data;
  }

  Future<Map<String, dynamic>> verifyKYC(
    String docType,
    String docNumber, {
    bool selfieCaptured = true,
    bool idPhotoCaptured = true,
    String? selfieHash,
    String? idImageBase64,
    String? selfieImageBase64,
  }) async {
    final headers = await _authHeaders();
    final res = await _dio.post('/kyc/verify',
      data: {
        'document_type': docType,
        'document_number': docNumber,
        'selfie_captured': selfieCaptured,
        'id_photo_captured': idPhotoCaptured,
        'selfie_hash': selfieHash,
        if (idImageBase64 != null) 'id_image_base64': idImageBase64,
        if (selfieImageBase64 != null) 'selfie_image_base64': selfieImageBase64,
      },
      options: Options(headers: headers),
    );
    return res.data;
  }

  // Wallets
  Future<List<dynamic>> getWallets() async {
    final headers = await _authHeaders();
    final res = await _dio.get('/wallets', options: Options(headers: headers));
    return res.data['wallets'] ?? [];
  }

  Future<Map<String, dynamic>> activateWallet(String currency) async {
    final headers = await _authHeaders();
    final res = await _dio.post('/wallets',
      data: {'currency': currency},
      options: Options(headers: headers),
    );
    return res.data;
  }

  Future<Map<String, dynamic>> fundWallet(String currency, String amount) async {
    final headers = await _authHeaders();
    final res = await _dio.post('/wallets/fund',
      data: {'currency': currency, 'amount': amount},
      options: Options(headers: headers),
    );
    return res.data;
  }

  Future<Map<String, dynamic>> initializeDeposit({
    required String currency,
    required String amount,
    String? gateway,
  }) async {
    final headers = await _authHeaders();
    final res = await _dio.post('/wallets/deposit/initialize',
      data: {
        'currency': currency,
        'amount': amount,
        if (gateway != null) 'gateway': gateway,
      },
      options: Options(headers: headers),
    );
    return res.data;
  }

  Future<Map<String, dynamic>> verifyDeposit({
    required String reference,
    required String gateway,
    required String currency,
  }) async {
    final headers = await _authHeaders();
    final res = await _dio.post('/wallets/deposit/verify',
      data: {
        'reference': reference,
        'gateway': gateway,
        'currency': currency,
      },
      options: Options(headers: headers),
    );
    return res.data;
  }

  // Dedicated Virtual Bank Account (NUBAN via Paystack-Titan / Wema / Flutterwave)
  Future<Map<String, dynamic>> getVirtualAccount() async {
    final headers = await _authHeaders();
    final res = await _dio.get('/wallets/virtual-account', options: Options(headers: headers));
    return res.data;
  }

  Future<Map<String, dynamic>> createVirtualAccount({
    String provider = 'PAYSTACK',
    String preferredBank = 'titan-paystack',
    String? bvn,
  }) async {
    final headers = await _authHeaders();
    final res = await _dio.post(
      '/wallets/virtual-account',
      data: {
        'provider': provider,
        'preferred_bank': preferredBank,
        if (bvn != null && bvn.trim().isNotEmpty) 'bvn': bvn.trim(),
      },
      options: Options(headers: headers),
    );
    return res.data;
  }

  Future<Map<String, dynamic>> convertWallet(
    String fromCurrency,
    String toCurrency,
    String fromAmount,
    String toAmount,
  ) async {
    final headers = await _authHeaders();
    final res = await _dio.post('/wallets/convert',
      data: {
        'from_currency': fromCurrency,
        'to_currency': toCurrency,
        'from_amount': fromAmount,
        'to_amount': toAmount,
      },
      options: Options(headers: headers),
    );
    return res.data;
  }

  // FX & Quotes
  Future<Map<String, dynamic>> getFXQuote(String from, String to, String amount) async {
    final res = await _dio.get('/fx/quote', queryParameters: {
      'source_currency': from,
      'destination_currency': to,
      'source_amount': amount,
    });
    return res.data;
  }

  // Transfers
  Future<Map<String, dynamic>> createTransfer(Map<String, dynamic> payload, String idempotencyKey) async {
    final headers = await _authHeaders();
    headers['Idempotency-Key'] = idempotencyKey;
    final res = await _dio.post('/transfers',
      data: payload,
      options: Options(headers: headers),
    );
    return res.data;
  }

  Future<List<dynamic>> getTransfers() async {
    final headers = await _authHeaders();
    final res = await _dio.get('/transfers', options: Options(headers: headers));
    return res.data['transfers'] ?? [];
  }

  // Beneficiaries
  Future<List<dynamic>> getBeneficiaries() async {
    final headers = await _authHeaders();
    final res = await _dio.get('/beneficiaries', options: Options(headers: headers));
    return res.data['beneficiaries'] ?? [];
  }

  Future<Map<String, dynamic>> createBeneficiary(
    String name,
    String countryIso,
    String currency,
    Map<String, dynamic> accountDetails,
  ) async {
    final headers = await _authHeaders();
    final res = await _dio.post('/beneficiaries',
      data: {
        'name': name,
        'country_iso': countryIso,
        'currency': currency,
        'account_details': accountDetails,
      },
      options: Options(headers: headers),
    );
    return res.data;
  }

  // AI Assistant
  Future<Map<String, dynamic>> chatAI(String prompt) async {
    final headers = await _authHeaders();
    final res = await _dio.post('/ai/chat',
      data: {'prompt': prompt},
      options: Options(headers: headers),
    );
    return res.data;
  }

  // Local Banking & Account Resolution
  Future<List<dynamic>> getSupportedBanks([String country = 'NG']) async {
    final res = await _dio.get('/transfers/banks', queryParameters: {'country': country});
    return (res.data['banks'] as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> resolveBankAccount({
    required String accountNumber,
    required String bankCode,
    String currency = 'NGN',
  }) async {
    final res = await _dio.post('/transfers/resolve-account', data: {
      'account_number': accountNumber,
      'account_bank': bankCode,
      'currency': currency,
    });
    return res.data;
  }

  // Bills & Utilities (Airtime, Data, Electricity)
  Future<Map<String, dynamic>> detectOperator(String phone, [String country = 'NG']) async {
    final res = await _dio.get('/bills/detect-operator', queryParameters: {'phone': phone, 'country': country});
    return res.data;
  }

  Future<List<dynamic>> getBillOperators([String country = 'NG']) async {
    final res = await _dio.get('/bills/operators', queryParameters: {'country': country});
    return (res.data['operators'] as List<dynamic>?) ?? [];
  }

  Future<List<dynamic>> getDataPlans(String operatorCode, [String country = 'NG']) async {
    final res = await _dio.get('/bills/data-plans', queryParameters: {'operator_code': operatorCode, 'country': country});
    return (res.data['plans'] as List<dynamic>?) ?? [];
  }

  Future<List<dynamic>> getElectricityProviders([String country = 'NG']) async {
    final res = await _dio.get('/bills/electricity-providers', queryParameters: {'country': country});
    return (res.data['providers'] as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> validateMeter({
    String? discoCode,
    required String meterNumber,
    String meterType = 'PREPAID',
    String countryIso = 'NG',
  }) async {
    final res = await _dio.post('/bills/validate-meter', data: {
      if (discoCode != null && discoCode.isNotEmpty) 'disco_code': discoCode,
      'meter_number': meterNumber,
      'meter_type': meterType,
      'country_iso': countryIso,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> purchaseAirtime({
    required String phone,
    required String operatorCode,
    required String amount,
    String countryIso = 'NG',
  }) async {
    final headers = await _authHeaders();
    final res = await _dio.post(
      '/bills/airtime',
      data: {
        'phone_number': phone,
        'operator_code': operatorCode,
        'amount': amount,
        'country_iso': countryIso,
      },
      options: Options(headers: headers),
    );
    return res.data;
  }

  Future<Map<String, dynamic>> purchaseData({
    required String phone,
    required String operatorCode,
    required String planId,
    required String amount,
    String countryIso = 'NG',
  }) async {
    final headers = await _authHeaders();
    final res = await _dio.post(
      '/bills/data',
      data: {
        'phone_number': phone,
        'operator_code': operatorCode,
        'plan_id': planId,
        'amount': amount,
        'country_iso': countryIso,
      },
      options: Options(headers: headers),
    );
    return res.data;
  }

  Future<Map<String, dynamic>> purchaseElectricity({
    String? discoCode,
    required String meterNumber,
    required String meterType,
    required String amount,
    String? customerName,
    String countryIso = 'NG',
  }) async {
    final headers = await _authHeaders();
    final res = await _dio.post(
      '/bills/electricity',
      data: {
        if (discoCode != null && discoCode.isNotEmpty) 'disco_code': discoCode,
        'meter_number': meterNumber,
        'meter_type': meterType,
        'amount': amount,
        'customer_name': customerName,
        'country_iso': countryIso,
      },
      options: Options(headers: headers),
    );
    return res.data;
  }

  // App-to-App (P2P) Transfers
  Future<Map<String, dynamic>> lookupP2PUser(String query) async {
    final headers = await _authHeaders();
    final res = await _dio.get(
      '/p2p/lookup',
      queryParameters: {'q': query},
      options: Options(headers: headers),
    );
    return res.data;
  }

  Future<Map<String, dynamic>> getP2PQuote({
    required String recipientUserId,
    required String sourceCurrency,
    required String amount,
    String receiveMode = 'LOCAL',
  }) async {
    final headers = await _authHeaders();
    final res = await _dio.get(
      '/p2p/quote',
      queryParameters: {
        'recipient_user_id': recipientUserId,
        'source_currency': sourceCurrency,
        'amount': amount,
        'receive_mode': receiveMode,
      },
      options: Options(headers: headers),
    );
    return res.data;
  }

  Future<Map<String, dynamic>> createP2PTransfer({
    required String recipientUserId,
    required String sourceCurrency,
    required String amount,
    required String receiveMode,
    String? note,
    required String idempotencyKey,
  }) async {
    final headers = await _authHeaders();
    headers['Idempotency-Key'] = idempotencyKey;
    final res = await _dio.post(
      '/p2p/transfer',
      data: {
        'recipient_user_id': recipientUserId,
        'source_currency': sourceCurrency,
        'amount': amount,
        'receive_mode': receiveMode,
        'note': note,
      },
      options: Options(headers: headers),
    );
    return res.data;
  }

  // Recent Bills History
  Future<List<dynamic>> getRecentAirtimePurchases() async {
    final headers = await _authHeaders();
    final res = await _dio.get(
      '/bills/airtime/recent',
      options: Options(headers: headers),
    );
    return (res.data['transactions'] as List<dynamic>?) ?? [];
  }
}
