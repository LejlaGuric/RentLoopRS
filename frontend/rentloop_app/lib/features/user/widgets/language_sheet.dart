import 'package:flutter/material.dart';

class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Odaberi jezik',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          ListTile(
            leading: const Text('🇧🇦', style: TextStyle(fontSize: 18)),
            title: const Text('Bosanski'),
            onTap: () {
              // TODO: ovdje ćeš kasnije pozvati tvoj localization change
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Jezik: Bosanski')),
              );
            },
          ),
          ListTile(
            leading: const Text('🇬🇧', style: TextStyle(fontSize: 18)),
            title: const Text('English'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language: English')),
              );
            },
          ),
        ],
      ),
    );
  }
}
