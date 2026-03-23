Bir iOS oyunu geliştir.

Proje adı: NearbyWordsDuel

Amaç:
Backend kullanmadan çalışan, iPhone cihazlar arasında yakındaki oyuncularla oynanabilen, Wordle benzeri 1v1 kelime düello oyunu yap.

Zorunlu teknik kurallar:
- Dil: Swift
- UI: SwiftUI
- Mimari: MVVM
- Minimum iOS: 17+
- Backend kesinlikle olmayacak
- Firebase olmayacak
- REST API olmayacak
- Socket server olmayacak
- Login/register olmayacak
- Oyun tamamen local/peer-to-peer çalışacak
- Yakındaki cihaz iletişimi için MultipeerConnectivity kullan
- Kod production-grade, temiz, modüler ve okunabilir olsun
- View içinde iş mantığı yazma
- Oyun mantığını ayrı service/engine katmanında yaz
- MultipeerConnectivity kodunu ayrı service katmanında yaz
- Tüm modeller Codable uyumlu olsun
- Hardcoded static kelime listesi Swift dosyası içinde tutulmayacak

Kelime sistemi zorunluluğu:
- Kelimeler uygulama içinde Resources altında bulunan `kelimeler.txt` dosyasından okunacak
- Kelime verisi JSON dosyasından çekilecek
- Kelime listesi memory cache ile yönetilecek
- JSON parse işlemi için ayrı bir provider yaz
- Kelime doğrulama ve hedef kelime seçimi bu JSON verisi üstünden yapılacak
- Kelime verisini asla Swift array içine hardcode etme
- `kelimeler.txt` bulunamazsa veya bozuksa güvenli hata yönetimi yap



Uygulama özellikleri:
- Home ekranı
- Solo Practice modu
- Nearby Duel modu
- Stats ekranı
- Settings ekranı
- Result ekranı
- Host Game akışı
- Join Game akışı
- Rematch sistemi
- Local stats kayıt sistemi
- Karanlık, premium, Apple-style modern UI
- Haptic feedback
- Animasyonlu kutu flip / shake / success feedback

Oyun kuralları:
- Varsayılan hedef kelime uzunluğu 5
- Varsayılan tahmin hakkı 6
- İki oyuncu da aynı hedef kelimeyi çözmeye çalışacak
- Her tahminde harfler şu şekilde değerlendirilecek:
  - doğru harf doğru yerde = correct
  - doğru harf yanlış yerde = present
  - harf yok = absent
- Tekrarlı harfler doğru şekilde ele alınmalı
- İlk doğru bilen kazanır
- Aynı turda doğru bilirlerse süreye göre kazanan belirlenir
- İkisi de çözemezse performans kıyaslanır
- Gerekirse beraberlik olur

Yakındaki oyuncu sistemi:
- MultipeerConnectivity ile host ve guest mantığı kur
- Bir cihaz host olur, diğeri katılır
- Host oyun ayarlarını ve seed/kelime bilgisini paylaşır
- Guess, progress, game start, result, rematch gibi mesajları Codable JSON ile taşı
- Peer bağlantısı koparsa uygun hata durumu ve UI göster
- Geçersiz payload gelirse ignore et ve logla

Veri ve katman mimarisi:
Aşağıdaki klasör yapısını oluştur:

NearbyWordsDuel/
├── App/
│   ├── NearbyWordsDuelApp.swift
│   ├── AppRouter.swift
│   └── AppEnvironment.swift
│
├── Core/
│   ├── Constants/
│   ├── Extensions/
│   ├── Helpers/
│   └── Theme/
│
├── Domain/
│   ├── Models/
│   ├── Enums/
│   └── Protocols/
│
├── Data/
│   ├── Providers/
│   ├── Repositories/
│   └── Storage/
│
├── Services/
│   ├── Connectivity/
│   ├── Game/
│   └── Persistence/
│
├── Features/
│   ├── Home/
│   ├── NearbyLobby/
│   ├── Game/
│   ├── Result/
│   ├── Stats/
│   └── Settings/
│
└── Resources/
    └── kelimeler.txt

Zorunlu modeller:
- Player
- Room
- GameConfig
- GameSession
- Guess
- GuessEvaluation
- TileState
- GameResult
- LocalStats
- PeerMessage

Zorunlu servisler:
- WordJSONProvider
- WordRepository
- WordleGameEngine
- GuessEvaluator
- MultipeerSessionManager
- NearbyDiscoveryService
- StatsService
- SettingsService

Word JSON provider kuralları:
- `kelimeler.txt` Bundle içinden okunmalı
- JSON parse için ayrı model yap
- `targetWords` ve `validGuesses` ayrımı yap
- wordLength kontrolü yap
- Gerektiğinde rastgele hedef kelime seç
- Tahmin doğrulamasını validGuesses listesi ile yap
- Dosya okuma başarısız olursa fallback hata modeli döndür

UI/UX kuralları:
- Premium dark theme
- Apple-style sade tasarım
- Cam efekti kartlar olabilir
- Büyük okunaklı harf kutuları
- Özel klavye bileşeni
- Bağlantı durumu göstergesi
- Rakip ilerleme göstergesi
- Animasyonlar akıcı olsun
- Gereksiz kalabalık olmasın

Ayarlar:
- Oyuncu adı
- Ses açık/kapalı
- Haptic açık/kapalı
- Tema tercihi
- İstatistik sıfırlama

Yerel veri saklama:
- Basit ayarlar için UserDefaults
- İstatistik için SwiftData veya sade local storage katmanı
- Backend kullanılmayacak

Unit test yaz:
- GuessEvaluator testleri
- Tekrarlı harf testleri
- kelimeler.txt parse testleri
- Word validation testleri
- Game result hesaplama testleri

Teslim beklentisi:
- Çalışan SwiftUI proje iskeleti
- Tüm klasörlerin oluşturulması
- Temel ekranların yazılması
- Solo modun çalışması
- Nearby duel altyapısının kurulması
- kelimeler.txt’dan veri çekilmesi
- Mock değil gerçek local JSON kullanımı
- Kod düzenli, bölünmüş ve geliştirilebilir olsun

Ek kurallar:
- Tek dosyada aşırı büyük kod yazma
- Açıklama satırlarını gereksiz uzatma
- Kod doğrudan derlenebilir olmaya yakın olsun
- Preview destekleri ekle
- Gereken yerlerde mock preview verisi oluştur
- Ama gerçek veri kaynağı mutlaka `kelimeler.txt` olsun

İlerleme sırası:
1. Proje iskeletini kur
2. Theme sistemini oluştur
3. Domain modellerini yaz
4. `kelimeler.txt` okuma altyapısını kur
5. WordleGameEngine yaz
6. Solo Practice modunu çalıştır
7. MultipeerConnectivity altyapısını kur
8. Nearby Lobby ekranını yap
9. Game senkronizasyonunu bağla
10. Result, Stats, Settings ekranlarını tamamla
11. Testleri ekle
12. UI polish yap

Çıktıyı parça parça değil, düzenli dosya yapısına uygun şekilde üret.
Her dosyayı doğru klasöre koy.
Önce temel proje dosyalarını ve modelleri oluştur, sonra servisleri ve ekranları yaz.