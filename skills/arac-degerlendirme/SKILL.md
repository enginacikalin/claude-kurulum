---
name: arac-degerlendirme
description: Kullanıcı "şunu yapan bir skill/eklenti/araç var mı", "bunun için bir skill bul" dediğinde ya da bir ihtiyaç için araç aradığında (keşif); ayrıca bir GitHub deposunu, Claude eklentisini, skill'i, MCP sunucusunu, CLI aracını veya yapay zekâ ajanını KURMADAN ÖNCE değerlendir. Kullanıcı bir github.com bağlantısı ya da araç adı paylaştığında; "bunu kuralım mı", "buna bakalım", "işime yarar mı", "güvenli mi", "tehlikeli mi" dediğinde; ya da akademik yazım veya makale üretim aracı söz konusu olduğunda kullan. Güvenlik, gizlilik, telif ve kullanım koşulları, akademik etik, maliyet, bakım durumu, mevcut araçlarla çakışma ve alan uygunluğunu kontrol eder; kanıta dayalı bir karar ve gerekiyorsa güvenli kurulum yolu önerir.
---

# Araç değerlendirme

Amaç: Kullanıcı (malzeme bilimi akademisyeni; TÜBİTAK projeleri, Q1 yayın, ÜAK/YÖK süreçleri, bireysel yatırım) bir aracı kurmadan önce **kanıta dayalı, eleştirel** bir karar alsın. Popülerlik (yıldız sayısı) kalite ya da güven göstergesi değildir; yıldızlar şişirilebilir.

## 0. Keşif: ihtiyaca göre araç/skill bulma

Kullanıcı bir ihtiyaç için skill ya da araç arıyorsa, önce şu sırayla ara ve **hiçbirini kurma**:

1. **Hesabın kataloğu:** `SearchPlugins` (Anthropic dizini, yayıncı katmanı ve içerik taraması bilgisiyle gelir).
2. **Anthropic resmî kaynakları:** anthropics/skills ve claude-plugins-official.
3. **Web araması** ve topluluk dizinleri (skills.sh sıralaması, awesome listeleri). Yıldız ve kurulum sayısı **kalite ya da güven göstergesi değildir**; şişirilebilir. Yalnızca "ne kadar yaygın" bilgisi olarak kullan.

Bulunan adaylar için kullanıcıya şunları sun: ne yaptığı, kaynağı ve yayıncısı, son güncelleme, lisans, ücretli hesap gerektirip gerektirmediği. Sonra bu skill'in **Adım 1–4** sürecini uygula.

**Yasak:** `npx skills add`, `npx skills find` ile bulunan sonucu otomatik kurma, `-y`/`--yes` ile onaysız kurma ve "bul ve kur" tek adımlı kurucular. Bu araçlar incelemeyi atlar. Kullanıcı bir skill'i adıyla isterse bile önce depoyu **indirip incele** (kanca, ağ, telemetri, betikler), sonra sabit SHA ile kopyala.

## 1. İncele (kodu asla çalıştırma)

Depoyu scratchpad'de **yeni, boş bir klasöre** sığ olarak klonla. İçindeki hiçbir betiği, kurulumu ya da testi çalıştırma. Python ile okuman gerekirse `python3 -I` kullan.

```bash
git clone -q --depth 50 https://github.com/SAHIP/DEPO <scratchpad>/inceleme/DEPO
```

Şunları topla ve **kendi gözünle doğrula**; README'nin iddiasını olgu gibi aktarma:

| Kontrol | Nasıl |
|---|---|
| Etkinlik | `git log -1` (son), `git rev-list --count HEAD`, ilk kayıt tarihi, yazar dağılımı |
| Lisans | `LICENSE` ilk satırları; yoksa "lisans yok" de |
| Tür | `.claude-plugin/marketplace.json` / `plugin.json`, `SKILL.md` sayısı, `.mcp.json`, CLI ya da bağımsız ajan |
| **Kancalar** | `hooks*.json`; her `command` satırını oku. SessionStart, PreToolUse, PostToolUse ve Stop'ta ne çalışıyor? |
| Ağ | Koddaki `https://` alan adları; veriler nereye gidiyor? |
| Telemetri | `telemetry`, `posthog`, `analytics` ara. **Varsayılan açık mı?** Nasıl kapatılıyor? |
| Kurulum yöntemi | `curl … \| sh`, `irm … \| iex` = okunmadan çalışan uzak betik → işaretle |
| Gereksinimler | Ücretli API anahtarı mı (OpenAI, Gemini…)? Hesap zorunlu mu? Kripto ödeme? |
| Saldırı yüzeyi | Gerçek tarayıcı veya oturumlar, kabuk erişimi, sürekli açık daemon, Telegram/Slack köprüsü, kişisel hesaplara erişim |
| Bağımlılıklar | Sürümler sabit mi? Alt paketlerin kendisi de inceleme gerektirir mi? |

