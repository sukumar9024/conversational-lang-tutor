import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../services/env_service.dart';
import '../constants/app_constants.dart';

class DioClient {
  static Dio create(EnvService envService) {
    final dio = Dio(
      BaseOptions(
        baseUrl: envService.openRouterBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
        sendTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (envService.isDebug) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          request: true,
          error: true,
          maxWidth: 90,
        ),
      );
    }

    return dio;
  }
}
