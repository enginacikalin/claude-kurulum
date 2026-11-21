#!/usr/bin/env bash
# =============================================================================
#  Claude Code ana kurulum betiği  —  macOS / Linux (Windows: WSL içinde)
#  Bu klasörün içinden çalıştırın:   bash kur.sh
#  Tekrar çalıştırmak güvenlidir (zaten kurulu olanları atlar/günceller).
#  Kurulum sonrası Claude Code'u yeniden başlatın.
#
#  Bölümler (ayrı ayrı kapatmak için aşağıdaki değişkenleri 0 yapın):
#   1 EKLENTILER  : 10 incelenmiş eklenti (claude-video/watch dahil)
#   2 SCRAPLING   : web'den veri toplama + güvenlik kancası (telif/ToS korumalı)
#   3 BORSA       : Türk piyasası verisi (borsa-mcp, sabit sürüm) + borsaci
#   4 TRADING     : claude-trading-skills (TRADING_SET=core | all)
#   5 FOUNDER     : founder-skill (iş fikri değerlendirme paketi)
#   6 EK_SKILLER  : discernment-nudge, mcp-builder, doc-coauthoring,
#                   deep-research, sr-screener (kancasız)
#   7 KURALLAR    : ~/.claude/CLAUDE.md'ye Scrapling ve borsa kuralları
#   + INSPECTOR   : MCP Inspector (MCP sunucularını test etmek için)
#   + WEB         : web sitesi kalite, SEO, erişilebilirlik skill'leri + modern-web-guidance
#                   (PAZARLAMA=0 ile 12 reklam/pazarlama skill'i atlanır)
#   + TASARIM     : archify + brand-voice (3 skill, 5 alt ajan)
#   + BILIM       : K-Dense seçkisi (8) + materials-simulation seçkisi (5)
#   + MOBIL       : app-store-compliance (skill, /app-store-audit, gönderim öncesi koruma kancası)
#   + VIDEO       : HyperFrames (HTML'den video; 5 skill, CLI 0.9.77'ye sabit, telemetri kapalı)
# =============================================================================
set -uo pipefail
EKLENTILER=${EKLENTILER:-1}; SCRAPLING=${SCRAPLING:-1}; BORSA=${BORSA:-1}
TRADING=${TRADING:-1}; TRADING_SET=${TRADING_SET:-all}; FOUNDER=${FOUNDER:-1}
EK_SKILLER=${EK_SKILLER:-1}; KURALLAR=${KURALLAR:-1}
# İncelenmiş ve test edilmiş sürümler (güncellemek için SHA'yı değiştirin)
BORSA_COMMIT=e3b45b22dafa703135afa84a1dc92973603a56f1     # saidsurucu/borsa-mcp        2026-09-24
BORSACI_SHA=292956ea4cf742e01240425a5c85e6c1e24b1259      # saidsurucu/borsaci          2026-07-13
TRADING_SHA=a627d17dd1d8fde1c8fa73b3cc69ffe83b33cb71      # tradermonty/claude-trading-skills 2026-11-17
FOUNDER_SHA=fd9385b0cfe1b96bebce3898fbd506d73eff5a9d      # Jakeschincariol/founder-skill 2026-10-06
ANTHROPIC_SHA=e4bb5d960d87126ff3b3a8af1a104b7db67560ba    # anthropics/skills           2026-11-16
ARS_SHA=f7da54e81b06da3e659c93f5309a1c0f98bd202a          # Imbad0202/academic-research-skills 2026-11-17
WQ_SHA=afa8da942115f2961fdbfa80807ea0b232ff6c00           # addyosmani/web-quality-skills     2026-08-24
MKT_SHA=73573e94a06a39965978b3fa1f9c1eace8cebc7c          # coreyhaines31/marketingskills     2026-11-17
JK_SHA=547d415dc10a23e66088eba5aa6664e6e772432c           # jakubkrehel/skills                2026-11-18
MWG_SHA=64a6d708f5a43f2cd3fde5d4d7db3905ba1bdf65          # GoogleChrome/modern-web-guidance  2026-11-16
MWG_NPM=1.0.1                                             # npx sürümü (@latest yerine)
AR_SHA=44781293f38728baf04dbad33ce1a0cef8c39cca           # tt-a1i/archify                    2026-11-17 (v3.2)
KWP_SHA=b4c9a4e1de4b42868b74a6fe30ac766f64e43a3e          # anthropics/knowledge-work-plugins 2026-11-18
KD_SHA=ec59a29a03d5c40f73ab40878df04860bc00e876           # K-Dense-AI/claude-scientific-skills 2026-11-16
MS_SHA=a4bd93c4224fadcb27495eb7b9c9e13bc02b9417           # HeshamFS/materials-simulation-skills 2026-11-15
ASC_SHA=d2156bab9d7189835631c0a99adcc2479d32138d          # mjmirza/app-store-compliance      2026-11-15 (ORA 2.3: bireysel/okul ücretsiz)
HF_SHA=7cb605c787f4e85f66a2a46df60f8fdbe13faad6           # heygen-com/hyperframes            2026-11-21 (CLI 0.9.77)
HF_CLI=0.9.77                                             # npm'deki hyperframes CLI sürümü (sabit)

