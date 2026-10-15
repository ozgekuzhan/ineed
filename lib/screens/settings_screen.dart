import 'package:flutter/material.dart';

import '../state/settings_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Tamamlanan görevler',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            RadioGroup<CompletedBehavior>(
              groupValue: settings.completedBehavior,
              onChanged: (value) {
                if (value != null) settings.setCompletedBehavior(value);
              },
              child: const Column(
                children: [
                  RadioListTile(
                    value: CompletedBehavior.strikeThrough,
                    title: Text('Üstü çizili kalsın'),
                    subtitle: Text(
                      'Gün boyunca listede görünür; neler yaptığını görürsün.',
                    ),
                  ),
                  RadioListTile(
                    value: CompletedBehavior.hide,
                    title: Text('Listeden kalksın'),
                    subtitle: Text('İşaretlediğin anda listeden çıkar.'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                'Ertesi gün yalnızca tamamlanmamış görevler listede kalır. '
                'Geçmiş günlerin listesini takvimden görebilirsin.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
