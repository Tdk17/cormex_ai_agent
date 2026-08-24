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
    try {
      final headers = <String, dynamic>{
        'X-Parse-Application-Id': AppConfig.parseApplicationId,
        if (AppConfig.parseRestApiKey.isNotEmpty)
          'X-Parse-REST-API-Key': AppConfig.parseRestApiKey,
        if (requiresAuth && _sessionStorage.sessionToken != null)
          'X-Parse-Session-Token': _sessionStorage.sessionToken,
      };

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
