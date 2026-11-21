# claude-kurulum

Claude Code için kişisel kurulum: eklentiler, MCP bağlantıları, skill'ler ve kurallar. Hem kendi bilgisayarınızda hem de Claude Code bulut ortamında çalışır.

## Dosyalar

| Dosya | İşlevi |
|---|---|
| `kur.sh` | Ana kurulum betiği. Tekrar çalıştırmak güvenlidir. |
| `bulut-setup.sh` | Bulut ortamının Setup script alanına yapıştırılacak metin. |
| `scrapling-guard.py` | Scrapling güvenlik kancası: telif, kullanım koşulları, robots.txt, hız sınırı. |
| `CLAUDE-kurallar.md` | `~/.claude/CLAUDE.md`'ye eklenen kurallar: Scrapling ve borsa verisi güvenilirliği. |

## Kendi bilgisayarınızda (macOS / Linux / WSL)

```bash
bash kur.sh
```

Seçmeli kurulum için bölümleri kapatabilirsiniz: `TRADING_SET=core bash kur.sh`, `FOUNDER=0 bash kur.sh` gibi.

## Bulut ortamında

1. Ortam ayarlarını açın: oturum başlığındaki bulut ortamı menüsü, ardından **Edit**.
2. **Repositories** bölümüne bu depoyu ekleyin.
3. **Setup script** alanına `bulut-setup.sh` dosyasının içeriğini yapıştırın.
4. Yeni bir oturum başlatın ve bu depoyu seçin.

## Kurulanlar

- **Eklentiler:** watch (claude-video), superpowers, karpathy-skills, ui-ux-pro-max, taste-skill, impeccable, hallmark, context7, claude-hud, last30days
- **MCP bağlantıları:** scrapling (güvenlik kancasıyla), borsa (borsa-mcp, sabit sürüm `e3b45b2`, kalıcı araç olarak)
- **Web sitesi skill'leri:** web-quality-skills (6), seo-audit, schema, better-accessibility, modern-web-guidance (npm 1.0.1, telemetri komut bazında kapalı); hepsi kancasız ve sabit sürüm
- **Reklam ve pazarlama seçkisi (12):** ad-creative, ads, copywriting, social, content-strategy, ai-seo, public-relations, emails, customer-research, marketing-plan, image, video (coreyhaines31/marketingskills, sabit SHA; `PAZARLAMA=0` ile atlanır)
- **Bilim (BILIM):** K-Dense seçkisi: pymoo, experimental-design, uncertainty-and-units, statistical-analysis, scientific-visualization, matplotlib, pymatgen, lab-hardware-cad; materials-simulation seçkisi: numerical-stability, convergence-study, post-processing, simulation-validator, parameter-optimization (API anahtarı gerektirmeyenler, sabit SHA; `BILIM=0` ile atlanır)
- **Tasarım ve marka (TASARIM):** archify, brand-voice (3 skill + 5 alt ajan; dış servis bağlantıları kurulmaz), sabit SHA; `TASARIM=0` ile atlanır
- **Mobil (MOBIL):** app-store-compliance (mjmirza, sabit SHA d2156ba; ORA 2.3 lisansı bireysel kullanım ve okullar için ücretsiz): App Store ve Google Play uyum denetimi skill'i, `/app-store-audit` komutu ve yalnızca mağaza gönderim komutlarında (eas submit, fastlane…) devreye girip kritik ret riski varsa gönderimi durduran PreToolUse kancası; `MOBIL=0` ile atlanır
- **Video (VIDEO):** HyperFrames (heygen-com, Apache 2.0, SHA 7cb605c): HTML'den video; yalnızca 5 skill (hyperframes, hyperframes-cli, hyperframes-registry, slideshow, style-sampling). CLI 0.9.77'ye sabitlendi; başlatıcı (`plugin-cli.mjs`) kopyada yamalandı: kullanım verisi, otomatik güncelleme ve skill'lerin kendiliğinden yenilenmesi kapalı. media-use, figma, reverse-any-video ve remotion-to-hyperframes alınmadı; `VIDEO=0` ile atlanır
- **Kendi skill'lerimiz:** `arac-degerlendirme`: GitHub deposu, eklenti, skill veya MCP kurmadan önce güvenlik, telif, akademik etik ve uygunluk değerlendirmesi ; `makale-ilkeleri`: akademik metinle her çalışmada akademik dürüstlük ve Q1 hakem kontrolü; `istem-kutuphanesi`: prompts.chat'in yaklaşık 3.083 istem şablonunda çevrimdışı arama (veri CC0 1.0 kamu malı, kaynak f/prompts.chat SHA 29417a1; dışarıya bağlanmaz, skill kurmaz); `arge-tarifleri`: DoE, ölçüm belirsizliği, Pareto optimizasyonu, numune tutucu CAD, veri işleme ve simülasyon doğrulama için yönlendirici (`skills/` klasörü)
- **Araçlar:** MCP Inspector 2.16.0 (`mcp-inspector --cli <sunucu komutu> --method tools/list` ile MCP sunucularını test etmek için)
- **Skill'ler:** borsaci, claude-trading-skills, founder-skill, discernment-nudge, mcp-builder, doc-coauthoring, deep-research, sr-screener

Kurulan her depo kurulmadan önce incelendi. Skill depoları ve borsa-mcp, `kur.sh` başındaki SHA değerleriyle incelenmiş sürüme sabitlenmiştir; upstream'deki yeni bir değişiklik otomatik gelmez. Güncellemek için önce yeni sürümü inceleyin, sonra SHA'yı değiştirin. Kancası, ağ bağlantısı veya telif riski olanlar ya kancasız kuruluyor ya da listeye alınmadı.

## Claude uygulamasında (claude.ai) kullanmak

`claude-ai-yukleme/` klasöründeki ZIP dosyaları, kendi skill'lerimizin claude.ai'ye yüklenebilir paketleridir. Claude uygulamasında **Ayarlar → Capabilities** altında kod çalıştırmayı açın, ardından **Customize → Skills** bölümünden ZIP'i yükleyin. Skill'ler klasörde değişirse ZIP'leri yeniden üretin: `cd skills && for s in */; do zip -qr ../claude-ai-yukleme/${s%/}.zip ${s%/}; done`
