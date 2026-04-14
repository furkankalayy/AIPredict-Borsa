# 🚀 AI Borsa Pro

Yapay Zeka (Derin Öğrenme) ve Teknik Analiz algoritmalarıyla güçlendirilmiş, gerçek zamanlı borsa ve kripto para tahmin / portföy yönetimi uygulaması. 

Bu proje, gücünü Python tabanlı bir Yapay Zeka sunucusundan alan ve kullanıcıya Flutter ile geliştirilmiş kusursuz bir mobil deneyim sunan **Monorepo** mimarisine sahiptir.

## ✨ Öne Çıkan Özellikler

* 🤖 **Yapay Zeka (LSTM) Tahminleri:** Geçmiş 60 zaman dilimi, işlem hacmi ve hareketli ortalamaları inceleyerek gelecek fiyat yönünü tahmin eden TensorFlow/Keras modeli.
* 📊 **Canlı Teknik Tarayıcı (Screener):** Yahoo Finance üzerinden saniyelik veri çekerek RSI, Volatilite ve Yüzdelik Değişim metriklerine göre otomatik "AL/SAT" sinyalleri üreten algoritma.
* 📱 **Kusursuz Kullanıcı Deneyimi:** Flutter ile geliştirilmiş, iç içe geçmiş grid sistemleri, dinamik arama ve dokunmatik detaylı grafikler (fl_chart).
* 🔒 **Kimlik Doğrulama & Portföy:** Kullanıcı hesap oluşturma sistemi ve kişiselleştirilmiş "Favoriler" veritabanı.
* 🎓 **Bilgi Akademisi:** Finansal okuryazarlığı artırmak için entegre edilmiş, RSI, Hacim ve Volatilite gibi terimleri açıklayan eğitim modülü.

---

## 🏗 Mimari ve Klasör Yapısı

Proje, iki ana bileşenden oluşmaktadır:

* **`/borsa-backend` (Python / FastAPI):** Canlı verileri çeken, makine öğrenmesi modelini çalıştıran ve algoritmik filtreleme yapan API sunucusu.
* **`/borsa_app` (Flutter / Dart):** API'den gelen karmaşık finansal verileri modern ve akıcı bir arayüzle kullanıcıya sunan mobil uygulama.

### Kullanılan Teknolojiler
* **Frontend:** Flutter, Dart, fl_chart, http
* **Backend:** Python, FastAPI, TensorFlow (Keras), yfinance, Pandas, NumPy, scikit-learn
* **Veritabanı:** JSON tabanlı yerel kimlik doğrulama sistemi

---

## 🚀 Kurulum ve Çalıştırma

Projeyi kendi bilgisayarınızda çalıştırmak için aşağıdaki adımları izleyin.

### 1. Sunucuyu (Backend) Başlatma
Terminalinizi açın ve `borsa-backend` klasörüne gidin:

cd borsa-backend

# Gerekli kütüphaneleri yükleyin
pip install fastapi uvicorn yfinance tensorflow pandas numpy scikit-learn pydantic

# FastAPI sunucusunu başlatın
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload

*(Sunucu varsayılan olarak http://localhost:8000 adresinde çalışacaktır.)*

### 2. Mobil Uygulamayı (Frontend) Başlatma
Yeni bir terminal sekmesi açın ve `borsa_app` klasörüne gidin:

cd borsa_app

# Gerekli paketleri indirin
flutter pub get

# Uygulamayı bağlı bir cihaza veya emülatöre kurun
flutter run

---

## 🧠 Çalışma Mantığı ve Güvenlik Ağları
Uygulama sadece yapay zeka modelinin tahminlerine körü körüne güvenmez. Python sunucusuna entegre edilmiş **"Gerçeklik Filtresi"** sayesinde:
* Hisse "Aşırı Alım" (RSI > 65) bölgesindeyse, model yükseliş öngörse bile algoritma bunu aşağı yönlü revize eder.
* "Volatilite Kelepçesi", hissenin o anki standart sapmasını hesaplayarak yapay zekanın mantıksız ve aşırı uç tahminler yapmasını engeller.

---
*Geliştirici Notu: Bu proje finansal bir tavsiye sistemi değil, teknik analiz ve makine öğrenmesi konseptlerinin mobil platforma nasıl entegre edilebileceğini gösteren bir mühendislik çalışmasıdır.*
