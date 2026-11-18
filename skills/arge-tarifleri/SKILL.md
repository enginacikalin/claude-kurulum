---
name: arge-tarifleri
description: Kullanıcının Ar-Ge ve laboratuvar işleri için hazır tarifler. Mikrodalga soğurucu ve EM kaplama, polimer kompozit formülasyonu, ölçüm ve veri analizi, numune tutucu tasarımı, simülasyon. Deney tasarımı (DoE) ya da "en az deneyle" plan istendiğinde; ölçüm belirsizliği veya hata bütçesi istendiğinde; kalınlık, dolgu oranı ve bant genişliği optimizasyonu ya da Pareto analizi istendiğinde; VNA numune tutucusu, dalga kılavuzu adaptörü veya 3B baskı fikstürü tasarımı istendiğinde; RL, ε ve μ verisi işleme, grafik, istatistik veya simülasyon doğrulaması istendiğinde kullan. Hangi uzman skill'in çağrılacağını ve alana özgü girdileri belirler.
---

# Ar-Ge tarifleri (yönlendirici)

Bu skill bir **yönlendiricidir**. İsteği tanı, aşağıdaki tariften ilgili uzman skill'i yükle (Skill aracı), alana özgü varsayılanları ona ver. Uzman skill kurulu değilse aynı adımları kendin uygula ve kurulmadığını belirt.

Genel kurallar:
- Sayıları ve ölçüm verisini kullanıcıdan al; **asla uydurma**. Eksikse `[VERİ GEREKLİ: …]` yaz.
- Birimleri her adımda taşı (GHz, mm, ağ.%, dB).
- Olgu, varsayım ve tahmini ayır. Sonuç makaleye gidecekse `makale-ilkeleri` geçerlidir.
- Hesap gerekiyorsa Python ile yap, betiği göster, sonucu yeniden üretilebilir bırak.

## Tarif 1: Deney tasarımı (DoE) — `experimental-design`
**Tetikleyici:** "En az deneyle…", "hangi faktörler önemli", formülasyon planı.

- **Tipik faktörler:**
  - dolgu türü (kategorik: ferrit, CNT, PANI, MXene…)
  - dolgu oranı (ağ.%)
  - kalınlık (mm)
  - matris (epoksi, PU, silikon)
  - dağıtma yöntemi ve süresi (ultrasonik, üç merdane)
  - kür koşulu
- **Tipik yanıtlar:**
  - RLmin (dB) ve frekansı
  - etkin soğurma bandı (EAB, RL < −10 dB) ve hangi kalınlıkta
  - ε′, ε″, μ′, μ″ (bant ortalaması)
  - yoğunluk ya da ağırlık
  - yapışma ve mekanik özellik
- **Önerilen akış:**
  1. Eleme: kesirli faktöriyel ya da Plackett–Burman.
  2. Optimizasyon: Box–Behnken ya da merkez kompozit tasarım.
  3. Her parti ve gün için **bloklama**; ölçüm sırası **rastgele**. VNA kalibrasyon kayması bir kaynak.
- **Uyarılar:**
  - Tekrar sayısını ve **sahte tekrarı** ayır: aynı numunenin tekrar ölçümü yeni bir numune değildir.
  - Örneklem büyüklüğü için `statistical-analysis` (güç analizi).

## Tarif 2: Ölçüm belirsizliği bütçesi — `uncertainty-and-units`
**Tetikleyici:** "Belirsizliği hesapla", "hata bütçesi", "± kaç dB".

- **Kaynaklar (GUM):**
  - **A tipi:** tekrar ölçüm saçılımı.
  - **B tipi:**
    - VNA kalibrasyon belirsizliği (üretici spesifikasyonu)
    - numune kalınlığının ölçümü (mikrometre çözünürlüğü)
    - numune geometrisi ve **hava boşluğu**: koaksiyel toroidde iç/dış çap boşluğu ε'yi düşük gösterir; düzeltme modeli belirtilmeli
    - frekans çözünürlüğü
    - sıcaklık
    - ε çıkarım yöntemi (NRW, NIST iteratif); yarım dalga boyu civarında NRW tekilliği
- **Çıktılar:**
  - bileşen tablosu
  - birleşik standart belirsizlik
  - genişletilmiş belirsizlik (k = 2)
  - **RL'ye yayılım:** Monte Carlo ile, ε ve μ belirsizliğinden ve kalınlıktan RL(f) bandı.
- RL hesaplanmışsa (metal destekli iletim hattı modeli) bunu açıkça yaz.

## Tarif 3: Kalınlık, dolgu ve bant genişliği optimizasyonu — `pymoo` (+ `parameter-optimization`)
**Tetikleyici:** "Pareto", "en ince ve en geniş bant", "optimum kalınlık".

