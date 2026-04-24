import 'package:dio/dio.dart';
import 'package:vulnscan/data/models/subscription_model.dart';
import 'package:vulnscan/data/models/scan_model.dart';
import 'package:vulnscan/data/models/scan_progress_model.dart';
import 'package:vulnscan/data/models/vulnerability_model.dart';
import 'package:vulnscan/domain/failures.dart';

class ApiDatasource {
  final Dio dio;

  ApiDatasource({required this.dio});

  /// Get user subscription info
  Future<SubscriptionInfo> getUserSubscription() async {
    try {
      final response = await dio.get('/api/user/subscription');
      return SubscriptionInfo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get user's scan history
  Future<List<Scan>> getUserScans({int limit = 50, int offset = 0}) async {
    try {
      final response = await dio.get(
        '/api/scans',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      return (response.data as List).map((e) => Scan.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Create a new scan
  Future<Scan> createScan({required String repositoryUrl, required String scanType}) async {
    try {
      final response = await dio.post(
        '/api/scans',
        data: {'url_or_repo': repositoryUrl, 'scan_type': scanType},
      );
      return Scan.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get scan status/progress
  Future<Scan> getScanProgress(String scanId) async {
    try {
      final response = await dio.get('/api/scans/$scanId');
      return Scan.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get detailed scan progress with tool breakdown
  Future<ScanProgress> getScanProgressDetailed(String scanId) async {
    try {
      final response = await dio.get('/api/scans/$scanId/status');
      return ScanProgress.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Cancel a running scan
  Future<void> cancelScan(String scanId) async {
    try {
      await dio.delete('/api/scans/$scanId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get full scan report with vulnerabilities
  Future<ScanReport> getReport(String scanId) async {
    try {
      final response = await dio.get('/api/scans/$scanId/report');
      return ScanReport.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      await dio.delete('/api/user/account');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Initiate payment for subscription upgrade
  Future<Map<String, dynamic>> createPaymentOrder({required String planId}) async {
    try {
      final response = await dio.post(
        '/api/payments/create-order',
        data: {'plan_id': planId},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Verify payment success
  Future<void> verifyPayment({required String orderId, required String paymentId, required String signature}) async {
    try {
      await dio.post(
        '/api/payments/verify',
        data: {'order_id': orderId, 'payment_id': paymentId, 'signature': signature},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkFailure(message: 'Connection timeout. Please check your internet.');
    }

    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      return AuthFailure(message: 'Unauthorized. Please login again.');
    }

    if (e.response?.statusCode == 429) {
      return SubscriptionFailure(message: 'Rate limited. Please try again later.');
    }

    if (e.response?.statusCode == 402) {
      return SubscriptionFailure(message: 'Subscription limit exceeded.');
    }

    return ServerFailure(
      message: e.response?.statusMessage ?? 'Server error occurred',
      statusCode: e.response?.statusCode,
    );
  }
}
