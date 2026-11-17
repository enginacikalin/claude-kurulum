# Atıf takibi (OpenAlex + Crossref)

Yayınlarınızın atıflarını ayda bir kaydeder ve bir önceki ayla karşılaştırır.

- **Özet:** toplam atıf ve h-indeks, OpenAlex ve Crossref için ayrı ayrı, bir önceki aya göre değişimiyle
- **Yeni atıflar:** hangi makalenize, hangi yayından, ne zaman atıf geldiği; kendine atıflar işaretli
- **h-indeks eşiği:** bir sonraki h için hangi makalenin kaç atıf daha alması gerektiği
- **Kaynak farkları:** OpenAlex ile Crossref arasındaki farklar

> **Resmî rakam değildir.** ÜAK ve YÖK başvuruları için Web of Science'tan teyit edin. Web of Science API anahtarı gelince bu araca eklenecek.

## Çalıştırma

```bash
export OPENALEX_API_KEY=...   # ücretsiz: openalex.org hesap ayarları
python3 atif_takip.py          # kaydeder: veri/TARİH.json, veri/gecmis.csv, rapor/TARİH.md, rapor/son.md
python3 atif_takip.py --kuru   # kaydetmeden yalnızca raporu gösterir
```

- Ağ erişimi: `api.openalex.org` ve `api.crossref.org`
- **API anahtarını asla bu depoya yazmayın; depo herkese açık.** Anahtarı ortam değişkeninde ya da bulut ortamının *Environment variables* alanında tutun.

## Notlar

- h-indekse makale, derleme, bildiri, kitap ve kitap bölümü girer. Tez ve veri seti ayrı listelenir.
- OpenAlex aynı yayının Türkçe ve İngilizce sürümlerini ayrı kayıt olarak tutabilir; tablodan kontrol edin.
- `veri/` klasöründeki kayıtlar yalnızca zaten herkese açık olan atıf bilgilerinden oluşur.
