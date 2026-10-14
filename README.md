# ineed

Sade, kişisel bir yapılacaklar uygulaması (Flutter, önce iOS).

Yol haritası ve gün gün plan: [PLAN.md](PLAN.md)

## Çalıştırma (Mac)

```sh
flutter pub get
flutter run          # simülatör veya bağlı iPhone
```

## Kontroller

Her adımdan sonra aynı üç kontrol çalıştırılır (CI'da da otomatik çalışır):

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
