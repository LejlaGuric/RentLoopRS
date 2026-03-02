import 'dart:io';

class ApiConfig {
  // 🔹 Sada i desktop i Android koriste isti PORT 5068
  static const _desktopBase = 'http://localhost:5068';
  static const _androidEmulatorBase = 'http://10.0.2.2:5068';

  static String get baseUrl {
    if (Platform.isAndroid) {
      return _androidEmulatorBase; 
    }
    return _desktopBase; 
  }
}