import 'package:dio/dio.dart';

/// Domain-level error the UI can render safely.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.isNetwork = false,
    this.needsVerification = false,
    this.verificationIdentifier,
  });

  final String message;
  final int? statusCode;
  final bool isNetwork;

  /// A API pediu verificação de e-mail (registo/login por confirmar).
  final bool needsVerification;
  final String? verificationIdentifier;

  bool get isUnauthorized => statusCode == 401;

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'A ligação demorou demasiado. Verifique a sua internet e tente novamente.',
          isNetwork: true,
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'Sem ligação à internet. Verifique a sua rede.',
          isNetwork: true,
        );
      case DioExceptionType.badResponse:
        final int? code = e.response?.statusCode;
        final data = e.response?.data;
        final String serverMsg = (data is Map && data['message'] is String)
            ? data['message'] as String
            : _defaultForCode(code);
        return ApiException(
          serverMsg,
          statusCode: code,
          needsVerification:
              data is Map && data['needs_verification'] == true,
          verificationIdentifier:
              data is Map ? data['identifier'] as String? : null,
        );
      case DioExceptionType.cancel:
        return const ApiException('Pedido cancelado.');
      default:
        return const ApiException('Ocorreu um erro inesperado. Tente novamente.');
    }
  }

  static String _defaultForCode(int? code) {
    switch (code) {
      case 400:
        return 'Pedido inválido. Verifique os dados introduzidos.';
      case 401:
        return 'Sessão expirada. Inicie sessão novamente.';
      case 403:
        return 'Não tem permissão para esta acção.';
      case 404:
        return 'Recurso não encontrado.';
      case 422:
        return 'Dados inválidos. Verifique os campos.';
      case 500:
      case 502:
      case 503:
        return 'O servidor está indisponível. Tente mais tarde.';
      default:
        return 'Ocorreu um erro. Tente novamente.';
    }
  }

  @override
  String toString() => message;
}
