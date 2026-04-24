import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vulnscan/config/constants/app_constants.dart';
import 'package:vulnscan/data/datasources/api_datasource.dart';
import 'package:vulnscan/data/models/subscription_model.dart';
import 'package:vulnscan/services/http_client_service.dart';

/// Provider to get the API datasource
final apiDatasourceProvider = Provider((ref) {
  final httpClient = HttpClientService();
  return ApiDatasource(dio: httpClient.dio);
});

/// Notifier for subscription state with Hive caching
class SubscriptionNotifier
    extends StateNotifier<AsyncValue<SubscriptionInfo?>> {
  final ApiDatasource _api;

  SubscriptionNotifier(this._api) : super(const AsyncValue.loading()) {
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      // Check cache first
      final cached = await _getFromCache();
      if (cached != null && !_isCacheExpired(cached)) {
        state = AsyncValue.data(cached);
        // Refresh in background
        _refreshInBackground();
        return;
      }

      // Fetch from API
      final subscription = await _api.getUserSubscription();
      await _saveToCache(subscription);
      state = AsyncValue.data(subscription);
    } catch (_) {
      // On error, try to get cached data or use default free subscription
      final cached = await _getFromCache();
      if (cached != null) {
        state = AsyncValue.data(cached);
      } else {
        // Fallback to default free subscription when backend is unavailable
        state = AsyncValue.data(SubscriptionInfo.defaultFree());
      }
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final subscription = await _api.getUserSubscription();
      await _saveToCache(subscription);
      state = AsyncValue.data(subscription);
    } catch (_) {
      // Silently fail on background refresh
    }
  }

  Future<SubscriptionInfo?> _getFromCache() async {
    try {
      final box = await Hive.openBox<Map>(
        AppConstants.storageKeySubscriptionTier,
      );
      final cached = box.get('subscription');
      if (cached != null) {
        return SubscriptionInfo.fromJson(Map<String, dynamic>.from(cached));
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveToCache(SubscriptionInfo subscription) async {
    try {
      final box = await Hive.openBox<Map>(
        AppConstants.storageKeySubscriptionTier,
      );
      await box.put('subscription', subscription.toJson() as Map);
    } catch (_) {}
  }

  bool _isCacheExpired(SubscriptionInfo cached) {
    final now = DateTime.now();
    final elapsed = now.difference(cached.cachedAt);
    return elapsed > AppConstants.subscriptionCacheDuration;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadSubscription();
  }
}

/// Provider for subscription info
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<SubscriptionInfo?>>((
      ref,
    ) {
      final api = ref.watch(apiDatasourceProvider);
      return SubscriptionNotifier(api);
    });

/// Derived provider to check if user can create scan
final canCreateScanProvider = Provider<bool>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.maybeWhen(
    data: (sub) => sub?.canCreateScan ?? false,
    orElse: () => false,
  );
});

/// Derived provider for scan quota info
final quotaInfoProvider = Provider<({int used, int limit})?>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.maybeWhen(
    data: (sub) =>
        sub != null ? (used: sub.scansUsed, limit: sub.scansLimit) : null,
    orElse: () => null,
  );
});
