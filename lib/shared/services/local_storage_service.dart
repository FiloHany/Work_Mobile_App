import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

final localStorageServiceProvider = Provider<LocalStorageService>(
  (_) => LocalStorageService._(),
);

class LocalStorageService {
  LocalStorageService._();

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── SharedPreferences (non-sensitive) ────────────────────────────────────

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await _prefs;
    return prefs.getBool(key) ?? defaultValue;
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  Future<void> setString(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  Future<void> remove(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }

  // ── Convenience getters ───────────────────────────────────────────────────

  Future<bool> get isOnboardingComplete =>
      getBool(AppConstants.keyOnboardingComplete);

  Future<void> setOnboardingComplete() =>
      setBool(AppConstants.keyOnboardingComplete, true);

  // ── FlutterSecureStorage (sensitive) ──────────────────────────────────────

  Future<String?> getSecure(String key) => _secure.read(key: key);

  Future<void> setSecure(String key, String value) =>
      _secure.write(key: key, value: value);

  Future<void> deleteSecure(String key) => _secure.delete(key: key);

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
    await _secure.deleteAll();
  }
}
