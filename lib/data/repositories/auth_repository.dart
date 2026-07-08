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

  /// Regista a conta. A conta fica POR VERIFICAR — a API envia um código
  /// de 6 dígitos para o e-mail (mesmo mecanismo do site).
  Future<RegisterResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? province,
    bool wantsBusiness = false,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'province': province,
        'wants_business': wantsBusiness,
      },
    );
    return RegisterResult(
      message: data['message'] as String? ?? '',
      identifier: data['identifier'] as String? ?? email,
      debugCode: data['debug_code'] as String?,
    );
  }

  /// Confirma o código de verificação e ENTRA (a API devolve tokens + user).
  Future<UserModel> verifyEmail({
    required String identifier,
    required String code,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.verifyEmail,
      data: {'identifier': identifier, 'code': code},
    );
    await _persistTokens(data);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> resendCode(String identifier) => _client.post<void>(
        ApiEndpoints.resendCode,
        data: {'identifier': identifier},
      );

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

/// Resultado do registo — a conta fica pendente de verificação por e-mail.
class RegisterResult {
  const RegisterResult({
    required this.message,
    required this.identifier,
    this.debugCode,
  });

  final String message;
  final String identifier;

  /// Só em modo de teste da API (DEBUG_OTP) — nunca em produção.
  final String? debugCode;
}
