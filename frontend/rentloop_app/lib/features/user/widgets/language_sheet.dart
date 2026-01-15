import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../main.dart'; // ili tačna putanja do main.dart (pazi na relative)


cclass LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.language, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),

            ListTile(
              title: const Text('Bosanski'),
              trailing: localeController.locale.languageCode == 'bs'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                localeController.setLocale(const Locale('bs'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              trailing: localeController.locale.languageCode == 'en'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                localeController.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

