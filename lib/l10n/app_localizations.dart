import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @tabTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tabTasks;

  /// No description provided for @tabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tabCalendar;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'To-do'**
  String get tasksTitle;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" deleted'**
  String taskDeleted(Object title);

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" completed'**
  String taskCompleted(Object title);

  /// No description provided for @emptyTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get emptyTasksTitle;

  /// No description provided for @emptyTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first task'**
  String get emptyTasksHint;

  /// No description provided for @allDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'All done 🎉'**
  String get allDoneTitle;

  /// No description provided for @allDoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You finished 1 task today} other{You finished {count} tasks today}}'**
  String allDoneSubtitle(int count);

  /// No description provided for @todayProgress.
  ///
  /// In en, this message translates to:
  /// **'Today {done} / {total} done'**
  String todayProgress(int done, int total);

  /// No description provided for @todayProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s progress'**
  String get todayProgressLabel;

  /// No description provided for @doneOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} done'**
  String doneOfTotal(int done, int total);

  /// No description provided for @historyEmptyDay.
  ///
  /// In en, this message translates to:
  /// **'No tasks were on the list this day'**
  String get historyEmptyDay;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String dueToday(Object time);

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow {time}'**
  String dueTomorrow(Object time);

  /// No description provided for @dueYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String dueYesterday(Object time);

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue · {when}'**
  String overdue(Object when);

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityA11y.
  ///
  /// In en, this message translates to:
  /// **'{priority} priority'**
  String priorityA11y(Object priority);

  /// No description provided for @taskTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'What needs doing?'**
  String get taskTitleLabel;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pickDate;

  /// No description provided for @removeDate.
  ///
  /// In en, this message translates to:
  /// **'Remove date'**
  String get removeDate;

  /// No description provided for @taskReminderHint.
  ///
  /// In en, this message translates to:
  /// **'Reminders 1 day before, 1 hour before and at the due time.'**
  String get taskReminderHint;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get markDone;

  /// No description provided for @markNotDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as not done'**
  String get markNotDone;

  /// No description provided for @itemGone.
  ///
  /// In en, this message translates to:
  /// **'This item no longer exists (deleted).'**
  String get itemGone;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @newEntryTooltip.
  ///
  /// In en, this message translates to:
  /// **'New birthday / event'**
  String get newEntryTooltip;

  /// No description provided for @calendarEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet.\nTap + to add a birthday or event.'**
  String get calendarEmpty;

  /// No description provided for @dayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day.'**
  String get dayEmpty;

  /// No description provided for @turnsAge.
  ///
  /// In en, this message translates to:
  /// **'turns {age}'**
  String turnsAge(int age);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{in 1 day} other{in {count} days}}'**
  String inDays(int count);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @monthView.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthView;

  /// No description provided for @birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthday;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get newEntry;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be removed from the calendar.'**
  String deleteConfirmBody(Object title);

  /// No description provided for @birthdayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Whose birthday?'**
  String get birthdayNameLabel;

  /// No description provided for @eventNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Event name'**
  String get eventNameLabel;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get birthDate;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @unknownBirthYear.
  ///
  /// In en, this message translates to:
  /// **'I don\'t know the birth year'**
  String get unknownBirthYear;

  /// No description provided for @addTime.
  ///
  /// In en, this message translates to:
  /// **'Add a time'**
  String get addTime;

  /// No description provided for @repeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Repeat every year'**
  String get repeatYearly;

  /// No description provided for @repeatYearlyHint.
  ///
  /// In en, this message translates to:
  /// **'Like anniversaries'**
  String get repeatYearlyHint;

  /// No description provided for @eventReminderHint.
  ///
  /// In en, this message translates to:
  /// **'Reminders 3 days before and on the day at {time} (change it in Settings).'**
  String eventReminderHint(Object time);

  /// No description provided for @timedEventReminderHint.
  ///
  /// In en, this message translates to:
  /// **'Reminders 3 days before at {time} and 1 hour before it starts.'**
  String timedEventReminderHint(Object time);

  /// No description provided for @completedSection.
  ///
  /// In en, this message translates to:
  /// **'Completed tasks'**
  String get completedSection;

  /// No description provided for @strikeThrough.
  ///
  /// In en, this message translates to:
  /// **'Keep them, struck through'**
  String get strikeThrough;

  /// No description provided for @strikeThroughHint.
  ///
  /// In en, this message translates to:
  /// **'They stay on the list all day, so you see what you\'ve done.'**
  String get strikeThroughHint;

  /// No description provided for @hideCompleted.
  ///
  /// In en, this message translates to:
  /// **'Remove them from the list'**
  String get hideCompleted;

  /// No description provided for @hideCompletedHint.
  ///
  /// In en, this message translates to:
  /// **'They leave the list as soon as you tick them.'**
  String get hideCompletedHint;

  /// No description provided for @completedFooter.
  ///
  /// In en, this message translates to:
  /// **'The next day only unfinished tasks stay on the list. You can see past days in History.'**
  String get completedFooter;

  /// No description provided for @remindersSection.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersSection;

  /// No description provided for @reminderTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Birthday and event time'**
  String get reminderTimeTitle;

  /// No description provided for @reminderTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'3 days before and on the day, at this time'**
  String get reminderTimeSubtitle;

  /// No description provided for @reminderTimePicker.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTimePicker;

  /// No description provided for @remindersFooter.
  ///
  /// In en, this message translates to:
  /// **'Tasks are reminded 1 day before, 1 hour before and at the due time. Events with a time are reminded 1 hour before.'**
  String get remindersFooter;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Automatic (phone language)'**
  String get languageSystem;

  /// No description provided for @notifDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow {time}'**
  String notifDueTomorrow(Object time);

  /// No description provided for @notifOneHourLeft.
  ///
  /// In en, this message translates to:
  /// **'1 hour left · {time}'**
  String notifOneHourLeft(Object time);

  /// No description provided for @notifDueNow.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get notifDueNow;

  /// No description provided for @notifBirthdayIn3Days.
  ///
  /// In en, this message translates to:
  /// **'Birthday in 3 days'**
  String get notifBirthdayIn3Days;

  /// No description provided for @notifIn3Days.
  ///
  /// In en, this message translates to:
  /// **'In 3 days'**
  String get notifIn3Days;

  /// No description provided for @notifBirthdayToday.
  ///
  /// In en, this message translates to:
  /// **'Birthday today! 🎉'**
  String get notifBirthdayToday;

  /// No description provided for @notifInOneHour.
  ///
  /// In en, this message translates to:
  /// **'In 1 hour · {time}'**
  String notifInOneHour(Object time);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
