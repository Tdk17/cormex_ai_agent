import 'api_exception.dart';

sealed class ApiResult<T> {
  const ApiResult();

  R fold<R>({
    required R Function(T data, ApiMeta meta) onSuccess,
    required R Function(ApiException error) onFailure,
  }) {
    return switch (this) {
      ApiSuccess<T>(:final data, :final meta) => onSuccess(data, meta),
      ApiFailure<T>(:final error) => onFailure(error),
    };
  }
}

class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data, {this.meta = const ApiMeta()});

  final T data;
  final ApiMeta meta;
}

class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.error);

  final ApiException error;
}

class ApiMeta {
  const ApiMeta({this.correlationId, this.nextCursor});

  final String? correlationId;
  final String? nextCursor;

  factory ApiMeta.fromMap(Map<String, dynamic>? map) {
    return ApiMeta(
      correlationId: map?['correlationId']?.toString(),
      nextCursor: map?['nextCursor']?.toString(),
    );
  }
}
