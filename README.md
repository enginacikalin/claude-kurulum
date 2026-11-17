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
- **MCP bağlantıları:** scrapling (güvenlik kancasıyla), borsa (borsa-mcp, sabit sürüm `e3b45b2`)
- **Skill'ler:** borsaci, claude-trading-skills, founder-skill, discernment-nudge, mcp-builder, doc-coauthoring, deep-research, sr-screener

Kurulan her depo kurulmadan önce incelendi. Skill depoları ve borsa-mcp, `kur.sh` başındaki SHA değerleriyle incelenmiş sürüme sabitlenmiştir; upstream'deki yeni bir değişiklik otomatik gelmez. Güncellemek için önce yeni sürümü inceleyin, sonra SHA'yı değiştirin. Kancası, ağ bağlantısı veya telif riski olanlar ya kancasız kuruluyor ya da listeye alınmadı.
