import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;
  final ApiClient _client;

  Future<UserModel> login({
    required String identifier, // email or phone
    required String password,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'identifier': identifier, 'password': password},
    );
    await _persistTokens(data);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? province,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
        'province': province,
      },
    );
    await _persistTokens(data);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> forgotPassword(String identifier) => _client.post<void>(
        ApiEndpoints.forgotPassword,
        data: {'identifier': identifier},
      );

  Future<void> verifyOtp({required String identifier, required String code}) =>
      _client.post<void>(
        ApiEndpoints.verifyOtp,
        data: {'identifier': identifier, 'code': code},
      );

  Future<UserModel> fetchProfile() async {
    final data = await _client.get<Map<String, dynamic>>(ApiEndpoints.profile);
    return UserModel.fromJson(
      (data['data'] ?? data) as Map<String, dynamic>,
    );
  }

  Future<UserModel> updateProfile(UserModel user) async {
    final data = await _client.put<Map<String, dynamic>>(
      ApiEndpoints.profile,
      data: user.toJson(),
    );
    return UserModel.fromJson((data['data'] ?? data) as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _client.post<void>(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

  Future<void> logout() async {
    try {
      await _client.post<void>(ApiEndpoints.logout);
    } catch (_) {
      // Best effort: clear local session even if the network call fails.
    }
    await TokenStorage.instance.clear();
  }

  Future<void> _persistTokens(Map<String, dynamic> data) =>
      TokenStorage.instance.saveTokens(
        accessToken: data['access_token'] as String? ?? '',
        refreshToken: data['refresh_token'] as String?,
      );
}
