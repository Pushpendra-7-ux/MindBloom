import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    // Add logging interceptor in debug mode for easier debugging
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('🌐 API: $obj'),
      ));
    }
  }

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Content-Type': 'application/json'},
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> setToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  Future<Options> _authOptions() async {
    final token = await getToken();
    return Options(headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  // Auth
  Future<Response> signup(String name, String email, String password, String? phone) async {
    return await _dio.post(AppConstants.signupEndpoint, data: {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null) 'phone': phone,
    });
  }

  Future<Response> login(String email, String password) async {
    return await _dio.post(AppConstants.loginEndpoint, data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> getProfile() async {
    return await _dio.get(AppConstants.profileEndpoint, options: await _authOptions());
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return await _dio.put(AppConstants.updateProfileEndpoint, data: data, options: await _authOptions());
  }

  Future<Response> setCategory(String category) async {
    return await _dio.put(AppConstants.categoryEndpoint, data: {'category': category}, options: await _authOptions());
  }

  // Mood
  Future<Response> submitMoodCheckin(Map<String, dynamic> data) async {
    return await _dio.post(AppConstants.moodCheckinEndpoint, data: data, options: await _authOptions());
  }

  Future<Response> getMoodHistory({int days = 30}) async {
    return await _dio.get('${AppConstants.moodHistoryEndpoint}?days=$days', options: await _authOptions());
  }

  Future<Response> getWeeklyMood() async {
    return await _dio.get(AppConstants.moodWeeklyEndpoint, options: await _authOptions());
  }

  Future<Response> getLatestMood() async {
    return await _dio.get(AppConstants.moodLatestEndpoint, options: await _authOptions());
  }

  // Recommendations
  Future<Response> getRecommendations(Map<String, dynamic> data) async {
    return await _dio.post(AppConstants.recommendationsEndpoint, data: data, options: await _authOptions());
  }

  // Appointments
  Future<Response> createAppointment(Map<String, dynamic> data) async {
    return await _dio.post(AppConstants.appointmentsEndpoint, data: data, options: await _authOptions());
  }

  Future<Response> getAppointments({bool upcoming = true}) async {
    return await _dio.get('${AppConstants.appointmentsEndpoint}?upcoming=$upcoming', options: await _authOptions());
  }

  Future<Response> updateAppointment(String id, Map<String, dynamic> data) async {
    return await _dio.put('${AppConstants.appointmentsEndpoint}/$id', data: data, options: await _authOptions());
  }

  Future<Response> deleteAppointment(String id) async {
    return await _dio.delete('${AppConstants.appointmentsEndpoint}/$id', options: await _authOptions());
  }

  // Tracker
  Future<Response> updateTracker(Map<String, dynamic> data) async {
    return await _dio.post(AppConstants.trackerEndpoint, data: data, options: await _authOptions());
  }

  Future<Response> getTrackerHistory({int days = 7}) async {
    return await _dio.get('${AppConstants.trackerEndpoint}?days=$days', options: await _authOptions());
  }

  Future<Response> getTodayTracker() async {
    return await _dio.get(AppConstants.trackerTodayEndpoint, options: await _authOptions());
  }
}
