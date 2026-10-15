import 'package:flutter/material.dart';

import '../models/dates.dart';
import '../state/settings_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final SettingsStore settings;

  Future<void> _pickReminderTime(BuildContext context) async {
    final current = settings.reminderTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Hatırlatma saati',
    );
    if (picked != null) {
      await settings.setReminderTime((
        hour: picked.hour,
        minute: picked.minute,
      ));
    }
  }

  Widget _sectionTitle(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          children: [
            _sectionTitle(theme, 'Tamamlanan görevler'),
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
            const Divider(),
            _sectionTitle(theme, 'Hatırlatmalar'),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Doğum günü ve etkinlik saati'),
              subtitle: const Text('3 gün önce ve gününde bu saatte'),
              trailing: Text(
                formatClockTime(settings.reminderTime),
                style: theme.textTheme.titleMedium,
              ),
              onTap: () => _pickReminderTime(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                'Görevler son tarihten 1 gün önce, 1 saat önce ve son tarihte '
                'hatırlatılır. Saati belli etkinlikler 1 saat önce hatırlatılır.',
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
