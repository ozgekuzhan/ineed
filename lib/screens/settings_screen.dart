import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
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
      helpText: context.l10n.reminderTimePicker,
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

  Widget _footnote(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
    child: Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          children: [
            _sectionTitle(theme, l10n.languageSection),
            RadioGroup<AppLanguage>(
              groupValue: settings.language,
              onChanged: (value) {
                if (value != null) settings.setLanguage(value);
              },
              child: Column(
                children: [
                  RadioListTile(
                    value: AppLanguage.system,
                    title: Text(l10n.languageSystem),
                  ),
                  // Language names are shown in their own language.
                  const RadioListTile(
                    value: AppLanguage.tr,
                    title: Text('Türkçe'),
                  ),
                  const RadioListTile(
                    value: AppLanguage.en,
                    title: Text('English'),
                  ),
                ],
              ),
            ),
            const Divider(),
            _sectionTitle(theme, l10n.completedSection),
            RadioGroup<CompletedBehavior>(
              groupValue: settings.completedBehavior,
              onChanged: (value) {
                if (value != null) settings.setCompletedBehavior(value);
              },
              child: Column(
                children: [
                  RadioListTile(
                    value: CompletedBehavior.strikeThrough,
                    title: Text(l10n.strikeThrough),
                    subtitle: Text(l10n.strikeThroughHint),
                  ),
                  RadioListTile(
                    value: CompletedBehavior.hide,
                    title: Text(l10n.hideCompleted),
                    subtitle: Text(l10n.hideCompletedHint),
                  ),
                ],
              ),
            ),
            _footnote(theme, l10n.completedFooter),
            const Divider(),
            _sectionTitle(theme, l10n.remindersSection),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(l10n.reminderTimeTitle),
              subtitle: Text(l10n.reminderTimeSubtitle),
              trailing: Text(
                formatClockTime(settings.reminderTime),
                style: theme.textTheme.titleMedium,
              ),
              onTap: () => _pickReminderTime(context),
            ),
            _footnote(theme, l10n.remindersFooter),
          ],
        ),
      ),
    );
  }
}
