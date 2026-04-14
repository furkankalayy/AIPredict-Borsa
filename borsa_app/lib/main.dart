import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const BorsaApp());
}

class BorsaApp extends StatelessWidget {
  const BorsaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Borsa Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
        colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent),
      ),
      home: const LoginEkrani(),
    );
  }
}

// --- 1. EKRAN: DİNAMİK GİRİŞ / KAYIT SAYFASI ---
class LoginEkrani extends StatefulWidget {
  const LoginEkrani({super.key});

  @override
  State<LoginEkrani> createState() => _LoginEkraniState();
}

class _LoginEkraniState extends State<LoginEkrani> {
  bool kayitModu = false;
  bool yukleniyor = false;

  TextEditingController adKontrolcusu = TextEditingController();
  TextEditingController emailKontrolcusu = TextEditingController();
  TextEditingController sifreKontrolcusu = TextEditingController();

  Future<void> authIslemi() async {
    if (emailKontrolcusu.text.isEmpty || sifreKontrolcusu.text.isEmpty || (kayitModu && adKontrolcusu.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm alanları doldurun."), backgroundColor: Colors.orange));
      return;
    }

    setState(() => yukleniyor = true);

    // İşleme göre doğru Python adresine istek atıyoruz
    String url = kayitModu ? "http://192.168.1.151:8000/kayit" : "http://192.168.1.151:8000/giris";

    Map<String, String> body = {
      "email": emailKontrolcusu.text.trim(),
      "sifre": sifreKontrolcusu.text.trim(),
    };
    if (kayitModu) body["ad"] = adKontrolcusu.text.trim();

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      // Türkçe karakter desteği için utf8.decode kullandık
      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        String kullaniciAdi = data["ad"];
        if (kayitModu) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Aramıza hoş geldin, $kullaniciAdi!"), backgroundColor: Colors.green));
        }
        // Giriş veya kayıt başarılıysa Ana Sayfaya gönder
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AnaSayfa(kullaniciAdi: kullaniciAdi)));
        }
      } else {
        // Şifre yanlışsa veya email varsa Python'dan gelen hata mesajını göster
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data["detail"], style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sunucuya bağlanılamadı. Python çalışıyor mu?"), backgroundColor: Colors.redAccent));
    }

    setState(() => yukleniyor = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0A0E21), Color(0xFF1D2136)]),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Colors.cyanAccent.withOpacity(0.1),
                    boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: const Icon(Icons.show_chart, size: 60, color: Colors.cyanAccent),
                ),
                const SizedBox(height: 30),
                Text(kayitModu ? "Hesap Oluştur" : "AI Borsa Pro'ya Giriş Yap", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 30),

                // Kayıt modu açıksa Ad Soyad kutusunu göster
                if (kayitModu) ...[
                  TextField(
                    controller: adKontrolcusu,
                    decoration: InputDecoration(hintText: "Ad Soyad", prefixIcon: const Icon(Icons.person, color: Colors.grey), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: emailKontrolcusu,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(hintText: "E-posta", prefixIcon: const Icon(Icons.email, color: Colors.grey), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sifreKontrolcusu,
                  obscureText: true,
                  decoration: InputDecoration(hintText: "Şifre", prefixIcon: const Icon(Icons.lock, color: Colors.grey), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 30),

                // GİRİŞ / KAYIT BUTONU
                GestureDetector(
                  onTap: yukleniyor ? null : authIslemi,
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                      boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Center(
                      child: yukleniyor
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : Text(kayitModu ? "Kayıt Ol" : "Giriş Yap", style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // MOD DEĞİŞTİRME BUTONU
                TextButton(
                  onPressed: () {
                    setState(() {
                      kayitModu = !kayitModu;
                      // Formu temizle
                      adKontrolcusu.clear(); emailKontrolcusu.clear(); sifreKontrolcusu.clear();
                    });
                  },
                  child: Text(kayitModu ? "Zaten hesabın var mı? Giriş Yap" : "Hesabın yok mu? Kayıt Ol", style: const TextStyle(color: Colors.cyanAccent)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 2. EKRAN: ANA SAYFA (Alt Menü Yönetimi) ---
class AnaSayfa extends StatefulWidget {
  final String kullaniciAdi;
  const AnaSayfa({super.key, required this.kullaniciAdi});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _aktifSekme = 0;
  Set<String> favoriHisseler = {"TSLA", "AAPL"};

  void _favoriDegistir(String hisseKodu) {
    setState(() {
      if (favoriHisseler.contains(hisseKodu)) favoriHisseler.remove(hisseKodu);
      else favoriHisseler.add(hisseKodu);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> ekranlar = [
      KesfetEkrani(favoriHisseler: favoriHisseler, favoriDegistir: _favoriDegistir),
      FavorilerEkrani(favoriHisseler: favoriHisseler, favoriDegistir: _favoriDegistir),
      const AkademiEkrani(),
    ];

    final List<String> basliklar = ["Hoş Geldin, ${widget.kullaniciAdi}", "Portföyüm", "Bilgi Akademisi"];

    return Scaffold(
      appBar: AppBar(title: Text(basliklar[_aktifSekme], style: const TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: ekranlar[_aktifSekme],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)]),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF1D2136), selectedItemColor: Colors.cyanAccent, unselectedItemColor: Colors.grey, currentIndex: _aktifSekme,
          onTap: (index) => setState(() => _aktifSekme = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Keşfet"),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: "Favoriler"),
            BottomNavigationBarItem(icon: Icon(Icons.school), label: "Akademi"),
          ],
        ),
      ),
    );
  }
}

// --- AKADEMİ EKRANI ---
class AkademiEkrani extends StatelessWidget {
  const AkademiEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _bilgiKarti("Yapay Zeka (LSTM) Nasıl Çalışır?", Icons.memory, Colors.blueAccent, "Modelimiz sadece son fiyata bakmaz. Geçmiş 60 zaman dilimindeki fiyat hareketlerini, işlem hacmini ve hareketli ortalamaları inceleyerek bir sonraki mumun nereye gidebileceğini matematiksel olarak tahmin eder."),
        _bilgiKarti("RSI (Göreceli Güç Endeksi) Nedir?", Icons.speed, const Color(0xFFB026FF), "RSI, bir hissenin yorgunluğunu ölçer.\n\n• RSI 70'in üzerindeyse: Hisse çok fazla alınmış, şişmiş ve yorulmuştur (SAT sinyali).\n• RSI 30'un altındaysa: Hisse çok fazla satılmış, cezalandırılmış ve ucuzlamıştır (AL sinyali)."),
        _bilgiKarti("Volatilite (Oynaklık) Kelepçesi", Icons.lock_outline, Colors.greenAccent, "Bazen yapay zeka sadece matematiğe odaklanıp 'Bu hisse 5 dakikada %20 artacak' gibi hayalperest tahminler yapabilir. Sisteme eklediğimiz volatilite kelepçesi, hissenin o anki dalgalanma kapasitesini hesaplar ve yapay zekanın hezeyanlarını gerçekçi piyasa sınırları içine çeker."),
        _bilgiKarti("İşlem Hacmi Neden Önemli?", Icons.waves, Colors.cyanAccent, "Bir hissenin fiyatı artıyor olabilir, ancak bu artış düşük bir 'hacim' ile gerçekleşiyorsa sahtedir (Tuzak). Fiyat artarken arkasında büyük bir para girişi (hacim) varsa, bu gerçek bir yükseliş trendidir."),
      ],
    );
  }

  Widget _bilgiKarti(String baslik, IconData ikon, Color renk, String icerik) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: const Color(0xFF1D2136), borderRadius: BorderRadius.circular(15), border: Border.all(color: renk.withOpacity(0.3), width: 1)),
      child: ExpansionTile(
        leading: Icon(ikon, color: renk, size: 30), title: Text(baslik, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)), iconColor: renk, collapsedIconColor: Colors.grey,
        children: [Padding(padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16), child: Text(icerik, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)))],
      ),
    );
  }
}

