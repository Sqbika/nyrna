import 'package:flutter/material.dart';

import '../../logs/logs.dart';
import '../../styles.dart';
import '../preferences.dart';

class PreferencesPage extends StatelessWidget {
  static const id = 'preferences_page';

  const PreferencesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: Scrollbar(
        trackVisibility: true,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            vertical: 30,
            horizontal: 30,
          ),
          children: [
            const Donate(),
            Spacers.verticalLarge,
            const BehaviourSection(),
            Spacers.verticalMedium,
            const ThemeSection(),
            const IntegrationSection(),
            Spacers.verticalMedium,
            const Text('Troubleshooting'),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('Logs'),
              onTap: () => Navigator.pushNamed(context, LogPage.id),
            ),
            Spacers.verticalMedium,
            const AboutSection(),
          ],
        ),
      ),
    );
  }
}
