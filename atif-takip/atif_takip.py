#!/usr/bin/env python3
"""Atıf takibi: OpenAlex + Crossref.

Yayın listesini ve atıfları çeker, tarihli bir anlık görüntü kaydeder, bir önceki
görüntüyle karşılaştırır ve Türkçe bir Markdown rapor yazar:
  - toplam atıf ve h-indeks (OpenAlex ve Crossref ayrı ayrı)
  - son kayıttan bu yana yeni atıflar ve atıf yapan yayınlar (kendine atıf işaretli)
  - h-indeksin bir sonraki eşiği için hangi makalenin kaç atıfa ihtiyacı olduğu
  - iki kaynak arasındaki farklar

Kullanım:
    OPENALEX_API_KEY=... python3 atif_takip.py            # çalıştır, kaydet, rapor yaz
    python3 atif_takip.py --kuru                          # kaydetmeden yalnızca rapor bas

Yalnızca standart kütüphane kullanır. Ağ: api.openalex.org, api.crossref.org.
Not: Web of Science resmî rakam değildir; ÜAK/YÖK başvuruları için WoS'tan teyit edin.
"""
import argparse, csv, datetime as dt, json, os, sys, time, urllib.parse, urllib.request
from pathlib import Path

AUTHOR_ID = "A5113785425"            # OpenAlex yazar kimliği
ORCID = "0000-0001-8151-3788"
# h-indekse ve "makale" listesine girecek türler (veri seti, tez vb. ayrı gösterilir)
COUNTED_TYPES = {"article", "review", "conference-paper", "book-chapter", "book", "letter"}

HERE = Path(__file__).resolve().parent
VERI = HERE / "veri"
RAPOR = HERE / "rapor"
UA = "atif-takip/1.0 (kişisel akademik atıf takibi)"


# ----------------------------------------------------------------------------- ağ
def _get(url, headers=None, tries=4):
    h = {"User-Agent": UA, "Accept": "application/json"}
    h.update(headers or {})
    last = None
    for i in range(tries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=40) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", "replace")[:300]
            if e.code == 404:
                return None
            if e.code in (401, 403) or "Insufficient budget" in body:
                raise SystemExit(f"OpenAlex/Crossref erişim hatası ({e.code}): {body}\n"
                                 "OPENALEX_API_KEY ortam değişkenini kontrol edin.")
            last = f"HTTP {e.code}: {body}"
        except Exception as e:  # ağ kesintisi vb.
            last = repr(e)
        time.sleep(2 * (i + 1))
    raise SystemExit(f"İstek başarısız: {url}\n{last}")


def openalex(path, **params):
    key = os.environ.get("OPENALEX_API_KEY", "").strip()
    if not key:
        raise SystemExit("OPENALEX_API_KEY tanımlı değil. Ücretsiz anahtar: https://openalex.org (hesap ayarları).")
    url = f"https://api.openalex.org/{path}?" + urllib.parse.urlencode(params)
    return _get(url, {"Authorization": f"Bearer {key}"})


def openalex_all(path, **params):
    params = dict(params, **{"per-page": 200, "cursor": "*"})
    out = []
    while True:
        d = openalex(path, **params)
        out += d.get("results", [])
        nxt = (d.get("meta") or {}).get("next_cursor")
        if not nxt or not d.get("results"):
            return out
        params["cursor"] = nxt


def crossref_count(doi):
    d = _get("https://api.crossref.org/works/" + urllib.parse.quote(doi))
    return None if d is None else d["message"].get("is-referenced-by-count")


# ----------------------------------------------------------------------------- veri
def short_doi(doi):
    return (doi or "").replace("https://doi.org/", "").lower() or None


def collect():
    works = openalex_all(
        "works", filter=f"author.id:{AUTHOR_ID}",
        select="id,doi,title,publication_year,type,cited_by_count,primary_location")
    rows = []
    for w in works:
        wid = w["id"].rsplit("/", 1)[-1]
        doi = short_doi(w.get("doi"))
        venue = ((w.get("primary_location") or {}).get("source") or {}).get("display_name")
        citing = []
        if w.get("cited_by_count"):
            for c in openalex_all(
                    "works", filter=f"cites:{wid}",
                    select="id,doi,title,publication_year,primary_location,authorships"):
                authors = [((a.get("author") or {}).get("id") or "").rsplit("/", 1)[-1]
                           for a in c.get("authorships") or []]
                citing.append({
                    "id": c["id"].rsplit("/", 1)[-1],
                    "doi": short_doi(c.get("doi")),
                    "title": c.get("title"),
                    "year": c.get("publication_year"),
                    "venue": ((c.get("primary_location") or {}).get("source") or {}).get("display_name"),
                    "self": AUTHOR_ID in authors,
                })
        rows.append({
            "id": wid, "doi": doi, "title": w.get("title"), "year": w.get("publication_year"),
            "type": w.get("type"), "venue": venue,
            "openalex": w.get("cited_by_count") or 0,
            "crossref": crossref_count(doi) if doi else None,
            "citing": sorted(citing, key=lambda c: c["id"]),
        })
        time.sleep(0.2)
    rows.sort(key=lambda r: (-r["openalex"], r["year"] or 0))
    return rows


# ----------------------------------------------------------------------------- hesap
def h_index(counts):
    c = sorted((x or 0 for x in counts), reverse=True)
    return sum(1 for i, v in enumerate(c, 1) if v >= i)


def next_h(rows, key):
    """h+1 için ilk h+1 makalenin her birinin kaç atıf daha alması gerektiği."""
    ranked = sorted(rows, key=lambda r: -(r[key] or 0))
    h = h_index(r[key] for r in ranked)
    need = []
    for r in ranked[: h + 1]:
        gap = (h + 1) - (r[key] or 0)
        if gap > 0:
            need.append((r, gap))
    return h, need