// --- 3. EKRAN: KEŞFET ---
class KesfetEkrani extends StatefulWidget {
  final Set<String> favoriHisseler;
  final Function(String) favoriDegistir;
  const KesfetEkrani({super.key, required this.favoriHisseler, required this.favoriDegistir});
  @override State<KesfetEkrani> createState() => _KesfetEkraniState();
}

class _KesfetEkraniState extends State<KesfetEkrani> {
  TextEditingController aramaKontrolcusu = TextEditingController();
  List<dynamic> aramaSonuclari = [];
  bool araniyor = false;
  String? seciliPazar;
  String? aktifFiltre;

  final List<Map<String, dynamic>> anaPazarlar = [
    {"baslik": "NASDAQ (ABD)", "ikon": Icons.business, "renk": Colors.blueAccent},
    {"baslik": "BİST 100 (TR)", "ikon": Icons.account_balance, "renk": Colors.redAccent},
    {"baslik": "Kripto Varlıklar", "ikon": Icons.currency_bitcoin, "renk": Colors.orangeAccent},
  ];

  final List<Map<String, dynamic>> altFiltreler = [
    {"baslik": "Yapay Zeka 'AL'", "ikon": Icons.auto_awesome, "renk": const Color(0xFFB026FF)},
    {"baslik": "Yapay Zeka 'SAT'", "ikon": Icons.trending_down, "renk": Colors.pinkAccent},
    {"baslik": "Asla Batmayacaklar", "ikon": Icons.shield, "renk": Colors.blueAccent},
    {"baslik": "Temettü Şampiyonları", "ikon": Icons.savings, "renk": Colors.tealAccent},
    {"baslik": "Günün Kazananları", "ikon": Icons.keyboard_double_arrow_up, "renk": Colors.greenAccent},
    {"baslik": "Günün Kaybedenleri", "ikon": Icons.keyboard_double_arrow_down, "renk": Colors.deepOrangeAccent},
  ];

