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

  Future<Map<String, dynamic>> verifyKYC(String docType, String docNumber) async {
    final headers = await _authHeaders();
    final res = await _dio.post('/kyc/verify',
      data: {'document_type': docType, 'document_number': docNumber},
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
    final res = await _dio.get('/transfers');
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
  Future<List<dynamic>> getBillOperators([String country = 'NG']) async {
    final res = await _dio.get('/bills/operators', queryParameters: {'country': country});
    return (res.data['operators'] as List<dynamic>?) ?? [];
  }

  Future<List<dynamic>> getDataPlans(String operatorCode) async {
    final res = await _dio.get('/bills/data-plans', queryParameters: {'operator_code': operatorCode});
    return (res.data['plans'] as List<dynamic>?) ?? [];
  }

  Future<List<dynamic>> getElectricityProviders([String country = 'NG']) async {
    final res = await _dio.get('/bills/electricity-providers', queryParameters: {'country': country});
    return (res.data['providers'] as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> validateMeter({
    required String discoCode,
    required String meterNumber,
    String meterType = 'PREPAID',
    String countryIso = 'NG',
  }) async {
    final res = await _dio.post('/bills/validate-meter', data: {
      'disco_code': discoCode,
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
    required String discoCode,
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
        'disco_code': discoCode,
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
}