- **Model:** metal destekli tek katman.
  - Zin = Z0 √(μr/εr) tanh[j(2πfd/c)√(μr εr)]
  - RL = 20 log10 |(Zin − Z0)/(Zin + Z0)|
- **Girdi:** Ölçülmüş ε(f), μ(f) tabloları, her dolgu oranı için. Ara oranlar için interpolasyon yapılacaksa bunu varsayım olarak belirt.
- **Amaçlar (genelde iki ya da üç):**
  - EAB'yi enbüyüt (RL < −10 dB)
  - kalınlık d'yi enküçült
  - isteğe bağlı: alan yoğunluğunu ya da maliyeti enküçült
  - **kısıt:** hedef bant (örneğin X bandı 8,2–12,4 GHz) içinde RL ≤ −10 dB
- **Algoritma:** NSGA-II. Pareto cephesini çiz, seçilen 2–3 tasarımı RL(f) eğrileriyle göster.
- **Kontrol:** Çeyrek dalga koşulu d ≈ λ/(4√|εr μr|), |Zin/Z0| grafiği. Sonucu Rozanov sınırına göre konumlandırmayı öner; formülü kaynaktan doğrula.
- **Çok katmanlı tasarım:** Katman sayısı ve sıralamasını değişken olarak ekle; iletim hattı matrisiyle hesapla.

## Tarif 4: Numune tutucu ve fikstür CAD — `lab-hardware-cad`
**Tetikleyici:** "Tutucu tasarla", "adaptör", "3B baskı", "STL/STEP".

- **Bilinen standart ölçüler** (tasarım öncesi kullanıcının kendi cihazından teyit et):
  - **7 mm koaksiyel hava hattı (APC-7) toroid numune:** dış çap ≈ 7,00 mm, iç çap ≈ 3,04 mm. Literatürde yaygın; örneğin Luo 2016'da OD 7 / ID 3,04 mm.
  - **X bandı dikdörtgen dalga kılavuzu WR-90:** iç ölçü 22,86 × 10,16 mm. Ku bandı WR-62: 15,80 × 7,90 mm.
- **Tipik parçalar:**
  - toroid pres kalıbı ya da kılavuzu
  - dalga kılavuzu numune çerçevesi (kalınlık ayarlı)
  - serbest uzay ölçümü için numune tutucu (köpük ya da düşük ε'li malzeme)
  - kaplama ya da film uygulama şablonu
- **Malzeme notu:** 3B baskı malzemesi (PLA, PETG, reçine) ölçüm bölgesine giriyorsa ε'sini ve kaybını dikkate al; mümkünse ölçüm alanının dışında tut.
- **Çıktı:** parametrik model; STEP, STL, DXF; toleranslar ve baskı ayarları.

## Tarif 5: Veri işleme ve şekiller — `scientific-visualization`, `matplotlib`, `statistical-analysis`
- **Standart şekiller:**
  - ε′, ε″ – f ve μ′, μ″ – f
  - tan δε, tan δμ
  - RL – f (birden çok kalınlık)
  - 2B RL haritası (f × d)
  - |Zin/Z0| ve α (zayıflatma sabiti)
  - Cole–Cole grafiği (yorumda aşırıya kaçma; bkz. literatür wiki'si)
- **Dergi standardı:** vektör çıktı (PDF ya da SVG), renk körlüğüne uygun palet, birimler eksen başlığında, belirsizlik bantları.
- **Karşılaştırma tablosu:** malzeme, ölçüm matrisi, dolgu oranı, kalınlık, RLmin, EAB ve RL'nin ölçülmüş mü hesaplanmış mı olduğu (literatür wiki'sindeki `tablolar/performans.csv` biçimi).

## Tarif 6: Simülasyon doğrulama — `convergence-study`, `simulation-validator`, `numerical-stability`, `post-processing`
- **Ağ yakınsaması:** GCI, ASME V&V 20 standardına göre.
- **Zaman adımı kararlılığı:** FDTD için CFL koşulu.
- **Ölçümle karşılaştırma:** simüle edilen RL'yi ölçülen panelle karşılaştır.
- Malzeme modeli (Debye ya da Lorentz uydurması) **nedensellik** (Kramers–Kronig) açısından tutarlı olmalı.

## Tarif 7: Kristal yapı ve faz — `pymatgen`
Ferritler (spinel, hegzaferrit) için yapı dosyası okuma, simetri, kafes parametresi ve XRD deseni simülasyonu. Bu sonuçları ölçülen XRD ile karşılaştırma için kullan; tek başına kanıt sayma.

## Örnek istekler
- "Dolgu oranı, kalınlık ve iki dolgu türü için en az deneyle bir deney tasarımı çıkar."
- "RL ölçümümün belirsizlik bütçesini hesapla."
- "Kalınlık ve bant genişliği için Pareto optimizasyonu yap."
- "VNA numune tutucusu için 3B baskıya uygun parça tasarla."