  Future<void> hisseAra(String sorgu) async {
    if (sorgu.trim().isEmpty) { setState(() { aramaSonuclari = []; aktifFiltre = null; }); return; }
    setState(() { araniyor = true; aktifFiltre = "Arama Sonuçları"; });

    final String url = "https://query2.finance.yahoo.com/v1/finance/search?q=$sorgu&quotesCount=100&newsCount=0";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() { aramaSonuclari = data['quotes'].where((item) => item['quoteType'] == 'EQUITY' || item['quoteType'] == 'ETF' || item['quoteType'] == 'CRYPTOCURRENCY').toList(); araniyor = false; });
      }
    } catch (e) { setState(() => araniyor = false); }
  }

  Future<void> kategoriGetir(String pazar, String kategori) async {
    setState(() { araniyor = true; aramaSonuclari = []; aktifFiltre = kategori; });
    final String url = "http://192.168.1.151:8000/tarayici?pazar=$pazar&kategori=$kategori";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() { aramaSonuclari = data['sonuclar']; araniyor = false; });
      } else { setState(() => araniyor = false); }
    } catch (e) { setState(() => araniyor = false); }
  }

  void geriDon() {
    setState(() {
      if (aktifFiltre != null || aramaKontrolcusu.text.isNotEmpty) { aramaKontrolcusu.clear(); aramaSonuclari = []; aktifFiltre = null; }
      else if (seciliPazar != null) { seciliPazar = null; }
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    bool geriButonuGoster = aramaKontrolcusu.text.isNotEmpty || aktifFiltre != null || seciliPazar != null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: aramaKontrolcusu, onChanged: hisseAra,
            decoration: InputDecoration(
              hintText: seciliPazar == null ? "Hisse veya Kripto Ara..." : "$seciliPazar İçinde Ara...",
              prefixIcon: geriButonuGoster ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent), onPressed: geriDon) : const Icon(Icons.search, color: Colors.cyanAccent),
              suffixIcon: aramaKontrolcusu.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { aramaKontrolcusu.clear(); hisseAra(""); }) : null,
              filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ),
        if (seciliPazar != null && aktifFiltre == null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text("$seciliPazar Kategorileri", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
        if (aktifFiltre != null && aktifFiltre != "Arama Sonuçları") Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(aktifFiltre!, style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold))),

        Expanded(
          child: araniyor ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
              : aktifFiltre != null
              ? (aramaSonuclari.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 60, color: Colors.grey.withOpacity(0.5)), const SizedBox(height: 16), const Text("Uygun hisse bulunamadı.", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text("Şu anki piyasa koşulları bu filtreyi\nkarşılayan bir sinyal üretmiyor.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14))]))
              : ListView.builder(itemCount: aramaSonuclari.length, itemBuilder: (context, index) => _hisseKarti(aramaSonuclari[index]['symbol'], aramaSonuclari[index]['shortname'] ?? "Bilinmeyen")))
              : seciliPazar != null
              ? _gridOlustur(altFiltreler, (baslik) => kategoriGetir(seciliPazar!, baslik))
              : _gridOlustur(anaPazarlar, (baslik) => setState(() => seciliPazar = baslik), caprazSayi: 1, oran: 3.5),
        ),
      ],
    );
  }

  Widget _gridOlustur(List<Map<String, dynamic>> liste, Function(String) onTapped, {int caprazSayi = 2, double oran = 1.2}) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: caprazSayi, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: oran),
      itemCount: liste.length,
      itemBuilder: (context, index) {
        final item = liste[index];
        return GestureDetector(
          onTap: () => onTapped(item["baslik"]),
          child: Container(
            decoration: BoxDecoration(color: const Color(0xFF1D2136), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))], border: Border.all(color: item["renk"].withOpacity(0.3), width: 1)),
            child: caprazSayi == 1
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item["ikon"], size: 40, color: item["renk"]), const SizedBox(width: 20), Text(item["baslik"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))])
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item["ikon"], size: 42, color: item["renk"]), const SizedBox(height: 12), Text(item["baslik"], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))]),
          ),
        );
      },
    );
  }

  Widget _hisseKarti(String kod, String ad) {
    bool favoriMi = widget.favoriHisseler.contains(kod);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF1D2136), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(kod, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        subtitle: Text(ad, style: const TextStyle(color: Colors.grey)),
        trailing: IconButton(icon: Icon(favoriMi ? Icons.star : Icons.star_border, color: favoriMi ? Colors.amber : Colors.grey, size: 28), onPressed: () => widget.favoriDegistir(kod)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HisseDetaySayfasi(hisseKodu: kod))),
      ),
    );
  }
}

