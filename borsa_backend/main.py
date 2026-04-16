from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import yfinance as yf
import numpy as np
import pandas as pd
from tensorflow.keras.models import load_model
import joblib
import json
import os

app = FastAPI(title="Profesyonel Borsa Yapay Zekası")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

model = load_model('gelismis_borsa_modeli.h5')
scaler = joblib.load('gelismis_scaler.gz')

# --- VERİTABANI MANTIGI (KULLANICI KAYITLARI) ---
DB_DOSYASI = "kullanicilar.json"


def db_oku():
    if not os.path.exists(DB_DOSYASI):
        return {}
    with open(DB_DOSYASI, "r", encoding="utf-8") as f:
        return json.load(f)


def db_yaz(veri):
    with open(DB_DOSYASI, "w", encoding="utf-8") as f:
        json.dump(veri, f, indent=4)


class KayitFormu(BaseModel):
    ad: str
    email: str
    sifre: str


class GirisFormu(BaseModel):
    email: str
    sifre: str


class SifreDegistirFormu(BaseModel):
    email: str
    eski_sifre: str
    yeni_sifre: str


class AdGuncelleFormu(BaseModel):
    email: str
    yeni_ad: str


@app.post("/kayit")
def kayit_ol(form: KayitFormu):
    db = db_oku()
    if form.email in db:
        raise HTTPException(status_code=400, detail="Bu e-posta adresi zaten kullanılıyor!")

    db[form.email] = {
        "ad": form.ad,
        "sifre": form.sifre,
        "favoriler": []  # İleride favorileri buluta kaydetmek için altyapı
    }
    db_yaz(db)
    return {"mesaj": "Kayıt Başarılı", "ad": form.ad}


@app.post("/giris")
def giris_yap(form: GirisFormu):
    db = db_oku()
    kullanici = db.get(form.email)

    if not kullanici or kullanici["sifre"] != form.sifre:
        raise HTTPException(status_code=401, detail="E-posta veya şifre hatalı!")

    return {"mesaj": "Giriş Başarılı", "ad": kullanici["ad"]}


@app.post("/sifre-degistir")
def sifre_degistir(form: SifreDegistirFormu):
    db = db_oku()
    kullanici = db.get(form.email)

    if not kullanici:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")

    if kullanici["sifre"] != form.eski_sifre:
        raise HTTPException(status_code=401, detail="Mevcut şifre yanlış.")

    if len(form.yeni_sifre.strip()) < 6:
        raise HTTPException(status_code=400, detail="Yeni şifre en az 6 karakter olmalı.")

    kullanici["sifre"] = form.yeni_sifre.strip()
    db[form.email] = kullanici
    db_yaz(db)
    return {"mesaj": "Şifre güncellendi."}


@app.post("/ad-guncelle")
def ad_guncelle(form: AdGuncelleFormu):
    db = db_oku()
    kullanici = db.get(form.email)

    if not kullanici:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")

    yeni_ad = form.yeni_ad.strip()
    if not yeni_ad:
        raise HTTPException(status_code=400, detail="Görünen ad boş olamaz.")

    kullanici["ad"] = yeni_ad
    db[form.email] = kullanici
    db_yaz(db)
    return {"mesaj": "Ad güncellendi.", "ad": yeni_ad}


