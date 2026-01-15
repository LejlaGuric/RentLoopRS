import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  Locale _locale = const Locale('bs'); // default (može i null/sistem)

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void toggle() {
    if (_locale.languageCode == 'bs') {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('bs'));
    }
  }
}
