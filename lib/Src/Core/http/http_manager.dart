import 'dart:typed_data';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/auth/session_storage.dart';
import 'package:agente_vendas_saas/Src/Core/config/app_config.dart';
import 'package:dio/dio.dart';

import 'endpoints.dart';
import 'http_method.dart';

class HttpManager {
  HttpManager({required SessionStorage sessionStorage, Dio? dio})
      : _sessionStorage = sessionStorage,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.parseServerUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 30),
                contentType: Headers.jsonContentType,
                responseType: ResponseType.json,
              ),
            );

  final SessionStorage _sessionStorage;
  final Dio _dio;

  Future<ApiResult<Map<String, dynamic>>> restRequest({
    required String endpoint,
    required HttpMethod method,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    final sessionToken = _sessionStorage.sessionToken;
    if (requiresAuth && (sessionToken == null || sessionToken.isEmpty)) {
      return const ApiFailure<Map<String, dynamic>>(
        ApiException(
          code: 'UNAUTHENTICATED',
          message: 'A operação exige uma sessão válida.',
        ),
      );
    }
    try {
      final headers = _parseHeaders(
        sessionToken: sessionToken,
        requiresAuth: requiresAuth,
      );

      final response = await _dio.request<dynamic>(
        endpoint,
        data: body,
        queryParameters: queryParameters,
        options: Options(method: method.name.toUpperCase(), headers: headers),
      );

      return _normalizeResponse(response.data);
    } on DioException catch (error) {
      return ApiFailure<Map<String, dynamic>>(ApiException.fromDio(error));
    } on Object catch (error) {
      return ApiFailure<Map<String, dynamic>>(
        ApiException(code: 'INTERNAL_ERROR', message: error.toString()),
      );
    }
  }

  Future<ApiResult<Map<String, dynamic>>> uploadParseFile({
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final sessionToken = _sessionStorage.sessionToken;
    if (sessionToken == null || sessionToken.isEmpty) {
      return const ApiFailure<Map<String, dynamic>>(
        ApiException(
          code: 'UNAUTHENTICATED',
          message: 'A operação exige uma sessão válida.',
        ),
      );
    }

    try {
      final safeName = _safeFileName(fileName);
      final response = await _dio.post<dynamic>(
        '/files/${Uri.encodeComponent(safeName)}',
        data: bytes,
        options: Options(
          headers: _parseHeaders(
            sessionToken: sessionToken,
            requiresAuth: true,
          ),
          contentType: contentType,
          responseType: ResponseType.json,
        ),
        onSendProgress: onSendProgress,
      );
      return _normalizeResponse(response.data);
    } on DioException catch (error) {
      return ApiFailure<Map<String, dynamic>>(ApiException.fromDio(error));
    } on Object catch (error) {
      return ApiFailure<Map<String, dynamic>>(
        ApiException(code: 'INTERNAL_ERROR', message: error.toString()),
      );
    }
  }

  Future<ApiResult<Map<String, dynamic>>> cloudFunction({
    required String name,
    Map<String, dynamic> parameters = const <String, dynamic>{},
  }) {
    return restRequest(
      endpoint: Endpoints.cloudFunction(name),
      method: HttpMethod.post,
      body: parameters,
    );
  }

  Map<String, dynamic> _parseHeaders({
    required String? sessionToken,
    required bool requiresAuth,
  }) {
    return <String, dynamic>{
      'X-Parse-Application-Id': AppConfig.parseApplicationId,
      if (AppConfig.parseRestApiKey.isNotEmpty)
        'X-Parse-REST-API-Key': AppConfig.parseRestApiKey,
      if (requiresAuth && sessionToken != null)
        'X-Parse-Session-Token': sessionToken,
    };
  }

  static String _safeFileName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (normalized.isEmpty) return 'campaign-media';
    return normalized.length <= 120 ? normalized : normalized.substring(normalized.length - 120);
  }

  ApiResult<Map<String, dynamic>> _normalizeResponse(dynamic raw) {
    if (raw is! Map) {
      return ApiSuccess<Map<String, dynamic>>(<String, dynamic>{'value': raw});
    }

    var body = Map<String, dynamic>.from(raw);
    if (body['result'] is Map) {
      body = Map<String, dynamic>.from(body['result'] as Map);
    }

    if (body['ok'] == false && body['error'] is Map) {
      return ApiFailure<Map<String, dynamic>>(
        ApiException.fromMap(Map<String, dynamic>.from(body['error'] as Map)),
      );
    }

    if (body['code'] != null || body['error'] != null) {
      final parseCode = int.tryParse(body['code']?.toString() ?? '');
      return ApiFailure<Map<String, dynamic>>(
        ApiException(
          code: switch (parseCode) {
            101 => 'INVALID_CREDENTIALS',
            141 => 'INVALID_FUNCTION',
            202 || 203 => 'CONFLICT',
            209 => 'UNAUTHENTICATED',
            _ => 'INTERNAL_ERROR',
          },
          message: body['error']?.toString() ?? 'Falha na requisição.',
        ),
      );
    }

    if (body['ok'] == true) {
      final data = body['data'];
      final normalizedData = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{'value': data};
      return ApiSuccess<Map<String, dynamic>>(
        normalizedData,
        meta: ApiMeta.fromMap(
          body['meta'] is Map
              ? Map<String, dynamic>.from(body['meta'] as Map)
              : null,
        ),
      );
    }

    return ApiSuccess<Map<String, dynamic>>(body);
  }
}