# --- YAPAY ZEKA TAHMİN MANTIGI ---
@app.get("/tahmin/{hisse_kodu}")
def hisse_tahmin_getir(hisse_kodu: str, zaman_dilimi: str = "1A"):
    hisse_kodu = hisse_kodu.upper()
    hisse = yf.Ticker(hisse_kodu)

    zaman_ayarlari = {
        "1G": {"fetch_period": "5d", "interval": "5m", "gosterilecek_nokta": 78, "max_degisim": 0.002},
        "1H": {"fetch_period": "1mo", "interval": "15m", "gosterilecek_nokta": 130, "max_degisim": 0.005},
        "1A": {"fetch_period": "6mo", "interval": "1d", "gosterilecek_nokta": 30, "max_degisim": 0.02},
        "1Y": {"fetch_period": "2y", "interval": "1d", "gosterilecek_nokta": 252, "max_degisim": 0.05},
        "5Y": {"fetch_period": "10y", "interval": "1wk", "gosterilecek_nokta": 260, "max_degisim": 0.10}
    }

    secim = zaman_ayarlari.get(zaman_dilimi, zaman_ayarlari["1A"])
    veri = hisse.history(period=secim["fetch_period"], interval=secim["interval"])

    if veri.empty or len(veri) < 120:
        raise HTTPException(status_code=404, detail=f"{hisse_kodu} için yeterli geçmiş veri yok.")

    delta = veri['Close'].diff()
    gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
    rs = gain / loss
    veri['RSI'] = 100 - (100 / (1 + rs))

    veri['MA20'] = veri['Close'].rolling(window=20).mean()
    veri['MA50'] = veri['Close'].rolling(window=50).mean()
    veri.dropna(inplace=True)

    ozellikler = ['Close', 'Volume', 'RSI', 'MA20', 'MA50']
    veri_seti = veri[ozellikler].values
    olcekli_veri = scaler.transform(veri_seti)

    son_60_birim = olcekli_veri[-60:]
    X_test = np.array([son_60_birim])
    ham_tahmin_olcekli = model.predict(X_test)[0][0]

    dummy_array = np.zeros((1, 5))
    dummy_array[0, 0] = ham_tahmin_olcekli
    saf_tahmin = scaler.inverse_transform(dummy_array)[0][0]

    en_guncel_fiyat = veri['Close'].iloc[-1]
    nihai_tahmin = saf_tahmin
    son_rsi = veri['RSI'].iloc[-1]

    if pd.notna(son_rsi):
        if son_rsi > 65:
            if nihai_tahmin > en_guncel_fiyat:
                nihai_tahmin = en_guncel_fiyat * 0.995
            else:
                nihai_tahmin = nihai_tahmin * 0.99
        elif son_rsi < 50:
            if nihai_tahmin < en_guncel_fiyat: nihai_tahmin = en_guncel_fiyat * 1.005

    tolerans = secim["max_degisim"]
    max_fiyat = en_guncel_fiyat * (1 + tolerans)
    min_fiyat = en_guncel_fiyat * (1 - tolerans)

    if nihai_tahmin > max_fiyat:
        nihai_tahmin = max_fiyat
    elif nihai_tahmin < min_fiyat:
        nihai_tahmin = min_fiyat

    limit = secim["gosterilecek_nokta"]
    gosterilecek_veri = veri.tail(limit)
    gosterilecek_gecmis = gosterilecek_veri['Close'].tolist()

    if zaman_dilimi == "1G":
        zaman_format = "%H:%M"           # intraday: sadece saat yeterli
    elif zaman_dilimi == "1H":
        zaman_format = "%Y-%m-%d %H:%M"  # haftalık: gün + saat
    elif zaman_dilimi == "1A":
        zaman_format = "%d %b"
    elif zaman_dilimi == "1Y":
        zaman_format = "%d %b %Y"
    else:
        zaman_format = "%b %Y"

    gecmis_zaman_verisi = gosterilecek_veri.index.strftime(zaman_format).tolist()
    hedef_metinleri = {"1G": "5 Dk Sonrası", "1H": "15 Dk Sonrası", "1A": "Yarın", "1Y": "Gelecek Hafta",
                       "5Y": "Gelecek Ay"}

    return {
        "hisse": hisse_kodu,
        "son_fiyat": round(float(en_guncel_fiyat), 2),
        "yarinki_tahmin": round(float(nihai_tahmin), 2),
        "hedef_zaman": hedef_metinleri.get(zaman_dilimi, "Yarın"),
        "rsi_durumu": round(float(son_rsi), 2),
        "gecmis_grafik_verisi": [round(float(fiyat), 2) for fiyat in gosterilecek_gecmis],
        "gecmis_zaman_verisi": gecmis_zaman_verisi
    }


# --- HABERLER ---
from datetime import datetime, timezone

