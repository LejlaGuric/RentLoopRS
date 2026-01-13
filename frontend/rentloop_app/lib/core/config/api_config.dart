import 'dart:io';

class ApiConfig {
  static const _desktopBase = 'https://localhost:7004';
  static const _androidEmulatorBase = 'http://10.0.2.2:5068';

  static String get baseUrl {
    if (Platform.isAndroid) {
      return _androidEmulatorBase; // ✅ HTTP za emulator
    }
    return _desktopBase; // ✅ HTTPS za desktop
  }
}
