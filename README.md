# Sanal Çip – Evre 1: Vektör Çekirdeği (float64)

Ticari kullanıma uygun, kendi yazdığımız Verilog; dış lisans bağımlılığı yok.

## İçerik
- `rtl/fp64_add.v`, `rtl/fp64_mul.v` – IEEE-754 double toplama/çarpma (RNE yuvarlama)
- `rtl/vec_mat.v` – 3D nokta çarpımı, çapraz çarpım, 4x4 matris çarpanı
- `tb/` – testbench'ler; `sim/gen_vectors.py` beklenen sonuçları Python'un IEEE-754 float64'ünden üretir
- `model/fp64_model.py` – aynı algoritmanın Python modeli (200.000 rastgele deneme geçti)
- `.github/workflows/sim.yml` – GitHub'a yükleyince testleri otomatik çalıştırır

## Test etme
GitHub'a yükle → Actions sekmesi → "Simulasyon". Yeşil tik = tüm testler geçti.
Bilgisayarda: `bash sim/run_all.sh` (Icarus Verilog gerekir).

## Bilinen sınırlar (bilerek)
- Alt-normal (denormal) girdi ve sonuçlar sıfıra yuvarlanır (flush-to-zero). Mimari ölçeklerde fark etmez.
- NaN her zaman kanonik sessiz NaN'a çevrilir.
- Birimler kombinasyonel (boru hattı yok). Boru hattı sentez aşamasında eklenecek.
- FMA yok; dot4 sırası ((p0+p1)+p2)+p3.

## Durum
Verilog kodu henüz gerçek bir simülatörde çalıştırılmadı (geliştirme ortamında simülatör kurulamadı).
Algoritma Python modeliyle doğrulandı. İlk gerçek Verilog testi GitHub Actions'ta yapılacak.
