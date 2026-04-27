import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

// Auth State
class AuthState {
  final String? token;
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.token, this.user, this.isLoading = false, this.error});

  AuthState copyWith({String? token, UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api = ApiService();

  AuthNotifier() : super(AuthState()) {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    final token = await _api.getToken();
    if (token != null) {
      state = state.copyWith(token: token, isLoading: true);
      try {
        final response = await _api.getProfile();
        final user = UserModel.fromJson(response.data['user']);
        state = state.copyWith(user: user, isLoading: false);
      } catch (e) {
        await _api.clearToken();
        state = AuthState();
      }
    }
  }

  Future<bool> signup(String name, String email, String password, String? phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.signup(name, email, password, phone);
      final token = response.data['token'];
      final user = UserModel.fromJson(response.data['user']);
      await _api.setToken(token);
      state = AuthState(token: token, user: user);
      return true;
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.login(email, password);
      final token = response.data['token'];
      final user = UserModel.fromJson(response.data['user']);
      await _api.setToken(token);
      state = AuthState(token: token, user: user);
      return true;
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<void> setCategory(String category) async {
    try {
      await _api.setCategory(category);
      if (state.user != null) {
        state = state.copyWith(user: state.user!.copyWith(category: category));
      }
    } catch (e) {
      // Silently fail, category is not critical
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _api.updateProfile(data);
      final user = UserModel.fromJson(response.data['user']);
      state = state.copyWith(user: user);
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
    }
  }

  Future<void> refreshUser() async {
    try {
      final response = await _api.getProfile();
      final user = UserModel.fromJson(response.data['user']);
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<void> logout() async {
    await _api.clearToken();
    state = AuthState();
  }

  String _extractError(dynamic e) {
    if (e is Exception) {
      try {
        final dynamic dioError = e;
        if (dioError.response?.data != null) {
          return dioError.response.data['message'] ?? 'Something went wrong';
        }
      } catch (_) {}
    }
    return 'Network error. Please try again.';
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
