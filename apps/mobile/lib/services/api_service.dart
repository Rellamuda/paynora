import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> setAuthToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'jwt_token');
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

  // FX & Transfers
  Future<Map<String, dynamic>> getFXQuote(String from, String to, String amount) async {
    final res = await _dio.get('/fx/quote', queryParameters: {
      'source_currency': from,
      'destination_currency': to,
      'source_amount': amount,
    });
    return res.data;
  }

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

  Future<Map<String, dynamic>> chatAI(String prompt) async {
    final headers = await _authHeaders();
    final res = await _dio.post('/ai/chat',
      data: {'prompt': prompt},
      options: Options(headers: headers),
    );
    return res.data;
  }
}