// --- 4. EKRAN: FAVORİLERİM ---
class FavorilerEkrani extends StatelessWidget {
  final Set<String> favoriHisseler;
  final Function(String) favoriDegistir;
  const FavorilerEkrani({super.key, required this.favoriHisseler, required this.favoriDegistir});

  @override
  Widget build(BuildContext context) {
    List<String> favoriListesi = favoriHisseler.toList();
    if (favoriListesi.isEmpty) return const Center(child: Text("Henüz favori hisseniz yok.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)));
    return ListView.builder(
      itemCount: favoriListesi.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF1D2136), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(favoriListesi[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            trailing: IconButton(icon: const Icon(Icons.star, color: Colors.amber, size: 28), onPressed: () => favoriDegistir(favoriListesi[index])),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HisseDetaySayfasi(hisseKodu: favoriListesi[index]))),
          ),
        );
      },
    );
  }
}

// --- 5. EKRAN: DETAY SAYFASI ---
class HisseDetaySayfasi extends StatefulWidget {
  final String hisseKodu;
  const HisseDetaySayfasi({super.key, required this.hisseKodu});
  @override State<HisseDetaySayfasi> createState() => _HisseDetaySayfasiState();
}

class _HisseDetaySayfasiState extends State<HisseDetaySayfasi> {
  Map<String, dynamic>? veri;
  bool yukleniyor = true;
  String aktifZamanDilimi = "1A";
  final List<String> zamanDilimleri = ["1G", "1H", "1A", "1Y", "5Y"];

