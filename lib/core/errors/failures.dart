import 'package:dio/dio.dart';

abstract class Failure {
  final String message;
  final StackTrace? stackTrace;

  Failure(this.message, [this.stackTrace]);

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  NetworkFailure(super.message, [super.stackTrace]);

  factory NetworkFailure.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure('Connection timeout. Please try again.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return NetworkFailure(_handleStatusCode(statusCode));
      case DioExceptionType.cancel:
        return NetworkFailure('Request cancelled');
      case DioExceptionType.unknown:
      default:
        return NetworkFailure('Network error occurred');
    }
  }

  static String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized. Please check your API key.';
      case 403:
        return 'Access forbidden';
      case 404:
        return 'Resource not found';
      case 429:
        return 'Rate limit exceeded. Please wait.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Request failed with status: $statusCode';
    }
  }
}

class PermissionFailure extends Failure {
  PermissionFailure(super.message) : super();
}

class VoiceServiceFailure extends Failure {
  VoiceServiceFailure(super.message) : super();
}

class CacheFailure extends Failure {
  CacheFailure(super.message) : super();
}
