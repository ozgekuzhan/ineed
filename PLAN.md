# ineed — Yol Haritası

Kişisel kullanım için sade bir yapılacaklar uygulaması. İlk hedef: **iOS / App Store**.

## Özellikler (v1)

- Görev ekle / düzenle / sil / tamamla
- **Öncelik**: Yüksek · Orta · Düşük
- **Not**: her göreve serbest metin
- **Son tarih (deadline)**: "şu güne/saate kadar" + buna göre **bildirimler**
- **Ana ekran widget'ı**: listedeki öncelikli görevler telefon ekranında görünsün
- Sade arayüz, açık/koyu tema, Türkçe

## Teknik kararlar

| Konu | Seçim | Neden |
|---|---|---|
| Framework | Flutter (stable) | Tek kod tabanı, ileride Android da açık |
| Durum yönetimi | `ChangeNotifier` (ek paket yok) | Uygulama küçük, sade kalsın |
| Kalıcı veri | `shared_preferences` (JSON) | Kişisel liste için yeterli; gerekirse sonra SQLite/Drift |
| Bildirim | `flutter_local_notifications` + `timezone` | Sunucu gerekmez, cihazda planlanır. Saat dilimi: **Europe/Amsterdam** (cihazdan okunur) |
| Widget | `home_widget` + Swift **WidgetKit** extension | iOS widget'ları native SwiftUI ile yazılmak zorunda; veri App Group üzerinden paylaşılır |

## Ön koşullar (senin tarafında)

