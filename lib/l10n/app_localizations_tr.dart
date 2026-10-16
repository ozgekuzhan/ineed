// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get tabTasks => 'Görevler';

  @override
  String get tabCalendar => 'Takvim';

  @override
  String get tasksTitle => 'Yapılacaklar';

  @override
  String get history => 'Geçmiş';

  @override
  String get settings => 'Ayarlar';

  @override
  String get newTask => 'Yeni görev';

  @override
  String get editTask => 'Görevi düzenle';

  @override
  String get save => 'Kaydet';

  @override
  String get undo => 'Geri al';

  @override
  String taskDeleted(Object title) {
    return '\"$title\" silindi';
  }

  @override
  String taskCompleted(Object title) {
    return '\"$title\" tamamlandı';
  }

  @override
  String get emptyTasksTitle => 'Henüz görev yok';

  @override
  String get emptyTasksHint => '+ ile ilk görevini ekle';

  @override
  String get allDoneTitle => 'Hepsi tamam 🎉';

  @override
  String allDoneSubtitle(int count) {
    return 'Bugün $count görev tamamladın';
  }

  @override
  String todayProgress(int done, int total) {
    return 'Bugün $done / $total tamamlandı';
  }

  @override
  String get todayProgressLabel => 'Bugünkü ilerleme';

  @override
  String doneOfTotal(int done, int total) {
    return '$done / $total tamamlandı';
  }

  @override
  String get historyEmptyDay => 'Bu gün listede görev yoktu';

  @override
  String dueToday(Object time) {
    return 'Bugün $time';
  }

  @override
  String dueTomorrow(Object time) {
    return 'Yarın $time';
  }

  @override
  String dueYesterday(Object time) {
    return 'Dün $time';
  }

  @override
  String overdue(Object when) {
    return 'Gecikti · $when';
  }

  @override
  String get priorityHigh => 'Yüksek';

  @override
  String get priorityMedium => 'Orta';

  @override
  String get priorityLow => 'Düşük';

  @override
  String priorityA11y(Object priority) {
    return '$priority öncelik';
  }

  @override
  String get taskTitleLabel => 'Ne yapılacak?';

  @override
  String get priority => 'Öncelik';

  @override
  String get dueDate => 'Son tarih';

  @override
  String get pickDate => 'Tarih seç';

  @override
  String get removeDate => 'Tarihi kaldır';

  @override
  String get taskReminderHint =>
      '1 gün önce, 1 saat önce ve son tarihte hatırlatılır.';

  @override
  String get note => 'Not';

  @override
  String get markDone => 'Tamamlandı olarak işaretle';

  @override
  String get markNotDone => 'Tamamlanmadı olarak işaretle';

  @override
  String get itemGone => 'Bu kayıt artık yok (silinmiş).';

  @override
  String get upcoming => 'Yaklaşanlar';

  @override
  String get newEntryTooltip => 'Yeni doğum günü / etkinlik';

  @override
  String get calendarEmpty =>
      'Henüz kayıt yok.\n+ ile doğum günü veya etkinlik ekle.';

  @override
  String get dayEmpty => 'Bu günde kayıt yok.';

  @override
  String turnsAge(int age) {
    return '$age yaşına giriyor';
  }

  @override
  String daysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String inDays(int count) {
    return '$count gün sonra';
  }

  @override
  String get today => 'Bugün';

  @override
  String get tomorrow => 'Yarın';

  @override
  String get monthView => 'Ay';

  @override
  String get birthday => 'Doğum günü';

  @override
  String get event => 'Etkinlik';

  @override
  String get newEntry => 'Yeni kayıt';

  @override
  String get edit => 'Düzenle';

  @override
  String get delete => 'Sil';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get deleteConfirmTitle => 'Silinsin mi?';

  @override
  String deleteConfirmBody(Object title) {
    return '\"$title\" takvimden silinecek.';
  }

  @override
  String get birthdayNameLabel => 'Kimin doğum günü?';

  @override
  String get eventNameLabel => 'Etkinlik adı';

  @override
  String get birthDate => 'Doğum tarihi';

  @override
  String get date => 'Tarih';

  @override
  String get unknownBirthYear => 'Doğum yılını bilmiyorum';

  @override
  String get addTime => 'Saat ekle';

  @override
  String get repeatYearly => 'Her yıl tekrarla';

  @override
  String get repeatYearlyHint => 'Yıldönümleri gibi';

  @override
  String eventReminderHint(Object time) {
    return '3 gün önce ve gününde saat $time hatırlatılır (Ayarlar\'dan değiştirilebilir).';
  }

  @override
  String timedEventReminderHint(Object time) {
    return '3 gün önce saat $time ve başlamadan 1 saat önce hatırlatılır.';
  }

  @override
  String get completedSection => 'Tamamlanan görevler';

  @override
  String get strikeThrough => 'Üstü çizili kalsın';

  @override
  String get strikeThroughHint =>
      'Gün boyunca listede görünür; neler yaptığını görürsün.';

  @override
  String get hideCompleted => 'Listeden kalksın';

  @override
  String get hideCompletedHint => 'İşaretlediğin anda listeden çıkar.';

  @override
  String get completedFooter =>
      'Ertesi gün yalnızca tamamlanmamış görevler listede kalır. Geçmiş günlerin listesini takvimden görebilirsin.';

  @override
  String get remindersSection => 'Hatırlatmalar';

  @override
  String get reminderTimeTitle => 'Doğum günü ve etkinlik saati';

  @override
  String get reminderTimeSubtitle => '3 gün önce ve gününde bu saatte';

  @override
  String get reminderTimePicker => 'Hatırlatma saati';

  @override
  String get remindersFooter =>
      'Görevler son tarihten 1 gün önce, 1 saat önce ve son tarihte hatırlatılır. Saati belli etkinlikler 1 saat önce hatırlatılır.';

  @override
  String get languageSection => 'Dil';

  @override
  String get languageSystem => 'Otomatik (telefonun dili)';

  @override
  String notifDueTomorrow(Object time) {
    return 'Son tarih yarın $time';
  }

  @override
  String notifOneHourLeft(Object time) {
    return '1 saat kaldı · $time';
  }

  @override
  String get notifDueNow => 'Son tarih şimdi';

  @override
  String get notifBirthdayIn3Days => 'Doğum günü 3 gün sonra';

  @override
  String get notifIn3Days => '3 gün sonra';

  @override
  String get notifBirthdayToday => 'Bugün doğum günü! 🎉';

  @override
  String notifInOneHour(Object time) {
    return '1 saat sonra · $time';
  }
}
