import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.correlationId,
    this.details = const <String, dynamic>{},
    this.statusCode,
  });

  final String code;
  final String message;
  final String? correlationId;
  final Map<String, dynamic> details;
  final int? statusCode;

  String get userMessage => switch (code) {
        'INVALID_CREDENTIALS' => 'E-mail ou senha inválidos.',
        'NETWORK_ERROR' => 'Sem conexão com o servidor. Verifique sua internet.',
        'TIMEOUT' => 'O servidor demorou para responder. Tente novamente.',
        'UNAUTHENTICATED' => 'Sua sessão expirou. Entre novamente.',
        'FORBIDDEN' => 'Você não tem permissão para realizar esta ação.',
        'WORKSPACE_NOT_FOUND' => 'O workspace solicitado não foi encontrado.',
        'VALIDATION_ERROR' => message,
        'NOT_FOUND' => 'O conteúdo solicitado não foi encontrado.',
        'CONFLICT' => message,
        'PLAN_LIMIT_REACHED' => 'O limite do seu plano foi atingido.',
        'RATE_LIMITED' => 'Muitas tentativas. Aguarde um instante e tente novamente.',
        'INTEGRATION_NOT_CONNECTED' => 'Conecte a integração antes de continuar.',
        'AI_PROVIDER_ERROR' => 'O agente de IA está temporariamente indisponível.',
        'EXTERNAL_PROVIDER_ERROR' => 'Um serviço externo não respondeu como esperado.',
        _ => 'Não foi possível concluir a operação. Tente novamente.',
      };

  factory ApiException.fromMap(
    Map<String, dynamic> map, {
    int? statusCode,
  }) {
    final rawDetails = map['details'];
    return ApiException(
      code: map['code']?.toString() ?? 'INTERNAL_ERROR',
      message: map['message']?.toString() ?? 'Erro interno',
      correlationId: map['correlationId']?.toString(),
      details: rawDetails is Map
          ? Map<String, dynamic>.from(rawDetails)
          : const <String, dynamic>{},
      statusCode: statusCode,
    );
  }

  factory ApiException.fromDio(DioException exception) {
    final responseData = exception.response?.data;
    if (responseData is Map) {
      final body = Map<String, dynamic>.from(responseData);
      final rawError = body['error'];
      if (rawError is Map) {
        return ApiException.fromMap(
          Map<String, dynamic>.from(rawError),
          statusCode: exception.response?.statusCode,
        );
      }
      if (body['code'] != null) {
        final parseCode = int.tryParse(body['code'].toString());
        return ApiException(
          code: switch (parseCode) {
            101 => 'INVALID_CREDENTIALS',
            202 || 203 => 'CONFLICT',
            209 => 'UNAUTHENTICATED',
            _ => _codeForStatus(exception.response?.statusCode),
          },
          message: rawError?.toString() ?? 'Falha na requisição',
          statusCode: exception.response?.statusCode,
        );
      }
      return ApiException(
        code: _codeForStatus(exception.response?.statusCode),
        message: rawError?.toString() ?? exception.message ?? 'Falha de comunicação',
        statusCode: exception.response?.statusCode,
      );
    }

    return ApiException(
      code: exception.type == DioExceptionType.connectionTimeout ||
              exception.type == DioExceptionType.receiveTimeout
          ? 'TIMEOUT'
          : 'NETWORK_ERROR',
      message: exception.message ?? 'Falha de comunicação',
      statusCode: exception.response?.statusCode,
    );
  }

  static String _codeForStatus(int? statusCode) => switch (statusCode) {
        401 => 'UNAUTHENTICATED',
        403 => 'FORBIDDEN',
        404 => 'NOT_FOUND',
        409 => 'CONFLICT',
        429 => 'RATE_LIMITED',
        _ => 'INTERNAL_ERROR',
      };

  @override
  String toString() => 'ApiException($code, $message, correlationId: $correlationId)';
}
