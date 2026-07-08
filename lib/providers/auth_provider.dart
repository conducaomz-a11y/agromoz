import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/token_storage.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
      : _repo = repository ?? AuthRepository() {
    ApiClient.instance.onSessionExpired = _handleSessionExpired;
  }

  final AuthRepository _repo;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _isBusy = false;
  String? _error;
  bool _onboardingSeen = false;

  /// Preenchido quando o login falha porque o e-mail está por confirmar (403).
  String? needsVerificationIdentifier;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get isBusy => _isBusy;
  String? get error => _error;
  bool get onboardingSeen => _onboardingSeen;

  /// Called by the Splash screen: restore session if a token exists.
  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

    final token = await TokenStorage.instance.accessToken;
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      _user = await _repo.fetchProfile();
      _status = AuthStatus.authenticated;
    } on ApiException {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> markOnboardingSeen() async {
    _onboardingSeen = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
  }

  Future<bool> login(String identifier, String password) async {
    needsVerificationIdentifier = null;
    final ok = await _guard(() async => _user = await _repo.login(
          identifier: identifier,
          password: password,
        ));
    if (ok) {
      _status = AuthStatus.authenticated;
    } else if (_lastException?.statusCode == 403 &&
        (_lastException?.needsVerification ?? false)) {
      needsVerificationIdentifier =
          _lastException?.verificationIdentifier ?? identifier;
    }
    notifyListeners();
    return ok;
  }

  /// Regista a conta — devolve o resultado (a conta fica por verificar)
  /// ou null em caso de erro (mensagem em [error]).
  Future<RegisterResult?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? province,
    bool wantsBusiness = false,
  }) async {
    RegisterResult? result;
    await _guard(() async {
      result = await _repo.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        province: province,
        wantsBusiness: wantsBusiness,
      );
    });
    return result;
  }

  /// Confirma o código de 6 dígitos e entra na conta.
  Future<bool> verifyEmail(String identifier, String code) =>
      _guard(() async => _user = await _repo.verifyEmail(
            identifier: identifier,
            code: code,
          )).then((ok) {
        if (ok) _status = AuthStatus.authenticated;
        notifyListeners();
        return ok;
      });

  Future<bool> resendCode(String identifier) =>
      _guard(() => _repo.resendCode(identifier));

  Future<bool> forgotPassword(String identifier) =>
      _guard(() => _repo.forgotPassword(identifier));

  Future<bool> verifyOtp(String identifier, String code) =>
      _guard(() => _repo.verifyOtp(identifier: identifier, code: code));

  Future<bool> updateProfile(UserModel updated) =>
      _guard(() async => _user = await _repo.updateProfile(updated));

  Future<bool> changePassword(String current, String next) => _guard(
        () => _repo.changePassword(currentPassword: current, newPassword: next),
      );

  Future<void> logout() async {
    await _repo.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _handleSessionExpired() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  ApiException? _lastException;

  Future<bool> _guard(Future<void> Function() action) async {
    _isBusy = true;
    _error = null;
    _lastException = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _lastException = e;
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
