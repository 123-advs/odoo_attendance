import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageService extends GetxService {
  final GetStorage _box = GetStorage();
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  static const _kSessionId = 'odoo_session_id';
  static const _kUserId = 'odoo_user_id';
  static const _kOnboardingSeen = 'onboarding_seen';

  bool get onboardingSeen => _box.read<bool>(_kOnboardingSeen) ?? false;
  Future<void> setOnboardingSeen() => _box.write(_kOnboardingSeen, true);

  int? get userId => _box.read<int>(_kUserId);
  Future<void> setUserId(int id) => _box.write(_kUserId, id);

  Future<String?> readSessionId() => _secure.read(key: _kSessionId);
  Future<void> writeSessionId(String value) =>
      _secure.write(key: _kSessionId, value: value);
  Future<void> clearSession() async {
    await _secure.delete(key: _kSessionId);
    await _box.remove(_kUserId);
  }
}
