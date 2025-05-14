import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Getters
  bool? getBool(String key) => _prefs?.getBool(key);
  int? getInt(String key) => _prefs?.getInt(key);
  double? getDouble(String key) => _prefs?.getDouble(key);
  String? getString(String key) => _prefs?.getString(key);
  List<String>? getStringList(String key) => _prefs?.getStringList(key);

  // Setters
  Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }

  // Remove
  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  // Clear all
  Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  // Common settings
  String get units => getString('units') ?? 'imperial';
  String get mapType => getString('map_type') ?? 'normal';
  bool get hapticFeedback => getBool('haptic_feedback') ?? true;
  bool get soundEffects => getBool('sound_effects') ?? false;
  bool get autoStart => getBool('auto_start') ?? false;
  bool get showSpeedLimit => getBool('show_speed_limit') ?? true;
  int get autoPauseDuration => getInt('auto_pause_duration') ?? 300;

  // Theme
  String get themeMode => getString('theme_mode') ?? 'system';

  // First run
  bool get isFirstRun => getBool('is_first_run') ?? true;
  Future<void> setFirstRunComplete() async {
    await setBool('is_first_run', false);
  }
}
