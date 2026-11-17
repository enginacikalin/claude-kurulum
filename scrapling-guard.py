#!/usr/bin/env python3
"""Scrapling güvenlik kancası (Claude Code PreToolUse).

Claude bir Scrapling MCP aracını çağırmadan önce çalışır; Claude bu kancayı atlayamaz.
Reddeder:  giriş/oturum saklama, serbest JS, tıklama/form, gerçek Chrome, proxy, çerez,
           kimlik bilgisi, Cloudflare/bot engeli aşma, GET dışı istekler,
           yayıncı/veritabanı/korsan/standart siteleri, kurum proxy'leri,
           robots.txt'nin izin vermediği sayfalar, alan adı başına günlük sınırı aşan istekler.
Zorlar:    sahte Google yönlendirmesi kapalı, gizlenmiş başlıklar kapalı, görünmez tarayıcı.
Yavaşlatır: aynı alan adına en az MIN_INTERVAL saniye arayla istek.
"""
import json, os, sys, time, urllib.parse, urllib.request, urllib.robotparser

MIN_INTERVAL = 5          # saniye, aynı alan adına iki istek arası
DAILY_CAP = 150           # alan adı başına günlük istek sınırı (toplu indirmeyi önler)
STATE = os.path.expanduser("~/.claude/scrapling-guard-state.json")

# Hiç kullanılmayacak araçlar
DENY_TOOLS = {
    "browser_save_state": "giriş/oturum bilgisi kaydetme",
    "browser_load_state": "kayıtlı giriş/oturum yükleme",
    "browser_evaluate": "sayfada serbest JavaScript çalıştırma",
    "browser_actions": "tıklama, yazma, form gönderme",
}

# Bu parametreler dolu/true ise reddet
DENY_PARAMS = {
    "real_chrome": "bilgisayardaki gerçek Chrome'u kullanma",
    "cdp_url": "açık bir tarayıcıya bağlanma",
    "executable_path": "özel tarayıcı çalıştırma",
    "proxy": "proxy üzerinden kimlik gizleme",
    "proxy_auth": "proxy kimlik bilgisi",
    "cookies": "çerez/oturum kullanma",
    "auth": "kullanıcı adı/şifre gönderme",
    "credentials": "kimlik bilgisi gönderme",
    "solve_cloudflare": "Cloudflare/bot engelini aşma",
    "hide_canvas": "tarayıcı parmak izini gizleme",
    "block_webrtc": "tarayıcı parmak izini gizleme",
    "useragent": "tarayıcı kimliğini taklit etme",
    "impersonate": "tarayıcı kimliğini taklit etme",
    "additional_args": "denetlenemeyen ek tarayıcı ayarları",
    "data": "form/veri gönderme",
    "json": "veri gönderme",
}

# Zorla güvenli değere çekilenler
FORCE = {"google_search": False, "stealthy_headers": False, "headless": True}
FORCE_BY_TOOL = {   # her aracın gerçekten kabul ettiği parametreler (Scrapling MCP kaynak kodundan)
    "browser_fetch_once": ("google_search", "headless"),
    "browser_open": ("headless",),
    "browser_fetch": ("google_search",),
    "make_request": ("stealthy_headers",),
    "session_make_request": ("stealthy_headers",),
}

# Alan adı (veya alt alan adı) bu listedeyse reddet
BLOCKED_DOMAINS = [
    # Abonelikli yayıncılar ve veritabanları (kullanım koşulları kazımayı yasaklar; kurum erişimi kapanabilir)
    "sciencedirect.com", "elsevier.com", "scopus.com", "webofscience.com", "clarivate.com",
    "springer.com", "springernature.com", "nature.com", "wiley.com", "tandfonline.com",
    "sagepub.com", "ieeexplore.ieee.org", "acs.org", "rsc.org", "iop.org", "aip.org",
    "jstor.org", "proquest.com", "ebsco.com", "ebscohost.com", "emerald.com",
    "cambridge.org", "academic.oup.com", "degruyter.com", "thieme-connect.com",
    "asme.org", "asmedigitalcollection.asme.org", "sae.org", "knovel.com", "reaxys.com",
    "cas.org", "scifinder.cas.org", "dimensions.ai",
    "scholar.google.com", "researchgate.net", "academia.edu",
    # Telifli standartlar
    "astm.org", "iso.org", "tse.org.tr", "din.de", "beuth.de", "bsigroup.com", "iec.ch",
    # Kişisel hesaplar / devlet girişleri
    "turkiye.gov.tr", "pbs.tubitak.gov.tr", "arbis.tubitak.gov.tr", "yoksis.yok.gov.tr",
    "mail.google.com", "outlook.live.com", "outlook.office.com",
]
# Adresin herhangi bir yerinde geçerse reddet (korsan siteler, kurum proxy'leri)
BLOCKED_SUBSTRINGS = ["sci-hub", "scihub", "libgen", "z-lib", "zlibrary", "annas-archive",
                      "ezproxy", ".idm.oclc.org", "/login", "/signin", "/sign-in", "/oturum-ac"]


