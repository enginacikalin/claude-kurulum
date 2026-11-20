#!/usr/bin/env python3
"""prompts.chat istem kütüphanesinde yerel arama (çevrimdışı, yalnız standart kütüphane).
Kullanım: python3 ara.py "anahtar kelimeler" [--n 8] [--tam] [--yazilim]
  --tam      : bulunan istemlerin tam metnini yazdır (varsayılan: ilk 300 karakter)
  --yazilim  : yalnızca yazılımcılara yönelik istemler
Veri: prompts.chat (f/prompts.chat, SHA 29417a1), CC0 1.0 kamu malı.
"""
import argparse, csv, os, re, sys
csv.field_size_limit(10**9)
ap = argparse.ArgumentParser()
ap.add_argument("sorgu"); ap.add_argument("--n", type=int, default=8)
ap.add_argument("--tam", action="store_true"); ap.add_argument("--yazilim", action="store_true")
a = ap.parse_args()
yol = os.path.join(os.path.dirname(os.path.abspath(__file__)), "istemler.csv")
terimler = [t for t in re.findall(r"\w+", a.sorgu.lower()) if len(t) > 1]
sonuc = []
with open(yol, encoding="utf-8") as f:
    for r in csv.DictReader(f):
        if a.yazilim and r.get("for_devs") != "TRUE":
            continue
        baslik, metin = r["act"].lower(), r["prompt"].lower()
        puan = sum(3 * baslik.count(t) + min(metin.count(t), 5) for t in terimler)
        if puan and all(t in baslik or t in metin for t in terimler):
            sonuc.append((puan, r))
sonuc.sort(key=lambda x: -x[0])
if not sonuc:
    print("Sonuç yok. Daha genel ya da İngilizce anahtar kelimeler deneyin."); sys.exit(0)
for i, (p, r) in enumerate(sonuc[: a.n], 1):
    m = r["prompt"].strip()
    print(f"### {i}. {r['act']}  (tür: {r['type']}, puan: {p})")
    print(m if a.tam else (m[:300] + ("…" if len(m) > 300 else "")))
    print()
print(f"[{len(sonuc)} eşleşme; ilk {min(a.n, len(sonuc))} gösterildi]")
