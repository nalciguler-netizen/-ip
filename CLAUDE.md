# Sanal Çip (HDL) – Proje Kuralları

Hedef: bina modelleme geometri işlemleri (B-Rep, AABB, NURBS) için sanal çip. Öğrenme + üretim hattı (OpenLane/GDSII) projesi.
Uygulamanın asıl geometri motoru yazılımdır (ayrı sohbet); bu proje onunla paralel gider.

## Evreler
1. Vektör çekirdeği (float64 add/mul, dot, cross, mat4) – kod yazıldı, ilk Actions testi bekleniyor
2. Uzamsal indeksleyici (AABB çakışma blokları)
3. Eğri birimi (NURBS / De Boor hattı)

## Kurallar
- Sayı formatı: IEEE-754 float64.
- Ticari kullanım: yalnızca kendi kodumuz veya ticari kullanıma uygun açık lisanslar (BSD/MIT/Apache); araçlar ücretsiz.
- Telefon tek cihaz: dosyalar GitHub'a yüklenir, testler GitHub Actions'ta çalışır.
- Teslimat: tek paket, test edilmiş; güncellemede yalnızca değişen dosyalar.
- Bu projenin dosyaları yalnızca bu sohbette; diğer uygulamaların dosyaları karıştırılmaz.