  @override void initState() { super.initState(); veriCek(); }

  Future<void> veriCek() async {
    setState(() => yukleniyor = true);
    final String apiUrl = "http://192.168.1.151:8000/tahmin/${widget.hisseKodu}?zaman_dilimi=$aktifZamanDilimi";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) { setState(() { veri = json.decode(response.body); yukleniyor = false; }); }
      else { setState(() => yukleniyor = false); }
    } catch (e) { setState(() => yukleniyor = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.hisseKodu), centerTitle: true),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : veri == null
          ? const Center(child: Text("Veri alınamadı."))
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("\$${veri!['son_fiyat']}", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("RSI Endeksi: ${veri!['rsi_durumu']} ${veri!['rsi_durumu'] > 65 ? '(Şişkin)' : veri!['rsi_durumu'] < 50 ? '(Ucuzladı)' : '(Nötr)'}",
                style: TextStyle(color: veri!['rsi_durumu'] > 65 ? Colors.redAccent : veri!['rsi_durumu'] < 50 ? Colors.greenAccent : Colors.grey, fontSize: 16)),
            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF1D2136), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: zamanDilimleri.map((dilim) {
                  bool secili = aktifZamanDilimi == dilim;
                  return GestureDetector(
                    onTap: () { setState(() => aktifZamanDilimi = dilim); veriCek(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: secili ? Colors.cyanAccent.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                      child: Text(dilim, style: TextStyle(color: secili ? Colors.cyanAccent : Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 30),

            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false), titlesData: const FlTitlesData(show: false), borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          if (spot.barIndex == 1) return LineTooltipItem("AI Tahmini\n\$${spot.y}", const TextStyle(color: Color(0xFFB026FF), fontWeight: FontWeight.bold));
                          int index = spot.spotIndex.toInt();
                          String zaman = "";
                          if (veri!['gecmis_zaman_verisi'] != null && index < veri!['gecmis_zaman_verisi'].length) zaman = veri!['gecmis_zaman_verisi'][index];
                          return LineTooltipItem("$zaman\n\$${spot.y}", const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold));
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(spots: _grafikNoktalariOlustur(veri!['gecmis_grafik_verisi']), isCurved: true, color: Colors.cyanAccent, barWidth: 3, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: Colors.cyanAccent.withOpacity(0.1))),
                    LineChartBarData(spots: [FlSpot((veri!['gecmis_grafik_verisi'].length - 1).toDouble(), veri!['son_fiyat'].toDouble()), FlSpot((veri!['gecmis_grafik_verisi'].length).toDouble(), veri!['yarinki_tahmin'].toDouble())], isCurved: false, color: const Color(0xFFB026FF), barWidth: 3, isStrokeCapRound: true, dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 5, color: const Color(0xFFB026FF)))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFB026FF).withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFB026FF).withOpacity(0.5))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFB026FF), size: 24), const SizedBox(width: 10),
                  Text("${veri!['hedef_zaman']} Tahmini: \$${veri!['yarinki_tahmin']}", style: const TextStyle(color: Color(0xFFB026FF), fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  List<FlSpot> _grafikNoktalariOlustur(List<dynamic> fiyatlar) {
    List<FlSpot> noktalar = [];
    for (int i = 0; i < fiyatlar.length; i++) noktalar.add(FlSpot(i.toDouble(), fiyatlar[i].toDouble()));
    return noktalar;
  }
}