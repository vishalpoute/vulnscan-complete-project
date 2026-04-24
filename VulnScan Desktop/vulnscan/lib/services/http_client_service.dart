import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vulnscan/config/constants/app_constants.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Dio HTTP Client with interceptors for auth, error handling, and retries
class HttpClientService {
  late final Dio dio;
  final Logger _logger = Logger();
  late SharedPreferences _prefs;

  HttpClientService() {
    _initDio();
  }

  void _initDio() {
    // Get base URL with safe fallback for web platform where .env is not loaded
    String baseUrl = AppConstants.baseApiUrl;

    try {
      if (!kIsWeb) {
        final envUrl = dotenv.env['API_BASE_URL'];
        if (envUrl != null && envUrl.isNotEmpty) {
          baseUrl = envUrl;
        }
      }
    } catch (e) {
      // .env not loaded — using default API base URL from AppConstants
      _logger.d('No .env file found. Using default API_BASE_URL: $baseUrl');
    }

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AppConstants.networkTimeout,
        receiveTimeout: AppConstants.networkTimeout,
        sendTimeout: AppConstants.networkTimeout,
        contentType: 'application/json',
      ),
    );

    // Add interceptors
    dio.interceptors.addAll([
      _AuthInterceptor(this),
      _ErrorInterceptor(_logger),
      _LoggingInterceptor(_logger),
    ]);
  }

  Future<void> setAuthToken(String token) async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.setString(AppConstants.storageKeyAuthToken, token);
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<String?> getAuthToken() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getString(AppConstants.storageKeyAuthToken);
  }

  Future<void> clearAuthToken() async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.remove(AppConstants.storageKeyAuthToken);
    dio.options.headers.remove('Authorization');
  }

  Future<Map<String, dynamic>> checkBackendHealth() async {
    try {
      final response = await dio.get(
        '/health',
        options: Options(extra: {'skipAuth': true}),
      );

      return {
        'status': response.statusCode == 200 ? 'healthy' : 'unhealthy',
        'message': response.data['message'] ?? 'Backend is online',
        'timestamp': DateTime.now().toIso8601String(),
        'statusCode': response.statusCode,
        'data': response.data,
      };
    } catch (e) {
      _logger.e('Backend health check failed: $e');
      return {
        'status': 'unhealthy',
        'message': 'Failed to connect to backend: ${e.toString()}',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }
}

/// Interceptor for handling authentication tokens
class _AuthInterceptor extends Interceptor {
  final HttpClientService _httpClient;

  _AuthInterceptor(this._httpClient);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _httpClient.getAuthToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Interceptor for handling errors
class _ErrorInterceptor extends Interceptor {
  final Logger _logger;

  _ErrorInterceptor(this._logger);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    _logger.e(
      'DIO Error: ${err.message}',
      error: err,
      stackTrace: err.stackTrace,
    );

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      _logger.e('Network timeout');
    }

    handler.next(err);
  }
}

/// Interceptor for logging requests and responses
class _LoggingInterceptor extends Interceptor {
  final Logger _logger;

  _LoggingInterceptor(this._logger);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    _logger.d(
      'REQUEST: ${options.method} ${options.path}',
      error: options.queryParameters,
    );
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    _logger.d(
      'RESPONSE: ${response.statusCode} ${response.requestOptions.path}',
    );
    handler.next(response);
  }
}
