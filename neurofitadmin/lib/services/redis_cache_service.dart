/// Redis Cache Bypass - Direct Database Sync Mode
class RedisCacheService {
  static final RedisCacheService _instance = RedisCacheService._internal();
  factory RedisCacheService() => _instance;
  RedisCacheService._internal();

  /// Direct Database Mode: No caching delays, always fetch fresh data from Firestore
  Future<String?> get(String key) async => null;

  /// Store value: No-op in direct DB mode
  Future<bool> set(String key, String value, {int ttlSeconds = 0}) async => true;

  /// Invalidate: No-op
  Future<void> invalidate(String keyPattern) async {}
}
