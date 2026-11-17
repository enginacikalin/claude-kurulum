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
  claude mcp remove --scope user borsa >/dev/null 2>&1
  claude mcp add --scope user borsa -- "$(command -v uvx)" --from "git+https://github.com/saidsurucu/borsa-mcp@$BORSA_COMMIT" borsa-mcp >/dev/null 2>&1 \
    && ok "borsa MCP" || bad "borsa MCP"
  clone saidsurucu/borsaci "$tmp/borsaci" "$BORSACI_SHA" && rm -rf ~/.claude/skills/borsaci && cp -r "$tmp/borsaci/skill/borsaci" ~/.claude/skills/ && ok "borsaci skill" || bad "borsaci skill"
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

# ---------------------------------------------------------------- 7 KURALLAR
if [ "$KURALLAR" = 1 ]; then
  log "7/7 CLAUDE.md kuralları"
  touch ~/.claude/CLAUDE.md
  grep -q "Scrapling) kuralları" ~/.claude/CLAUDE.md || { printf '\n'; sed -n '/^## Web/,/^## Türk/p' "$HERE/CLAUDE-kurallar.md" | sed '$d'; } >> ~/.claude/CLAUDE.md
  grep -q "borsa MCP / borsaci" ~/.claude/CLAUDE.md || { printf '\n'; sed -n '/^## Türk/,$p' "$HERE/CLAUDE-kurallar.md"; } >> ~/.claude/CLAUDE.md
  ok "kurallar"
fi

# ---------------------------------------------------------------- ÖZET
log "Özet"
printf '  ✓ %s\n' "${OK[@]}"
[ ${#FAIL[@]} -gt 0 ] && printf '  ✗ %s\n' "${FAIL[@]}"
echo; echo "Claude Code'u yeniden başlatın. Kontrol:  claude plugin list ; claude mcp list"
[ ${#FAIL[@]} -eq 0 ]
