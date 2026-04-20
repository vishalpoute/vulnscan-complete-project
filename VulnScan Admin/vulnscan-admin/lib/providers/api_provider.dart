import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

const String API_BASE_URL = 'http://localhost:8000';

// Dio client for HTTP requests
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: API_BASE_URL,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  
  // Add auth interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await ref.watch(authTokenProvider.future);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ),
  );
  
  return dio;
});

// Fetch all users
final usersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/admin/users');
    final users = List<Map<String, dynamic>>.from(response.data);
    return users;
  } catch (e) {
    throw 'Failed to fetch users: $e';
  }
});

// Fetch all scans
final scansProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/admin/scans');
    final scans = List<Map<String, dynamic>>.from(response.data);
    return scans;
  } catch (e) {
    throw 'Failed to fetch scans: $e';
  }
});

// Fetch analytics
final analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/admin/analytics');
    return response.data as Map<String, dynamic>;
  } catch (e) {
    throw 'Failed to fetch analytics: $e';
  }
});

// Fetch feedback
final feedbackProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/feedback');
    final feedback = List<Map<String, dynamic>>.from(response.data);
    return feedback;
  } catch (e) {
    throw 'Failed to fetch feedback: $e';
  }
});

// Delete user
final deleteUserProvider = FutureProvider.family<void, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  try {
    await dio.delete('/admin/users/$userId');
    ref.invalidate(usersProvider);
  } catch (e) {
    throw 'Failed to delete user: $e';
  }
});