- **Mac + Xcode** (iOS derlemek ve App Store'a göndermek için şart; Linux/Windows'ta olmaz)
- **Apple Developer Program** üyeliği — yıllık 99 USD (Hollanda'da Apple faturada € olarak ~€99 civarı gösteriyor). Kayıt developer.apple.com/programs üzerinden; bireysel hesap için KvK kaydı gerekmez.
- iPhone'u kabloyla Mac'e bağlayıp test etmek (widget ve bildirimler simülatörde de çalışır ama gerçek cihazda denemek daha doğru)

## Çalışma şekli

Her özellik **tek tek** yapılır. Her özellik bittiğinde:
1. Bütün kod baştan gözden geçirilir (sadece yeni kısım değil)
2. Bulunan her sorun düzeltilir ve **o sorunu yakalayan bir test** eklenir
3. Testin gerçekten hatayı yakaladığı, düzeltme geçici olarak geri alınarak doğrulanır
4. `format` + `analyze` + `test` temiz geçmeden commit yapılmaz (CI da her push'ta kontrol eder)

## Gün gün plan

### Gün 1 — İskelet + temel liste ✅
- Flutter projesi (iOS + Android), bundle id `com.ozgekuzhan.ineed`
- `Task` modeli: başlık, not, öncelik, son tarih, tamamlandı
- Yerel kayıt (shared_preferences)
- Ana ekran: açık görevler (önceliğe sonra tarihe göre sıralı), tamamlananlar ayrı bölüm
- Görev ekleme/düzenleme ekranı (öncelik seçici, tarih+saat seçici, not)
- Kaydırarak silme, geri al (undo)
- Birim testleri

**Gün 1 kontrolü (yapıldı)** — bulunan ve düzeltilen sorunlar:
- Bozuk kayıt verisi uygulamanın açılmasını engelliyordu → okunamayan veri atlanıp yedekleniyor
- "Kaydet"e çift dokunma görevi iki kez ekliyordu → koruma eklendi
- 1 yıldan eski tarihli görevde tarih seçici çöküyordu → tarih aralığı düzeltildi
- Art arda kayıtlar sırasız bitip yeni veriyi eskisiyle ezebilirdi → kayıtlar sıraya alındı
- Tamamlama işareti eski görev kopyası üzerinden yapılıyordu → güncel kayıt kullanılıyor
- Öncelik noktası ekran okuyucuda (VoiceOver) okunmuyordu → etiket eklendi

### Gün 2 — Arayüz cilası
- ✅ Gecikmiş / bugün / yarın etiketleri ve renkleri (dakika dolunca ve uygulamaya dönünce kendiliğinden güncellenir)

  **Kontrol (yapıldı)** — bulunan ve düzeltilen sorunlar:
  - Yaz saati bitiş gecesi (Ekim'in son pazarı 02:00–03:00) zamanlayıcı −59 dk bekleme hesaplıyordu → bir saat boyunca boşa dönüp pil tüketirdi; bekleme artık saniyeden hesaplanıyor
  - Bozuk veri yedeği her açılışta tekrar ekleniyordu → okunabilir kısım hemen kaydediliyor
  - "Yarın" hesabı yaz saati günlerinde (23/25 saatlik günler) testle güvenceye alındı; CI testleri Amsterdam saat diliminde çalıştırıyor
- ✅ Ayarlar → Tamamlanan görevler: **Üstü çizili kalsın** (varsayılan) / **Listeden kalksın**
  - Üstü çizili modda görev yerinde kalır, üstte "Bugün 2 / 5 tamamlandı" ilerleme çubuğu
  - Listeden kalksın modunda "Geri al" mesajı çıkar
  - Ertesi gün liste yalnızca tamamlanmamış görevlerle başlar (gece yarısı kendiliğinden)

  **Kontrol (yapıldı)**:
  - İlerleme çubuğunun ekran okuyucu değeri geçersizdi; VoiceOver açıkken hataya yol açacaktı → düzeltildi
- ✅ Geçmiş (Görevler → saat ikonu): takvimden gün seç, listenin o günkü hali görünür; o gün tamamlananlar üstü çizili, "x / y tamamlandı", tamamlanan günlerde nokta. Salt okunur.
- ✅ **Takvim sekmesi**: doğum günleri ve etkinlikler
  - Aylık takvim (noktalı günler) + "Yaklaşanlar" listesi: "Bugün / Yarın / 3 gün sonra", "36 yaşına giriyor"
  - Güne dokununca o günün kayıtları; tekrar dokununca Yaklaşanlar'a döner
  - Doğum günü (yılı bilinmiyorsa yaş gösterilmez), etkinlik (saat opsiyonel, "her yıl tekrarla")
  - 29 Şubat doğumlular artık yıl olmayan yıllarda 28 Şubat'ta

  **Kontrol (yapıldı)** — bulunan ve düzeltilen sorunlar:
  - 2 yıldan uzak tek seferlik etkinlikler "Yaklaşanlar"da görünmüyordu
  - Takvim dikey kaydırmayı yutuyordu → parmak takvimin üstündeyken sayfa kaymıyordu (Geçmiş ekranında da)
  - Takvim + liste ekranı küçük telefonlarda listeye çok az yer bırakıyordu → tek parça kaydırılabilir
  - Yılı bilinmeyen doğum gününde "yılı biliyorum"a dönünce yer tutucu yıl (2000) gerçek yıl gibi kalıyordu
- Filtre: Tümü · Bugün · Yüksek öncelik
- Boş durum ekranı, açık/koyu tema ayarı
- Uygulama ikonu taslağı

### Gün 3 — Bildirimler
- `flutter_local_notifications` + `timezone` kurulumu, iOS izin isteği
- Her görev için hatırlatıcı seçimi: son tarihte · 1 saat önce · 1 gün önce
- Görev tamamlanınca/silinince bildirimin iptali, düzenlenince yeniden planlanması
- Sabah özeti (opsiyonel): her sabah 08:30'da "bugün X görevin var"

### Gün 4 — iOS Widget (1. kısım)
- Xcode'da Widget Extension hedefi, App Group (`group.com.ozgekuzhan.ineed`)
- `home_widget` ile Flutter → widget veri aktarımı (ilk 3–5 açık görev)
- Küçük ve orta boy widget, SwiftUI görünümü

### Gün 5 — Widget (2. kısım) + etkileşim
- Widget'tan dokununca ilgili göreve açılma (deep link)
- iOS 17+ etkileşimli widget: widget üzerinden görevi tamamla (opsiyonel)
- Veri her değiştiğinde widget'ın yenilenmesi

### Gün 6 — Sağlamlık
- Widget + bildirim + kayıt için testler
- Uç durumlar: geçmiş tarih, saat dilimi/yaz saati geçişi (Amsterdam: Mart ve Ekim sonu), çok uzun başlıklar
- Performans ve erişilebilirlik (Dynamic Type, VoiceOver etiketleri)

### Gün 7 — App Store hazırlığı
- Uygulama ikonu (1024×1024) ve açılış ekranı
- App Store Connect'te uygulama kaydı, gizlilik bilgisi ("veri toplanmıyor")
- Ekran görüntüleri (6.9" ve 6.5" iPhone)
- `flutter build ipa` → Xcode/Transporter ile yükleme → **TestFlight**

### Gün 8 — Yayın
- TestFlight'ta birkaç gün kendi kullanımın
- Düzeltmeler → App Store incelemesine gönderim

## Sonra (v2 fikirleri)
- iCloud senkronizasyonu (iPhone ↔ iPad)
- Tekrarlayan görevler (her pazartesi vb.)
- Etiketler / listeler
- Android sürümü ve Play Store
