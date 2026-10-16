import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../models/dates.dart';
import '../models/event.dart';
import '../models/task.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// The app language chosen in settings.
enum AppLanguage {
  /// Follows the phone's language (English if it's neither Turkish nor
  /// English).
  system,
  tr,
  en,
}

/// The locale the app shows for [language], given the phone's preferred
/// [deviceLocales] (most preferred first).
Locale resolveLocale(AppLanguage language, List<Locale> deviceLocales) =>
    switch (language) {
      AppLanguage.tr => const Locale('tr'),
      AppLanguage.en => const Locale('en'),
      AppLanguage.system => Locale(
        deviceLocales
            .map((l) => l.languageCode)
            .firstWhere((c) => c == 'tr' || c == 'en', orElse: () => 'en'),
      ),
    };

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Date and time texts in the app's language. Turkish puts the day first
/// ("14 Eki Çar"); English uses "Wed 14 Oct" (UK/European order).
class DateTexts {
  DateTexts(this.locale);

  /// e.g. "tr" or "en", as in [AppLocalizations.localeName].
  final String locale;

  bool get _tr => locale.startsWith('tr');

  String _f(String pattern, DateTime d) =>
      DateFormat(pattern, locale).format(d);

  /// "18:00".
  String time(DateTime d) => _f('HH:mm', d);

  /// "14 Eki Çar" / "Wed 14 Oct"; with [withYear] "3 Oca 2027" / "3 Jan 2027".
  String short(DateTime d, {bool withYear = false}) =>
      withYear ? _f('d MMM y', d) : _f(_tr ? 'd MMM EEE' : 'EEE d MMM', d);

  /// "14 Ekim 2026, Çarşamba" / "Wednesday 14 October 2026".
  String long(DateTime d) => _f(_tr ? 'd MMMM y, EEEE' : 'EEEE d MMMM y', d);

  /// "14 Ekim 2026, Çarşamba 18:00" / "Wednesday 14 October 2026, 18:00".
  String longWithTime(DateTime d) =>
      _f(_tr ? 'd MMMM y, EEEE HH:mm' : 'EEEE d MMMM y, HH:mm', d);

  /// "17 Ekim Cumartesi" / "Saturday 17 October".
  String dayMonthWeekday(DateTime d) =>
      _f(_tr ? 'd MMMM EEEE' : 'EEEE d MMMM', d);

  /// "17 Ekim" / "17 October".
  String dayMonth(DateTime d) => _f('d MMMM', d);

  /// "17 Ekim 1962" / "17 October 1962".
  String dayMonthYear(DateTime d) => _f('d MMMM y', d);
}

extension PriorityText on AppLocalizations {
  String priorityLabel(Priority p) => switch (p) {
    Priority.high => priorityHigh,
    Priority.medium => priorityMedium,
    Priority.low => priorityLow,
  };

  String eventKindLabel(EventKind k) => switch (k) {
    EventKind.birthday => birthday,
    EventKind.event => event,
  };

  DateTexts get dates => DateTexts(localeName);

  /// Short text for a due date relative to [now]: "Bugün 18:00" /
  /// "Today 18:00", "Yarın 09:00", "Dün 14:30", otherwise the date
  /// ("17 Eki Cmt 18:00", or with the year if it's another year).
  ///
  /// With [relative] false the date is always written out, for views of a
  /// past day where "Bugün" would be read as the real today.
  String dueText(DateTime due, DateTime now, {bool relative = true}) {
    final time = dates.time(due);
    if (relative) {
      switch (daysBetween(now, due)) {
        case 0:
          return dueToday(time);
        case 1:
          return dueTomorrow(time);
        case -1:
          return dueYesterday(time);
      }
    }
    return '${dates.short(due, withYear: due.year != now.year)} $time';
  }
}