def summary(rows):
    counted = [r for r in rows if r["type"] in COUNTED_TYPES]
    cr = [r for r in counted if r["crossref"] is not None]
    return {
        "yayin_tumu": len(rows), "yayin_sayilan": len(counted),
        "atif_openalex": sum(r["openalex"] for r in counted),
        "atif_crossref": sum(r["crossref"] for r in cr),
        "h_openalex": h_index(r["openalex"] for r in counted),
        "h_crossref": h_index(r["crossref"] for r in cr),
        "kendine_atif": sum(1 for r in counted for c in r["citing"] if c["self"]),
    }


# ----------------------------------------------------------------------------- kayıt
def latest_snapshot(before):
    snaps = sorted(p for p in VERI.glob("20*.json") if p.stem < before)
    return json.loads(snaps[-1].read_text(encoding="utf-8")) if snaps else None


def report(today, rows, s, prev):
    L = [f"# Atıf raporu — {today}", "",
         "Kaynaklar: OpenAlex (atıf sayısı ve atıf yapan yayınlar), Crossref (bağımsız kontrol). "
         "**Resmî rakam değildir;** ÜAK/YÖK için Web of Science'tan teyit edin.", ""]
    ps = prev["ozet"] if prev else None
    def d(k):
        return "" if not ps else f" ({s[k] - ps[k]:+d})"
    L += ["## Özet", "",
          "| Gösterge | OpenAlex | Crossref |", "|---|---|---|",
          f"| Toplam atıf (makale/bildiri) | {s['atif_openalex']}{d('atif_openalex')} | {s['atif_crossref']}{d('atif_crossref')} |",
          f"| h-indeks | {s['h_openalex']}{d('h_openalex')} | {s['h_crossref']}{d('h_crossref')} |", "",
          f"Sayılan yayın: {s['yayin_sayilan']} / {s['yayin_tumu']} kayıt "
          f"(veri seti, tez vb. h-indekse katılmadı). Kendine atıf: {s['kendine_atif']}.",
          "" if prev else "\n_İlk kayıt: karşılaştırma bir sonraki çalıştırmada başlayacak._", ""]

    # yeni atıflar
    L += ["## Son kayıttan bu yana yeni atıflar", ""]
    if not prev:
        L += ["İlk kayıt; yeni atıf karşılaştırması yok.", ""]
    else:
        old = {w["id"]: {c["id"] for c in w["citing"]} for w in prev["yayinlar"]}
        any_new = False
        for r in rows:
            new = [c for c in r["citing"] if c["id"] not in old.get(r["id"], set())]
            if not new:
                continue
            any_new = True
            L += [f"**{r['title']}** ({r['year']}) — {len(new)} yeni", ""]
            for c in new:
                link = f"https://doi.org/{c['doi']}" if c["doi"] else f"https://openalex.org/{c['id']}"
                L.append(f"- [{c['title']}]({link}) — {c['venue'] or 'kaynak yok'}, {c['year']}"
                         + (" · **kendine atıf**" if c["self"] else ""))
            L.append("")
        if not any_new:
            L += [f"Yeni atıf yok (önceki kayıt: {prev['tarih']}).", ""]

    # h eşiği
    L += ["## h-indeks eşik analizi (OpenAlex)", ""]
    counted = [r for r in rows if r["type"] in COUNTED_TYPES]
    h, need = next_h(counted, "openalex")
    L += [f"Şu an h = {h}. h = {h + 1} için şu makalelerin her birinin en az {h + 1} atıfı olmalı:", ""]
    L += [f"- {r['title'][:90]} ({r['year']}): {r['openalex']} atıf → **{g} daha**" for r, g in need] or ["- (hazır)"]
    L.append("")

    # makale tablosu
    L += ["## Yayın bazında atıflar", "",
          "| Yıl | Yayın | Tür | OpenAlex | Crossref | Fark |", "|---|---|---|---|---|---|"]
    for r in rows:
        diff = "" if r["crossref"] is None else f"{r['openalex'] - r['crossref']:+d}"
        title = (r["title"] or "")[:70].replace("|", "/")
        L.append(f"| {r['year']} | {title} | {r['type']} | {r['openalex']} | "
                 f"{'—' if r['crossref'] is None else r['crossref']} | {diff} |")
    L += ["", "_Fark = OpenAlex − Crossref. Büyük farklar eksik/fazla eşleşmeye işaret edebilir._", ""]
    return "\n".join(L)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--kuru", action="store_true", help="kaydetmeden yalnızca raporu bas")
    a = ap.parse_args()
    today = dt.date.today().isoformat()
    rows = collect()
    s = summary(rows)
    prev = latest_snapshot(today)
    text = report(today, rows, s, prev)
    if a.kuru:
        print(text)
        return
    VERI.mkdir(exist_ok=True); RAPOR.mkdir(exist_ok=True)
    (VERI / f"{today}.json").write_text(
        json.dumps({"tarih": today, "ozet": s, "yayinlar": rows}, ensure_ascii=False, indent=1), encoding="utf-8")
    (RAPOR / f"{today}.md").write_text(text, encoding="utf-8")
    (RAPOR / "son.md").write_text(text, encoding="utf-8")
    hist = VERI / "gecmis.csv"
    new = not hist.exists()
    with hist.open("a", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        if new:
            w.writerow(["tarih", *s.keys()])
        w.writerow([today, *s.values()])
    print(text)
    print(f"\nKaydedildi: {VERI / (today + '.json')}, {RAPOR / (today + '.md')}", file=sys.stderr)


if __name__ == "__main__":
    main()
