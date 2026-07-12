import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Single Dio instance shared by every repository.
///
/// Responsibilities:
///  * attaches the Bearer token to every request
///  * transparently refreshes an expired token once, then retries
///  * normalizes every failure into [ApiException]
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final String? token = await TokenStorage.instance.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // One silent refresh-and-retry on 401.
          if (error.response?.statusCode == 401 &&
              error.requestOptions.extra['retried'] != true) {
            final bool refreshed = await _tryRefreshToken();
            if (refreshed) {
              final options = error.requestOptions..extra['retried'] = true;
              try {
                final response = await _dio.fetch<dynamic>(options);
                return handler.resolve(response);
              } on DioException catch (e) {
                return handler.next(e);
              }
            }
          }
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  /// Session-expired hook — AuthProvider registers a logout callback here.
  VoidCallback? onSessionExpired;

  Future<bool> _tryRefreshToken() async {
    final String? refresh = await TokenStorage.instance.refreshToken;
    if (refresh == null) {
      onSessionExpired?.call();
      return false;
    }
    try {
      final response = await Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl))
          .post<Map<String, dynamic>>(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refresh},
      );
      final data = response.data;
      final String? newToken = data?['access_token'] as String?;
      if (newToken == null) return false;
      await TokenStorage.instance.saveTokens(
        accessToken: newToken,
        refreshToken: data?['refresh_token'] as String?,
      );
      return true;
    } catch (_) {
      await TokenStorage.instance.clear();
      onSessionExpired?.call();
      return false;
    }
  }

  // ── Verb helpers ─────────────────────────────────────

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _run(() => _dio.get<T>(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? data}) =>
      _run(() => _dio.post<T>(path, data: data));

  Future<T> put<T>(String path, {Object? data}) =>
      _run(() => _dio.put<T>(path, data: data));

  Future<T> patch<T>(String path, {Object? data}) =>
      _run(() => _dio.patch<T>(path, data: data));

  Future<T> delete<T>(String path, {Object? data}) =>
      _run(() => _dio.delete<T>(path, data: data));

  Future<T> _run<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