def _haber_isle(h: dict) -> dict | None:
    """Yeni yfinance .news formatını (content nested) parse eder."""
    try:
        c = h.get("content") or h  # yeni format: content nested; eski: düz
        title = c.get("title") or h.get("title", "")
        if not title:
            return None

        # URL
        click = c.get("clickThroughUrl") or {}
        canon = c.get("canonicalUrl") or {}
        url = (click.get("url") or canon.get("url")
               or h.get("link") or h.get("url") or "")

        # Publisher
        prov = c.get("provider") or {}
        kaynak = (prov.get("displayName") or prov.get("source")
                  or h.get("publisher") or "")

        # Zaman → Unix timestamp
        zaman = 0
        pub = c.get("pubDate") or ""
        if pub:
            try:
                dt = datetime.fromisoformat(pub.replace("Z", "+00:00"))
                zaman = int(dt.timestamp())
            except Exception:
                pass
        if not zaman:
            zaman = h.get("providerPublishTime", 0)

        # Thumbnail
        resim = ""
        thumb = c.get("thumbnail") or h.get("thumbnail") or {}
        resim = (thumb.get("originalUrl") or thumb.get("url") or "")
        if not resim:
            resolutions = thumb.get("resolutions") or []
            if resolutions:
                resim = resolutions[0].get("url", "")

        return {"baslik": title, "kaynak": kaynak,
                "url": url, "zaman": zaman, "resim": resim}
    except Exception:
        return None

@app.get("/haberler")
def haberler_getir():
    """Popüler hisse ve kripto haberlerini döner (yfinance .news)."""
    kaynaklar = ["AAPL", "TSLA", "NVDA", "MSFT", "BTC-USD", "ETH-USD", "SPY"]
    toplam = []
    goruldu = set()
    for sembol in kaynaklar:
        try:
            for h in (yf.Ticker(sembol).news or [])[:3]:
                item = _haber_isle(h)
                if not item or not item["url"] or item["url"] in goruldu:
                    continue
                goruldu.add(item["url"])
                toplam.append(item)
        except Exception:
            pass
    toplam.sort(key=lambda x: x["zaman"], reverse=True)
    return {"haberler": toplam[:12]}


@app.get("/haberler/{hisse_kodu}")
def hisse_haberleri(hisse_kodu: str):
    """Belirli bir hisseye ait haberleri döner."""
    sonuc = []
    goruldu = set()
    try:
        for h in (yf.Ticker(hisse_kodu.upper()).news or [])[:8]:
            item = _haber_isle(h)
            if not item or not item["url"] or item["url"] in goruldu:
                continue
            goruldu.add(item["url"])
            sonuc.append(item)
    except Exception:
        pass
    return {"haberler": sonuc}