## 2. Kullanıcıya göre değerlendir

- **Çakışma:** Mevcut kurulumla örtüşüyor mu? `ls ~/.claude/skills`, `claude plugin list` ve `claude mcp list` ile bak. İş akışı çerçeveleri (superpowers, gstack, ECC…) birbiriyle çelişir; birden fazlasını kurma.
- **Bağlam maliyeti:** Skill açıklamaları her oturumda token harcar. Çok sayıda skill içeren paketlerde yaklaşık maliyeti hesapla.
- **Alan uygunluğu:** Yazılımcıya yönelik bir araç akademik işe katkı sağlamayabilir; açıkça söyle.
- **Telif ve kullanım koşulları:** Yayıncı sitelerini (Elsevier, Springer, Wiley, IEEE, Scopus, WoS, ResearchGate, Google Scholar), standartları ve korsan siteleri kazıma ya da bot engeli aşma yoksa bile riskli. Abonelikli içerik için API öner (OpenAlex, Crossref, Europe PMC, Clarivate). Kişisel veri toplanacaksa KVKK'yı hatırlat.
- **Akademik etik** (yazım ve makale araçları):
  - Makaleyi baştan sona otomatik yazan araçları **önerme**. Yayıncı yapay zekâ politikalarına göre yapay zekâ kullanımı beyan edilmeli, yapay zekâ yazar olamaz ve sorumluluk yazardadır. Bu tür araçlar ÜAK/YÖK etik incelemesinde ve doçentlik dosyasında risk oluşturur.
  - Otomatik literatür taraması uydurma atıf üretebilir; her DOI'yi Crossref veya OpenAlex ile doğrulamadan kullanma.
  - "Yapay zekâ dedektörünü atlatma" amaçlı araçlara yardım etme. Beyan edilmiş yardım (yapılandırma, eleştiri, dil, kaynak doğrulama) uygundur.
- **Finans araçları:** Veri kaynağının lisansını kontrol et; resmî olmayan kazıma ticari kullanıma uygun değildir. Veri gecikmesini, para birimi etiket hatalarını ve emir gönderme yetkisini kontrol et. Yatırım tavsiyesi verme.
- **Gizlilik:** Yayımlanmamış makaleler, TÜBİTAK önerileri ve kişisel dosyalar bir dış yapay zekâ servisine gidiyor mu?

## 3. Yanıt biçimi (Türkçe, kısa ve net)

1. **Kısa cevap:** Kuralım / koşullu / kurmayalım, tek cümleyle.
2. **Ne olduğu:** 2–4 madde.
3. **Olumlu yanlar:** Yalnızca doğrulanmış olanlar.
4. **Riskler ve eksikler:** Her birinin kanıtıyla (dosya, satır ya da komut çıktısı).
5. **Kurulacaksa güvenli yol:** Ayrı makine veya sanal makine, telemetriyi kapatma, kancasız kurulum, sürüm sabitleme.
6. **Alternatif:** Mevcut araçlarla aynı işin nasıl yapılacağı.

Olgu, çıkarım ve tahmini ayır. Doğrulamadığın şeyi "doğrulamadım" diye belirt. Bir bağlantı açılamazsa engeli aşmaya çalışma; nedenini söyle ve kullanıcıdan içeriği iste.

## 4. Kurulumu onaylanırsa

- İncelenen sürüme **sabitle**: git deposu için SHA, Python paketi için `uv tool install git+…@SHA`, npm için `paket@sürüm`.
- Kanca gerekmiyorsa **kancasız** kur; skill'leri doğrudan `~/.claude/skills/` altına kopyala.
- Kalıcı kurulum `enginacikalin/claude-kurulum` deposundaki `kur.sh` üzerinden yapılır. Yeni bölümü ekle, **boş bir ev dizininde** test et (`HOME=<scratchpad>/hometest bash kur.sh`), ikinci çalıştırmada çiftlenme olmadığını doğrula, sonra commit ve push yap. Depo **herkese açık**; içine API anahtarı, e-posta ya da kişisel veri koyma.
- MCP sunucusunu `mcp-inspector --cli <komut> --method tools/list` ile test et; açılış süresini ölç (30 sn zaman aşımı).