def out(decision, reason, updated=None):
    o = {"hookSpecificOutput": {"hookEventName": "PreToolUse",
                                 "permissionDecision": decision,
                                 "permissionDecisionReason": reason}}
    if updated is not None:
        o["hookSpecificOutput"]["updatedInput"] = updated
    print(json.dumps(o, ensure_ascii=False))
    sys.exit(0)


def deny(reason):
    out("deny", "Scrapling güvenlik kuralı: " + reason +
        ". Bu kural kullanıcının isteğiyle konmuştur; atlatmaya çalışma, kullanıcıya bildir.")


def truthy(v):
    return v not in (None, False, "", [], {}, 0, "false", "False")


def load_state():
    try:
        with open(STATE) as f:
            return json.load(f)
    except Exception:
        return {}


def save_state(s):
    try:
        os.makedirs(os.path.dirname(STATE), exist_ok=True)
        with open(STATE, "w") as f:
            json.dump(s, f)
    except Exception:
        pass


def robots_allows(url, state):
    p = urllib.parse.urlsplit(url)
    key = f"robots:{p.scheme}://{p.netloc}"
    cached = state.get(key)
    if cached and time.time() - cached["t"] < 86400:
        text, status = cached["text"], cached["status"]
    else:
        status, text = 0, ""
        try:
            req = urllib.request.Request(f"{p.scheme}://{p.netloc}/robots.txt",
                                         headers={"User-Agent": "Mozilla/5.0 (research; robots check)"})
            with urllib.request.urlopen(req, timeout=8) as r:
                status, text = r.status, r.read(500_000).decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            status = e.code
        except Exception:
            status = -1
        state[key] = {"t": time.time(), "text": text, "status": status}
    if status == -1 or status >= 500:
        return False, "robots.txt okunamadı (site izin durumu doğrulanamadı)"
    if status in (401, 403):
        return False, "site robots.txt erişimini reddediyor"
    if status >= 400:          # robots.txt yok → standart gereği izinli
        return True, ""
    rp = urllib.robotparser.RobotFileParser()
    rp.parse(text.splitlines())
    if not rp.can_fetch("*", url):
        return False, "robots.txt bu sayfanın otomatik okunmasına izin vermiyor"
    return True, ""


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        deny("kanca girdisi okunamadı")
    tool = data.get("tool_name", "").split("__")[-1]
    args = dict(data.get("tool_input") or {})

    if tool in DENY_TOOLS:
        deny(f"'{tool}' kapalı ({DENY_TOOLS[tool]})")
    for k, why in DENY_PARAMS.items():
        if truthy(args.get(k)):
            deny(f"'{k}' seçeneği kapalı ({why})")
    if str(args.get("method", "GET")).upper() != "GET":
        deny("yalnızca okuma (GET) isteklerine izin var")

    url = args.get("url")
    if url:
        p = urllib.parse.urlsplit(url)
        host = (p.hostname or "").lower()
        if p.scheme not in ("http", "https") or not host:
            deny("geçersiz adres")
        low = url.lower()
        for d in BLOCKED_DOMAINS:
            if host == d or host.endswith("." + d):
                deny(f"{d} yasaklı listede (telif / kullanım koşulları / kişisel hesap)")
        for s in BLOCKED_SUBSTRINGS:
            if s in low:
                deny(f"adres yasaklı ifade içeriyor: {s}")

        state = load_state()
        ok, why = robots_allows(url, state)
        if not ok:
            save_state(state)
            deny(why)
        today = time.strftime("%Y-%m-%d")
        ck = f"count:{today}:{host}"
        if state.get(ck, 0) >= DAILY_CAP:
            save_state(state)
            deny(f"{host} için günlük {DAILY_CAP} istek sınırı doldu (toplu indirmeyi önlemek için)")
        lk = f"last:{host}"
        wait = MIN_INTERVAL - (time.time() - state.get(lk, 0))
        if wait > 0:
            time.sleep(min(wait, MIN_INTERVAL))
        state[lk] = time.time()
        state[ck] = state.get(ck, 0) + 1
        # eski sayaçları temizle
        for k in [k for k in state if k.startswith("count:") and not k.startswith(f"count:{today}")]:
            del state[k]
        save_state(state)

    changed = False
    for k in FORCE_BY_TOOL.get(tool, ()):
        if args.get(k, None) != FORCE[k]:
            args[k] = FORCE[k]
            changed = True
    if changed:
        out("allow", "Scrapling güvenlik kuralı: güvenli ayarlar uygulandı", args)
    sys.exit(0)   # normal izin akışı


if __name__ == "__main__":
    main()
