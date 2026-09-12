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
        'FORBIDDEN' || 'PERMISSION_DENIED' || 'UNAUTHORIZED' =>
          'Você não tem permissão para realizar esta ação.',
        'WORKSPACE_NOT_FOUND' => 'A empresa selecionada não foi encontrada.',
        'VALIDATION_ERROR' => message,
        'NOT_FOUND' => 'O conteúdo solicitado não foi encontrado.',
        'CONFLICT' => message,
        'PLAN_LIMIT_REACHED' => 'O limite do seu plano foi atingido.',
        'RATE_LIMITED' => 'Muitas tentativas. Aguarde um instante e tente novamente.',
        'INTEGRATION_NOT_CONNECTED' =>
          'Conecte a integração antes de continuar.',
        'CHANNEL_NOT_CONNECTED' =>
          'Conecte o canal antes de iniciar ou enviar mensagens.',
        'ADS_ACCOUNT_NOT_CONNECTED' =>
          'Conecte sua conta de anúncios antes de publicar.',
        'AUTHORIZATION_ERROR' =>
          'A autorização da conta de anúncios expirou. Reconecte a conta.',
        'PUBLICATION_ERROR' =>
          'O provedor não conseguiu publicar a campanha. Tente novamente.',
        'PAYMENT_ISSUE' =>
          'Revise a forma de pagamento da conta de anúncios.',
        'GOOGLE_OAUTH_ERROR' =>
          'Não foi possível iniciar a autorização do Google. Tente novamente.',
        'GOOGLE_ADS_NOT_CONFIGURED' =>
          'A integração com Google Ads ainda não está configurada no ambiente atual.',
        'GOOGLE_OAUTH_NETWORK_ERROR' =>
          'Não foi possível comunicar com o Google. Tente novamente.',
        'GOOGLE_OAUTH_STATE_INVALID' ||
        'GOOGLE_OAUTH_STATE_EXPIRED' ||
        'GOOGLE_OAUTH_STATE_USED' =>
          'A sessão de autorização do Google não é mais válida. Inicie a conexão novamente.',
        'GOOGLE_OAUTH_CODE_MISSING' =>
          'O Google não retornou a autorização esperada. Inicie a conexão novamente.',
        'GOOGLE_OAUTH_CODE_EXCHANGE_FAILED' ||
        'GOOGLE_REFRESH_TOKEN_MISSING' =>
          'Não foi possível concluir a autorização do Google. Reconecte a conta.',
        'GOOGLE_ADS_ACCOUNT_NOT_FOUND' =>
          'A conta de anúncios selecionada não foi encontrada.',
        'GOOGLE_ADS_ACCOUNT_NOT_ACCESSIBLE' ||
        'GOOGLE_ADS_PERMISSION_ERROR' =>
          'A conta Google atual não possui acesso suficiente para esta operação.',
        'GOOGLE_ADS_AUTHORIZATION_ERROR' =>
          'A autorização do Google Ads expirou ou foi revogada. Reconecte a conta.',
        'GOOGLE_ADS_DEVELOPER_TOKEN_ERROR' ||
        'GOOGLE_ADS_API_ERROR' =>
          'O Google Ads não conseguiu concluir a operação. Tente novamente mais tarde.',
        'GOOGLE_ADS_PUBLICATION_ERROR' =>
          'O Google Ads não conseguiu publicar a campanha. Revise a conta e tente novamente.',
        'INVALID_FUNCTION' =>
          'Este recurso ainda não está disponível no ambiente atual.',
        'AI_PROVIDER_ERROR' =>
          'O agente de IA está temporariamente indisponível. Tente novamente.',
        'AI_NOT_CONFIGURED' =>
          'O agente de IA ainda não está configurado no ambiente atual.',
        'AI_INVALID_RESPONSE' =>
          'A IA respondeu em um formato inválido. Tente novamente.',
        'EXTERNAL_PROVIDER_ERROR' => 'Um serviço externo não respondeu como esperado.',
        _ => message.trim().isEmpty || code == 'INTERNAL_ERROR'
            ? 'Não foi possível concluir a operação. Tente novamente.'
            : message,
      };

  factory ApiException.fromMap(
    Map<String, dynamic> map, {
    int? statusCode,
  }) {
    final rawDetails = map['details'];
    return ApiException(
      code: (map['code']?.toString() ?? 'INTERNAL_ERROR').toUpperCase(),
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
            141 => 'INVALID_FUNCTION',
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
