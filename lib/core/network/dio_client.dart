import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../app/injection.dart';
import '../constants/app_constants.dart';

@module
abstract class DioClient {
  @singleton
  Dio provideDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
        sendTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

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

    return dio;
  }
}