cd "$(dirname "$0")"; HERE=$(pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p ~/.claude/skills ~/.claude/hooks ~/.claude/skill-sources
OK=(); FAIL=()
log()  { printf '\n\033[1m== %s\033[0m\n' "$*"; }
ok()   { OK+=("$1"); }
bad()  { FAIL+=("$1"); echo "!! BAŞARISIZ: $1"; }
have() { command -v "$1" >/dev/null 2>&1; }
pipi() { pip install -q -U "$@" 2>/dev/null || pip3 install -q -U "$@" 2>/dev/null || python3 -m pip install -q -U --user "$@"; }
# İncelenmiş sürüme sabitlenmiş indirme: clone sahip/depo hedef SHA
clone(){ mkdir -p "$2" && git -C "$2" init -q && git -C "$2" fetch -q --depth 1 "https://github.com/$1" "$3" && git -C "$2" checkout -q FETCH_HEAD; }

have claude || { echo "Claude Code bulunamadı. Önce: curl -fsSL https://claude.ai/install.sh | bash"; exit 1; }
have git    || { echo "git gerekli."; exit 1; }
have python3|| { echo "Python 3.11+ gerekli."; exit 1; }
if ! have uvx; then log "uv kuruluyor"; curl -LsSf https://astral.sh/uv/install.sh | sh; export PATH="$HOME/.local/bin:$PATH"; fi

# ---------------------------------------------------------------- 1 EKLENTILER
if [ "$EKLENTILER" = 1 ]; then
  log "1/7 Eklentiler"
  addp() { claude plugin marketplace add "$1" >/dev/null 2>&1; claude plugin install "$2" >/dev/null 2>&1 && ok "eklenti $2" || bad "eklenti $2"; }
  addp bradautomates/claude-video           watch@claude-video
  addp obra/superpowers                     superpowers@superpowers-dev
  addp multica-ai/andrej-karpathy-skills    andrej-karpathy-skills@karpathy-skills
  addp nextlevelbuilder/ui-ux-pro-max-skill ui-ux-pro-max@ui-ux-pro-max-skill
  addp Leonxlnx/taste-skill                 taste-skill@taste-skill
  addp pbakaus/impeccable                   impeccable@impeccable
  addp Nutlope/hallmark                     hallmark@hallmark
  addp upstash/context7                     context7@context7-marketplace
  addp jarrodwatts/claude-hud               claude-hud@claude-hud
  addp mvanhorn/last30days-skill            last30days@last30days-skill
  # watch (claude-video) bağımlılıkları
  pipi "yt-dlp[default,curl-cffi]" && ok "yt-dlp" || bad "yt-dlp"
  if ! have ffmpeg; then
    if have brew; then brew install ffmpeg; elif have apt-get; then sudo apt-get install -y ffmpeg; fi
  fi
  have ffmpeg && ok "ffmpeg" || bad "ffmpeg (elle kurun)"
fi

# ---------------------------------------------------------------- 2 SCRAPLING
if [ "$SCRAPLING" = 1 ]; then
  log "2/7 Scrapling + güvenlik kancası"
  if pipi "scrapling[ai]" && scrapling install >/dev/null 2>&1; then ok "scrapling"; else bad "scrapling"; fi
  cp "$HERE/scrapling-guard.py" ~/.claude/hooks/scrapling-guard.py
  python3 - <<'EOF'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
pre = s.setdefault("hooks", {}).setdefault("PreToolUse", [])
if not any(h.get("matcher") == "mcp__scrapling__.*" for h in pre):
    pre.append({"matcher": "mcp__scrapling__.*",
                "hooks": [{"type": "command", "command": "python3 ~/.claude/hooks/scrapling-guard.py", "timeout": 30}]})
json.dump(s, open(p, "w"), indent=2, ensure_ascii=False)
EOF
  ok "scrapling güvenlik kancası"
  claude mcp remove --scope user scrapling >/dev/null 2>&1
  claude mcp add --scope user scrapling "$(command -v scrapling-mcp)" >/dev/null 2>&1 && ok "scrapling MCP" || bad "scrapling MCP"
fi

# ---------------------------------------------------------------- 3 BORSA
if [ "$BORSA" = 1 ]; then
  log "3/7 Borsa MCP (yerel, sabit sürüm) + borsaci"
  # Kalıcı araç olarak kur: her oturum açılışında git'ten yeniden çözümlemesin (zaman aşımını önler)
  claude mcp remove --scope user borsa >/dev/null 2>&1
  if uv tool install -q --force "git+https://github.com/saidsurucu/borsa-mcp@$BORSA_COMMIT" >/dev/null 2>&1 \
     && BM=$(command -v borsa-mcp || echo "$HOME/.local/bin/borsa-mcp") && [ -x "$BM" ]; then
    claude mcp add --scope user borsa "$BM" >/dev/null 2>&1 && ok "borsa MCP" || bad "borsa MCP"
  else bad "borsa-mcp kurulumu"; fi
  clone saidsurucu/borsaci "$tmp/borsaci" "$BORSACI_SHA" && rm -rf ~/.claude/skills/borsaci && cp -r "$tmp/borsaci/skill/borsaci" ~/.claude/skills/ && ok "borsaci skill" || bad "borsaci skill"
fi

# MCP Inspector (resmî MCP test aracı, sabit sürüm): mcp-inspector --cli <komut> --method tools/list
if [ "${INSPECTOR:-1}" = 1 ]; then
  npm install -g -q @modelcontextprotocol/inspector@2.16.0 >/dev/null 2>&1 && ok "MCP Inspector 2.16.0" || bad "MCP Inspector"
fi

# ---------------------------------------------------------------- 4 TRADING
if [ "$TRADING" = 1 ]; then
  log "4/7 claude-trading-skills ($TRADING_SET)"
  if clone tradermonty/claude-trading-skills "$tmp/cts" "$TRADING_SHA"; then
    if [ "$TRADING_SET" = core ]; then
      list="trading-skills-navigator position-sizer trader-memory-core pre-trade-discipline-gate drawdown-circuit-breaker backtest-expert trade-performance-coach"
    else
      list=$(cd "$tmp/cts/skills" && for d in */; do [ -f "$d/SKILL.md" ] && echo "${d%/}"; done)
    fi
    n=0; for s in $list; do rm -rf ~/.claude/skills/$s; cp -r "$tmp/cts/skills/$s" ~/.claude/skills/ && n=$((n+1)); done
    ok "trading skill ($n adet)"
  else bad "trading skills"; fi
fi

# ---------------------------------------------------------------- 5 FOUNDER
if [ "$FOUNDER" = 1 ]; then
  log "5/7 founder-skill"
  if clone Jakeschincariol/founder-skill "$tmp/fs" "$FOUNDER_SHA"; then
    for d in "$tmp/fs/skills/"*/; do s=$(basename "$d"); rm -rf ~/.claude/skills/$s; cp -r "$d" ~/.claude/skills/; done
    ok "founder skill ($(ls "$tmp/fs/skills" | wc -l | tr -d ' ') adet)"
  else bad "founder skills"; fi
fi

# ---------------------------------------------------------------- 6 EK SKILLER
if [ "$EK_SKILLER" = 1 ]; then
  log "6/7 Ek skill'ler (kancasız)"
  if clone anthropics/skills "$tmp/anthropic" "$ANTHROPIC_SHA"; then
    for s in discernment-nudge mcp-builder doc-coauthoring; do rm -rf ~/.claude/skills/$s; cp -r "$tmp/anthropic/skills/$s" ~/.claude/skills/; done
    ok "discernment-nudge, mcp-builder, doc-coauthoring"
  else bad "anthropic skills"; fi
  SRC=~/.claude/skill-sources/academic-research-skills
  rm -rf "$SRC"
  if clone Imbad0202/academic-research-skills "$SRC" "$ARS_SHA"; then
    rm -rf "$SRC/hooks" "$SRC/.git"
    for s in deep-research sr-screener; do
      [ -e "$SRC/$s/shared" ]  || ln -s ../shared  "$SRC/$s/shared"
      [ -e "$SRC/$s/scripts" ] || ln -s ../scripts "$SRC/$s/scripts"
      rm -rf ~/.claude/skills/$s; ln -s "$SRC/$s" ~/.claude/skills/$s
    done
    ok "deep-research, sr-screener"
  else bad "academic-research-skills"; fi
fi

# ---------------------------------------------------------------- WEB (site geliştirme)
if [ "${WEB:-1}" = 1 ]; then
  log "Web sitesi skill'leri (kancasız, sabit sürüm)"
  if clone addyosmani/web-quality-skills "$tmp/wq" "$WQ_SHA"; then
    for d in "$tmp/wq/skills/"*/; do s=$(basename "$d"); rm -rf ~/.claude/skills/$s; cp -r "$d" ~/.claude/skills/; done
    ok "web-quality-skills ($(ls "$tmp/wq/skills" | wc -l | tr -d ' ') skill)"
  else bad "web-quality-skills"; fi
  if clone coreyhaines31/marketingskills "$tmp/mkt" "$MKT_SHA"; then
    for s in seo-audit schema; do rm -rf ~/.claude/skills/$s; cp -r "$tmp/mkt/skills/$s" ~/.claude/skills/; done
    ok "seo-audit, schema"
    # Reklam ve pazarlama seçkisi (yalnızca metin; betik içeren conversion-tracking hariç)
    if [ "${PAZARLAMA:-1}" = 1 ]; then
      MKT_SET="ad-creative ads copywriting social content-strategy ai-seo public-relations emails customer-research marketing-plan image video"
      for s in $MKT_SET; do rm -rf ~/.claude/skills/$s; cp -r "$tmp/mkt/skills/$s" ~/.claude/skills/; done
      ok "pazarlama seçkisi ($(echo $MKT_SET | wc -w | tr -d ' ') skill)"
    fi
  else bad "marketingskills"; fi
  if clone jakubkrehel/skills "$tmp/jk" "$JK_SHA"; then
    rm -rf ~/.claude/skills/better-accessibility; cp -r "$tmp/jk/skills/better-accessibility" ~/.claude/skills/
    ok "better-accessibility"
  else bad "jakubkrehel/skills"; fi
  if clone GoogleChrome/modern-web-guidance "$tmp/mwg" "$MWG_SHA"; then
    rm -rf ~/.claude/skills/modern-web-guidance; cp -r "$tmp/mwg/skills/modern-web-guidance" ~/.claude/skills/
    # Sürümü incelenen npm sürümüne sabitle ve kullanım verisini YALNIZCA bu komutlar için kapat
    # (genel Claude Code ayarlarına dokunmadan): "npx -y modern-web-guidance@latest" ->
    # "DISABLE_TELEMETRY=1 npx -y modern-web-guidance@<sürüm>"
    sed -i.bak -E "s/(npx -y |pnpx )?modern-web-guidance@latest/DISABLE_TELEMETRY=1 \1modern-web-guidance@$MWG_NPM/g" \
      ~/.claude/skills/modern-web-guidance/SKILL.md && rm -f ~/.claude/skills/modern-web-guidance/SKILL.md.bak
    ok "modern-web-guidance (npm $MWG_NPM, telemetri komut bazında kapalı)"
  else bad "modern-web-guidance"; fi
fi

# ---------------------------------------------------------------- TASARIM VE MARKA
if [ "${TASARIM:-1}" = 1 ]; then
  log "Diyagram (archify) ve marka sesi (kancasız, sabit sürüm)"
  if clone tt-a1i/archify "$tmp/ar" "$AR_SHA"; then
    rm -rf ~/.claude/skills/diagram-design ~/.claude/skills/archify   # diagram-design'ın yerini archify aldı
    cp -r "$tmp/ar/archify" ~/.claude/skills/
    # Sürüm sabit olduğu için güncelleme kontrolünü yalnızca bu kopyada kapat (genel ayarlara dokunmadan)
    f=~/.claude/skills/archify/scripts/check-update.mjs
    sed -i.bak "s#return process.env.ARCHIFY_UPDATE_CHECK_DISABLED === '1';#return true; // claude-kurulum: sürüm sabit, güncelleme kontrolü kapalı#" "$f" && rm -f "$f.bak"
    grep -q "claude-kurulum: sürüm sabit" "$f" && ok "archify 3.2 (güncelleme kontrolü kapalı)" || bad "archify güncelleme kontrolü kapatılamadı"
  else bad "archify"; fi
  if clone anthropics/knowledge-work-plugins "$tmp/kwp" "$KWP_SHA"; then
    BV="$tmp/kwp/partner-built/brand-voice"
    for d in "$BV/skills/"*/; do s=$(basename "$d"); rm -rf ~/.claude/skills/$s; cp -r "$d" ~/.claude/skills/; done
    # Skill'lerin uzun ve kritik metinlerde çağırdığı alt ajanlar (eklentinin dış servis bağlantıları kurulmaz)
    mkdir -p ~/.claude/agents && cp "$BV/agents/"*.md ~/.claude/agents/
    ok "brand-voice (3 skill + $(ls "$BV/agents" | wc -l | tr -d ' ') alt ajan)"
  else bad "brand-voice"; fi
fi

# ---------------------------------------------------------------- BILIM (deney, analiz, simülasyon)
if [ "${BILIM:-1}" = 1 ]; then
  log "Bilimsel analiz ve simülasyon skill'leri (kancasız, API anahtarı gerektirmeyenler, sabit sürüm)"
  if clone K-Dense-AI/claude-scientific-skills "$tmp/kd" "$KD_SHA"; then
    KD_SET="pymoo experimental-design uncertainty-and-units statistical-analysis scientific-visualization matplotlib pymatgen lab-hardware-cad"
    for s in $KD_SET; do rm -rf ~/.claude/skills/$s; cp -r "$tmp/kd/skills/$s" ~/.claude/skills/; done
    ok "K-Dense seçkisi ($(echo $KD_SET | wc -w | tr -d ' ') skill)"
  else bad "K-Dense"; fi
  if clone HeshamFS/materials-simulation-skills "$tmp/ms" "$MS_SHA"; then
    for p in core-numerical/numerical-stability core-numerical/convergence-study simulation-workflow/post-processing \
             simulation-workflow/simulation-validator simulation-workflow/parameter-optimization; do
      s=$(basename "$p"); rm -rf ~/.claude/skills/$s; cp -r "$tmp/ms/skills/$p" ~/.claude/skills/
      # ortak açıklama dosyasını skill'in içine al, yolu düzelt
      if grep -q '\.\./\.\./GROUNDED_EXPLANATIONS.md' ~/.claude/skills/$s/SKILL.md; then
        cp "$tmp/ms/skills/GROUNDED_EXPLANATIONS.md" ~/.claude/skills/$s/
        sed -i.bak 's#\.\./\.\./GROUNDED_EXPLANATIONS.md#GROUNDED_EXPLANATIONS.md#g' ~/.claude/skills/$s/SKILL.md && rm -f ~/.claude/skills/$s/SKILL.md.bak
      fi
    done
    ok "materials-simulation seçkisi (5 skill)"
  else bad "materials-simulation-skills"; fi
fi

# ---------------------------------------------------------------- MOBIL (App Store / Google Play uyumu)
if [ "${MOBIL:-1}" = 1 ]; then
  log "App Store uyum denetimi (skill + /app-store-audit + gönderim öncesi koruma kancası)"
  if clone mjmirza/app-store-compliance "$tmp/asc" "$ASC_SHA"; then
    # Projenin kendi kurucusu: skill, komut ve yalnızca mağaza gönderim komutlarında devreye giren PreToolUse kancası
    if bash "$tmp/asc/scripts/install.sh" --tool claude >"$tmp/asc-kur.log" 2>&1; then
      ok "app-store-compliance (skill, /app-store-audit, gönderim koruması)"
    else bad "app-store-compliance (ayrıntı: kurulum günlüğü)"; tail -5 "$tmp/asc-kur.log"; fi
  else bad "app-store-compliance"; fi
fi

# ---------------------------------------------------------------- VIDEO (HyperFrames: HTML'den video)
if [ "${VIDEO:-1}" = 1 ]; then
  log "HyperFrames video skill'leri (kancasız, CLI $HF_CLI'e sabit, kullanım verisi ve otomatik güncelleme kapalı)"
  if clone heygen-com/hyperframes "$tmp/hf" "$HF_SHA"; then
    # Çekirdek 5 skill. media-use (HeyGen girişi, hazır görsel/müzik kaynakları), figma, reverse-any-video
    # (başkasının videosunu yeniden kurma) ve remotion-to-hyperframes bilinçli olarak alınmaz.
    for s in hyperframes hyperframes-cli hyperframes-registry slideshow style-sampling; do
      rm -rf ~/.claude/skills/$s; cp -r "$tmp/hf/skills/$s" ~/.claude/skills/
    done
    HF_CLI="$HF_CLI" python3 - <<'PYEOF'
import os, re
f = os.path.expanduser("~/.claude/skills/hyperframes/scripts/plugin-cli.mjs")
t = open(f, encoding="utf-8").read()
ver = os.environ["HF_CLI"]
a = "  let release = version;\n"
b = "    : { ...env };\n"
if "claude-kurulum" not in t:
    assert a in t and b in t, "plugin-cli.mjs beklenen biçimde değil"
    t = t.replace(a, a + f"  // claude-kurulum: CLI sürümü sabit (bağımsız kurulum varsayılanı 'en yeni')\n"
                       f"  if (!version && env.HYPERFRAMES_STANDALONE_CLI_VERSION === undefined)\n"
                       f"    env = {{ ...env, HYPERFRAMES_STANDALONE_CLI_VERSION: \"{ver}\" }};\n", 1)
    t = t.replace(b, '    : { HYPERFRAMES_SKIP_SKILLS: "1", HYPERFRAMES_NO_UPDATE_CHECK: "1", HYPERFRAMES_NO_TELEMETRY: "1", DO_NOT_TRACK: "1", ...env }; // claude-kurulum\n', 1)
    open(f, "w", encoding="utf-8").write(t)
PYEOF
    if grep -q 'claude-kurulum' ~/.claude/skills/hyperframes/scripts/plugin-cli.mjs; then
      ok "HyperFrames (5 skill, CLI $HF_CLI sabit, telemetri ve otomatik güncelleme kapalı)"
    else bad "HyperFrames başlatıcı yaması"; fi
  else bad "HyperFrames"; fi
fi

# Bu depodaki kendi skill'lerimiz (ör. arac-degerlendirme)
if [ -d "$HERE/skills" ]; then
  for d in "$HERE/skills/"*/; do s=$(basename "$d"); rm -rf ~/.claude/skills/$s; cp -r "$d" ~/.claude/skills/; done
  ok "kendi skill'lerimiz ($(ls "$HERE/skills" | tr '\n' ' '))"
fi

# ---------------------------------------------------------------- 7 KURALLAR
if [ "$KURALLAR" = 1 ]; then
  log "7/7 CLAUDE.md kuralları"
  touch ~/.claude/CLAUDE.md
  # CLAUDE-kurallar.md'deki her "## " bölümünü, başlığı henüz yoksa ekle
  python3 - "$HERE/CLAUDE-kurallar.md" <<'PYEOF'
import os, re, sys
src = open(sys.argv[1], encoding="utf-8").read()
dst_p = os.path.expanduser("~/.claude/CLAUDE.md")
dst = open(dst_p, encoding="utf-8").read()
parts = re.split(r"(?m)^(?=## )", src)
add = [p.rstrip() for p in parts if p.startswith("## ") and p.splitlines()[0] not in dst]
if add:
    open(dst_p, "a", encoding="utf-8").write("\n\n" + "\n\n".join(add) + "\n")
PYEOF
  ok "kurallar"
fi

# ---------------------------------------------------------------- ÖZET
log "Özet"
printf '  ✓ %s\n' "${OK[@]}"
[ ${#FAIL[@]} -gt 0 ] && printf '  ✗ %s\n' "${FAIL[@]}"
echo; echo "Claude Code'u yeniden başlatın. Kontrol:  claude plugin list ; claude mcp list"
[ ${#FAIL[@]} -eq 0 ]