# --- TARAYICI MANTIGI ---
@app.get("/tarayici")
def tarayici_getir(pazar: str, kategori: str):
    if "NASDAQ" in pazar:
        havuz = {
            "AAPL": {"ad": "Apple Inc.", "etiket": "guvenli"}, "MSFT": {"ad": "Microsoft", "etiket": "guvenli"},
            "NVDA": {"ad": "NVIDIA", "etiket": "agresif"}, "KO": {"ad": "Coca-Cola", "etiket": "temettu"},
            "PEP": {"ad": "PepsiCo", "etiket": "temettu"}, "XOM": {"ad": "Exxon Mobil", "etiket": "temettu"},
            "JNJ": {"ad": "Johnson & Johnson", "etiket": "guvenli"}, "TSLA": {"ad": "Tesla", "etiket": "agresif"},
            "AMZN": {"ad": "Amazon", "etiket": "guvenli"}, "META": {"ad": "Meta Platforms", "etiket": "agresif"}
        }
    elif "BİST" in pazar:
        havuz = {
            "THYAO.IS": {"ad": "Türk Hava Yolları", "etiket": "guvenli"},
            "TUPRS.IS": {"ad": "Tüpraş", "etiket": "temettu"},
            "KCHOL.IS": {"ad": "Koç Holding", "etiket": "guvenli"},
            "FROTO.IS": {"ad": "Ford Otosan", "etiket": "temettu"},
            "DOAS.IS": {"ad": "Doğuş Otomotiv", "etiket": "temettu"},
            "ISCTR.IS": {"ad": "İş Bankası (C)", "etiket": "guvenli"},
            "SASA.IS": {"ad": "Sasa Polyester", "etiket": "agresif"}, "HEKTS.IS": {"ad": "Hektaş", "etiket": "agresif"},
            "EREGL.IS": {"ad": "Erdemir", "etiket": "temettu"}, "ASELS.IS": {"ad": "Aselsan", "etiket": "guvenli"}
        }
    else:
        havuz = {
            "BTC-USD": {"ad": "Bitcoin", "etiket": "guvenli"}, "ETH-USD": {"ad": "Ethereum", "etiket": "guvenli"},
            "SOL-USD": {"ad": "Solana", "etiket": "agresif"}, "BNB-USD": {"ad": "BNB", "etiket": "guvenli"},
            "DOGE-USD": {"ad": "Dogecoin", "etiket": "agresif"}, "AVAX-USD": {"ad": "Avalanche", "etiket": "agresif"},
            "XRP-USD": {"ad": "XRP Ripple", "etiket": "temettu"}
        }

    semboller = list(havuz.keys())
    veri = yf.download(semboller, period="1mo", progress=False)
    analiz_edilenler = []

    for kod in semboller:
        try:
            kapanislar = veri['Close'][kod].dropna()
            hacimler = veri['Volume'][kod].dropna()
            if len(kapanislar) < 15: continue

            guncel_fiyat = float(kapanislar.iloc[-1])
            onceki_fiyat = float(kapanislar.iloc[-2])
            son_hacim = float(hacimler.iloc[-1])

            degisim = ((guncel_fiyat - onceki_fiyat) / onceki_fiyat) * 100
            delta = kapanislar.diff()
            gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
            loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
            rs = gain / loss
            rsi = float(100 - (100 / (1 + rs)).iloc[-1])

            analiz_edilenler.append({
                "symbol": kod, "shortname": havuz[kod]["ad"], "etiket": havuz[kod]["etiket"],
                "rsi": rsi, "degisim": degisim, "hacim": son_hacim
            })
        except Exception as e:
            continue

    secilenler = []

    if "AL" in kategori:
        filtrelenmis = [h for h in analiz_edilenler if h["rsi"] < 50]
        secilenler = sorted(filtrelenmis, key=lambda x: x["rsi"])[:10]
    elif "SAT" in kategori:
        filtrelenmis = [h for h in analiz_edilenler if h["rsi"] > 65]
        secilenler = sorted(filtrelenmis, key=lambda x: x["rsi"], reverse=True)[:10]
    elif "Batmayacak" in kategori:
        filtrelenmis = [h for h in analiz_edilenler if h["etiket"] == "guvenli"]
        secilenler = sorted(filtrelenmis, key=lambda x: x["degisim"], reverse=True)[:10]
    elif "Temettü" in kategori:
        filtrelenmis = [h for h in analiz_edilenler if h["etiket"] == "temettu"]
        secilenler = sorted(filtrelenmis, key=lambda x: x["hacim"], reverse=True)[:10]
    elif "Kazananlar" in kategori:
        filtrelenmis = [h for h in analiz_edilenler if h["degisim"] > 0]
        secilenler = sorted(filtrelenmis, key=lambda x: x["degisim"], reverse=True)[:10]
    elif "Kaybedenler" in kategori:
        filtrelenmis = [h for h in analiz_edilenler if h["degisim"] < 0]
        secilenler = sorted(filtrelenmis, key=lambda x: x["degisim"])[:10]
    else:
        secilenler = sorted(analiz_edilenler, key=lambda x: x["hacim"], reverse=True)[:10]

    if not secilenler: return {"sonuclar": []}
    son_paket = [{"symbol": h["symbol"], "shortname": h["shortname"]} for h in secilenler]
    return {"sonuclar": son_paket}