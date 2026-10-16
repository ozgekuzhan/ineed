import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter/widgets.dart';
import 'package:ineed/l10n/l10n.dart';
import 'package:ineed/models/due_label.dart';

void main() {
  final tr = lookupAppLocalizations(const Locale('tr'));
  setUpAll(() => initializeDateFormatting('tr'));

  // Wednesday 14 October 2026, 15:00.
  final now = DateTime(2026, 10, 14, 15);

  group('dueStatus', () {
    test('past time is overdue, even a minute ago', () {
      expect(dueStatus(DateTime(2026, 10, 14, 14, 59), now), DueStatus.overdue);
    });

    test('exactly now is not overdue yet', () {
      expect(dueStatus(now, now), DueStatus.today);
    });

    test('later today, tomorrow and beyond', () {
      expect(dueStatus(DateTime(2026, 10, 14, 23, 59), now), DueStatus.today);
      expect(dueStatus(DateTime(2026, 10, 15, 0, 0), now), DueStatus.tomorrow);
      expect(
        dueStatus(DateTime(2026, 10, 15, 23, 59), now),
        DueStatus.tomorrow,
      );
      expect(dueStatus(DateTime(2026, 10, 16), now), DueStatus.later);
    });

    test('month and year boundaries', () {
      expect(
        dueStatus(DateTime(2026, 11, 1, 9), DateTime(2026, 10, 31, 20)),
        DueStatus.tomorrow,
      );
      expect(
        dueStatus(DateTime(2027, 1, 1, 9), DateTime(2026, 12, 31, 20)),
        DueStatus.tomorrow,
      );
    });

    // These matter when the suite runs with TZ=Europe/Amsterdam (as CI
    // does): the days of the clock change are 23 and 25 hours long.
    test('tomorrow across the spring clock change (29 Mar 2026)', () {
      expect(
        dueStatus(DateTime(2026, 3, 29, 10), DateTime(2026, 3, 28, 23, 30)),
        DueStatus.tomorrow,
      );
    });

    test('tomorrow across the autumn clock change (25 Oct 2026)', () {
      expect(
        dueStatus(DateTime(2026, 10, 26, 9), DateTime(2026, 10, 25, 0, 30)),
        DueStatus.tomorrow,
      );
    });
  });

  group('untilNextMinute', () {
    test('waits for the rest of the current minute', () {
      expect(
        untilNextMinute(DateTime(2026, 10, 14, 17, 59, 30)),
        const Duration(seconds: 30),
      );
      expect(
        untilNextMinute(DateTime(2026, 10, 14, 18)),
        const Duration(minutes: 1),
      );
    });

    // With TZ=Europe/Amsterdam this is 02:30 in the hour that repeats
    // when the clocks go back; building "02:31" as a local time there
    // picks the earlier 02:31 and gave a delay of minus 59 minutes.
    test('stays positive in the repeated hour (25 Oct 2026)', () {
      final now = DateTime.utc(2026, 10, 25, 1, 30, 15).toLocal();
      expect(untilNextMinute(now), const Duration(seconds: 45));
    });
  });

  group('dueText', () {
    test('relative day names', () {
      expect(tr.dueText(DateTime(2026, 10, 14, 18), now), 'Bugün 18:00');
      expect(tr.dueText(DateTime(2026, 10, 15, 9, 5), now), 'Yarın 09:05');
      expect(tr.dueText(DateTime(2026, 10, 13, 14, 30), now), 'Dün 14:30');
    });

    test('non-relative always writes the date', () {
      expect(
        tr.dueText(DateTime(2026, 10, 14, 18), now, relative: false),
        '14 Eki Çar 18:00',
      );
    });

    test('same year shows weekday, other years show the year', () {
      expect(tr.dueText(DateTime(2026, 10, 17, 18), now), '17 Eki Cmt 18:00');
      expect(tr.dueText(DateTime(2027, 1, 3, 9), now), '3 Oca 2027 09:00');
    });
  });
}
