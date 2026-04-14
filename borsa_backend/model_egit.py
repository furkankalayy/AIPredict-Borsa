import yfinance as yf
import numpy as np
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense, Dropout
import joblib

print("1. Piyasa Verileri Çekiliyor (10 Yıllık S&P 500 Verisi)...")
# Modele piyasa dinamiklerini öğretmek için en stabil borsa endeksini kullanıyoruz
hisse = yf.Ticker("SPY")
veri = hisse.history(period="10y")

print("2. Teknik İndikatörler Hesaplanıyor...")
# RSI Hesaplama
delta = veri['Close'].diff()
gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
rs = gain / loss
veri['RSI'] = 100 - (100 / (1 + rs))

# Hareketli Ortalamalar (20 ve 50 günlük trendler)
veri['MA20'] = veri['Close'].rolling(window=20).mean()
veri['MA50'] = veri['Close'].rolling(window=50).mean()

# Hesaplanamayan ilk günleri (NaN) temizle
veri.dropna(inplace=True)

print("3. Yapay Zeka İçin 5 Farklı Duyu (Özellik) Ölçeklendiriliyor...")
# Eski model sadece 'Close' okuyordu. Yeni model 5 farklı veriyi okuyacak!
ozellikler = ['Close', 'Volume', 'RSI', 'MA20', 'MA50']
veri_seti = veri[ozellikler].values

# Gerçek tahminler yapabilmek için scaler'ı kaydetmemiz ÇOK ÖNEMLİ
scaler = MinMaxScaler(feature_range=(0, 1))
olcekli_veri = scaler.fit_transform(veri_seti)
joblib.dump(scaler, 'gelismis_scaler.gz') # Tahmin yaparken bunu kullanacağız

# 60 birimlik hafıza pencereleri oluşturma
X = []
y = []
zaman_adimi = 60

for i in range(zaman_adimi, len(olcekli_veri)):
    X.append(olcekli_veri[i-zaman_adimi:i]) # 60 günün 5 farklı özelliği
    y.append(olcekli_veri[i, 0]) # Hedef: Yarının 'Close' fiyatı

X, y = np.array(X), np.array(y)

print("4. Gelişmiş Derin Öğrenme Modeli İnşa Ediliyor...")
model = Sequential()

# 1. Gelişmiş LSTM Katmanı (Çok daha fazla nöron)
model.add(LSTM(units=100, return_sequences=True, input_shape=(X.shape[1], X.shape[2])))
model.add(Dropout(0.2)) # Aşırı ezberlemeyi (overfitting) önler

# 2. Derin LSTM Katmanı
model.add(LSTM(units=100, return_sequences=False))
model.add(Dropout(0.2))

# Çıkış Katmanları
model.add(Dense(units=50))
model.add(Dense(units=1)) # Tek bir fiyat tahmini

model.compile(optimizer='adam', loss='mean_squared_error')

print("5. Model Eğitiliyor... (Bilgisayarının hızına göre 1-3 dakika sürebilir. Lütfen bekleyin.)")
# Modeli geçmiş verilerle sınav yapıyoruz (Epoch=50 kere baştan sona çalışacak)
model.fit(X, y, epochs=50, batch_size=32, validation_split=0.1)

print("6. Yeni Beyin Kaydediliyor...")
model.save('gelismis_borsa_modeli.h5')
print("\n🎉 HARİKA! 'gelismis_borsa_modeli.h5' ve 'gelismis_scaler.gz' başarıyla oluşturuldu!")