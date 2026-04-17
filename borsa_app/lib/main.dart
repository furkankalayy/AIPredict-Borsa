import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════════════════
//  SABİTLER
// ══════════════════════════════════════════════════════════════════

// Local geliştirme: "http://192.168.1.8:8000"
// HF Spaces prod: "https://KULLANICI_ADIN-aipredict-borsa.hf.space"
const kBaseUrl = "https://aipredict-borsa.onrender.com";

// ══════════════════════════════════════════════════════════════════
//  TEMA NOTIFIER
// ══════════════════════════════════════════════════════════════════

final ValueNotifier<bool> appDarkMode = ValueNotifier(false);

// ══════════════════════════════════════════════════════════════════
//  RENK PALETİ — Human Harvest / Warm Organic
// ══════════════════════════════════════════════════════════════════

class C {
  // Tema bağımlı renkler (getter)
  static Color get bg             => appDarkMode.value ? const Color(0xFF0D1117) : const Color(0xFFFDF9F4);
  static Color get surface        => appDarkMode.value ? const Color(0xFF0D1117) : const Color(0xFFFDF9F4);
  static Color get surfaceLowest  => appDarkMode.value ? const Color(0xFF161B22) : const Color(0xFFFFFFFF);
  static Color get surfaceLow     => appDarkMode.value ? const Color(0xFF1A1F29) : const Color(0xFFF7F3EF);
  static Color get surfaceMid     => appDarkMode.value ? const Color(0xFF1F2430) : const Color(0xFFF1EDE9);
  static Color get surfaceHigh    => appDarkMode.value ? const Color(0xFF252B38) : const Color(0xFFECE7E3);
  static Color get surfaceHighest => appDarkMode.value ? const Color(0xFF2D3444) : const Color(0xFFE6E2DE);
  static Color get onSurface      => appDarkMode.value ? const Color(0xFFE6EDF3) : const Color(0xFF1C1B19);
  static Color get onSurfaceVar   => appDarkMode.value ? const Color(0xFF8B949E) : const Color(0xFF3E4949);
  static Color get outline        => appDarkMode.value ? const Color(0xFF6E7681) : const Color(0xFF6E7979);
  static Color get outlineVar     => appDarkMode.value ? const Color(0xFF30363D) : const Color(0xFFBDC9C8);

  // Sabit renkler
  static const primary        = Color(0xFF036565);
  static const primaryCont    = Color(0xFF2E7E7E);
  static const primaryFixed   = Color(0xFFA4F0EF);
  static const primaryFixDim  = Color(0xFF88D3D3);
  static const secondary      = Color(0xFF5F5E59);
  static const tertiary       = Color(0xFF9E380D);
  static const tertiaryFixed  = Color(0xFFFFDBCF);
  static const secondaryFixed = Color(0xFFE5E2DB);
  static const error          = Color(0xFFBA1A1A);
}

// ══════════════════════════════════════════════════════════════════
//  METİN YARDIMCILARI
// ══════════════════════════════════════════════════════════════════

TextStyle hl(double sz,
    {Color? color, FontWeight fw = FontWeight.w700}) =>
    GoogleFonts.plusJakartaSans(fontSize: sz, fontWeight: fw, color: color ?? C.onSurface);

TextStyle bd(double sz,
    {Color? color, FontWeight fw = FontWeight.w400}) =>
    GoogleFonts.manrope(fontSize: sz, fontWeight: fw, color: color ?? C.onSurface);

// ══════════════════════════════════════════════════════════════════
//  ORTAK YARDIMCI FONKSİYONLAR
// ══════════════════════════════════════════════════════════════════

void yakinda(BuildContext ctx, [String mesaj = "Bu özellik yakında geliyor."]) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(mesaj, style: bd(13, color: Colors.white)),
    backgroundColor: C.primaryCont,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 2),
  ));
}

String _kullaniciKapsami(String email) {
  final temiz = email.trim().toLowerCase();
  if (temiz.isEmpty) return 'anonim';
  return temiz.replaceAll(RegExp(r'[^a-z0-9]'), '_');
}

Future<String> _aktifKullaniciKapsami() async {
  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString('kullanici_email') ?? '';
  return _kullaniciKapsami(email);
}

String _kullaniciBazliAnahtar(String temelAnahtar, String kapsam) {
  return '${temelAnahtar}__$kapsam';
}

void bildirimSheet(BuildContext ctx) {
  showModalBottomSheet(
    context: ctx,
    backgroundColor: C.surfaceLowest,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: C.outlineVar, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 24),
        Text("Bildirimler", style: hl(20, fw: FontWeight.w700)),
        const SizedBox(height: 40),
        Icon(Icons.notifications_off_outlined, size: 52, color: C.outlineVar),
        const SizedBox(height: 14),
        Text("Henüz bildirim yok", style: hl(16)),
        const SizedBox(height: 8),
        Text(
          "Takip ettiğin hisseler hareket ettiğinde\nburaya gelecek.",
          style: bd(13, color: C.secondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ]),
    ),
  );
}

void sifremiUnuttumDialog(BuildContext ctx) {
  final ctrl = TextEditingController();
  showDialog(
    context: ctx,
    builder: (dCtx) => AlertDialog(
      backgroundColor: C.surfaceLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text("Şifremi Unuttum", style: hl(18, fw: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(
          "E-posta adresini gir, sıfırlama bağlantısı gönderelim.",
          style: bd(13, color: C.secondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          style: bd(15),
          decoration: InputDecoration(
            hintText: "E-posta adresin",
            hintStyle: bd(15, color: C.outline.withOpacity(0.6)),
            filled: true, fillColor: C.surfaceHigh,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dCtx),
          child: Text("İptal", style: bd(14, color: C.secondary)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dCtx);
            yakinda(ctx, "Sıfırlama bağlantısı gönderildi.");
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: C.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          child: Text("Gönder",
              style: bd(14, color: Colors.white, fw: FontWeight.w600)),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════
//  UYGULAMA GİRİŞİ
// ══════════════════════════════════════════════════════════════════

void main() => runApp(const BorsaApp());

class BorsaApp extends StatefulWidget {
  const BorsaApp({super.key});
  @override
  State<BorsaApp> createState() => _BorsaAppState();
}

class _BorsaAppState extends State<BorsaApp> {
  @override
  void initState() {
    super.initState();
    appDarkMode.addListener(_onThemeChange);
    _loadThemePref();
  }

  @override
  void dispose() {
    appDarkMode.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() => setState(() {});

  Future<void> _loadThemePref() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool('dark_mode') ?? false;
    if (dark != appDarkMode.value) appDarkMode.value = dark;
  }

  ThemeData _buildTheme(bool dark) => ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: C.bg,
    colorScheme: (dark ? ColorScheme.dark : ColorScheme.light)(
      primary: C.primary,
      surface: C.surface,
      onPrimary: Colors.white,
      onSurface: C.onSurface,
      secondary: C.secondary,
      tertiary: C.tertiary,
      error: C.error,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      iconTheme: IconThemeData(color: C.onSurface),
    ),
    useMaterial3: true,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AIPredict-Borsa',
      theme: _buildTheme(appDarkMode.value),
      home: const LoginEkrani(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  GİRİŞ / KAYIT EKRANI
// ══════════════════════════════════════════════════════════════════

class LoginEkrani extends StatefulWidget {
  const LoginEkrani({super.key});

  @override
  State<LoginEkrani> createState() => _LoginEkraniState();
}

class _LoginEkraniState extends State<LoginEkrani> {
  bool kayitModu  = false;
  bool yukleniyor = false;
  bool sifreGoster = false;

  final _adCtrl    = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();

  @override
  void dispose() {
    _adCtrl.dispose();
    _emailCtrl.dispose();
    _sifreCtrl.dispose();
    super.dispose();
  }

  void _modDegistir() => setState(() {
    kayitModu = !kayitModu;
    _adCtrl.clear(); _emailCtrl.clear(); _sifreCtrl.clear();
  });

  Future<void> _authIslemi() async {
    if (_emailCtrl.text.isEmpty || _sifreCtrl.text.isEmpty ||
        (kayitModu && _adCtrl.text.isEmpty)) {
      _snack("Tüm alanları doldurun."); return;
    }
    setState(() => yukleniyor = true);
    final url = kayitModu ? "$kBaseUrl/kayit" : "$kBaseUrl/giris";
    final Map<String, String> body = {
      "email": _emailCtrl.text.trim(),
      "sifre": _sifreCtrl.text.trim(),
    };
    if (kayitModu) body["ad"] = _adCtrl.text.trim();
    try {
      final res = await http
          .post(Uri.parse(url),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 60));
      final data = json.decode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 200) {
        final ad = (data["ad"] ?? _adCtrl.text.trim()).toString();
        final email = _emailCtrl.text.trim();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('kullanici_adi', ad);
        await prefs.setString('kullanici_email', email);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    AnaSayfa(kullaniciAdi: ad.isNotEmpty ? ad : "Yatırımcı")),
          );
        }
      } else {
        _snack(data["detail"] ?? "Hata oluştu.");
      }
    } on TimeoutException {
      _snack("Sunucu uyanıyor olabilir. Lütfen 20-60 sn sonra tekrar dene.");
    } catch (_) {
      _snack("Sunucuya bağlanılamadı.");
    }
    if (mounted) setState(() => yukleniyor = false);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: bd(13, color: Colors.white)),
      backgroundColor: C.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(
                      color: C.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.insights_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text("AIPredict-Borsa",
                    style: hl(20, color: C.primary, fw: FontWeight.w800)),
              ]),
              const SizedBox(height: 44),
              Text(
                kayitModu ? "Hesap Oluştur" : "Tekrar Hoş Geldin",
                style: hl(30, fw: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                kayitModu
                    ? "Yatırım yolculuğuna bugün başla."
                    : "Bilgilerini girerek hesabına eriş.",
                style: bd(15, color: C.secondary),
              ),
              const SizedBox(height: 36),
              // ── Form
              if (kayitModu) ...[
                _label("Ad Soyad"),
                const SizedBox(height: 6),
                _input(_adCtrl, "Adın ve soyadın",
                    Icons.person_outline_rounded),
                const SizedBox(height: 18),
              ],
              _label("E-posta adresi"),
              const SizedBox(height: 6),
              _input(_emailCtrl, "ad@örnek.com", Icons.mail_outline_rounded,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _label("Şifre"),
                  if (!kayitModu)
                    GestureDetector(
                      onTap: () => sifremiUnuttumDialog(context),
                      child: Text("Şifremi unuttum?",
                          style: bd(13,
                              color: C.primaryCont, fw: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              _input(
                _sifreCtrl, "••••••••", Icons.lock_outline_rounded,
                obscure: !sifreGoster,
                suffix: GestureDetector(
                  onTap: () =>
                      setState(() => sifreGoster = !sifreGoster),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      sifreGoster
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: C.outline, size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // ── CTA
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: yukleniyor ? null : _authIslemi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999)),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: yukleniyor
                            ? [C.outlineVar, C.outlineVar]
                            : [C.primary, C.primaryCont],
                      ),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Center(
                      child: yukleniyor
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  kayitModu
                                      ? "Hesap Oluştur"
                                      : "Borsaya Giriş",
                                  style: bd(16,
                                      color: Colors.white,
                                      fw: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 18),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // ── Switch mode
              Center(
                child: GestureDetector(
                  onTap: _modDegistir,
                  child: RichText(
                    text: TextSpan(
                      style: bd(14, color: C.secondary, fw: FontWeight.w500),
                      children: [
                        TextSpan(
                            text: kayitModu
                                ? "Zaten hesabın var mı?  "
                                : "Hesabın yok mu?  "),
                        TextSpan(
                          text: kayitModu ? "Giriş Yap" : "Hesap Oluştur",
                          style: bd(14,
                              color: C.tertiary, fw: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // ── Footer
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20, runSpacing: 6,
                    children: ["Gizlilik", "Koşullar", "© 2026 AIPredict-Borsa"]
                      .map((t) => Text(t,
                          style: bd(11,
                              color: C.outline, fw: FontWeight.w500)))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: bd(13, color: C.onSurfaceVar, fw: FontWeight.w600));

  Widget _input(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      style: bd(15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: bd(15, color: C.outline.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: C.outline, size: 20),
        suffixIcon: suffix,
        filled: true, fillColor: C.surfaceHigh,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  ANA EKRAN (SHELL)
// ══════════════════════════════════════════════════════════════════

class AnaSayfa extends StatefulWidget {
  final String kullaniciAdi;
  const AnaSayfa({super.key, required this.kullaniciAdi});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _sekme = 0;
  final Set<String> favoriler = {"TSLA", "AAPL"};
  late String _kullaniciAdi;

  @override
  void initState() {
    super.initState();
    _kullaniciAdi = widget.kullaniciAdi;
    _kullaniciAdiniYukle();
  }

  Future<void> _kullaniciAdiniYukle() async {
    final p = await SharedPreferences.getInstance();
    final kayitliAd = (p.getString('kullanici_adi') ?? '').trim();
    if (kayitliAd.isNotEmpty && mounted) {
      setState(() => _kullaniciAdi = kayitliAd);
    }
  }

  void _favoriDegistir(String kod) => setState(() {
    if (favoriler.contains(kod)) {
      favoriler.remove(kod);
    } else {
      favoriler.add(kod);
    }
  });

  @override
  Widget build(BuildContext context) {
    final ekranlar = [
      KesfetEkrani(
        kullaniciAdi: _kullaniciAdi,
        favoriler: favoriler,
        favoriDegistir: _favoriDegistir,
      ),
      PortfolioEkrani(
        favoriler: favoriler,
        favoriDegistir: _favoriDegistir,
      ),
      const AkademiEkrani(),
      ProfilEkrani(
        kullaniciAdi: _kullaniciAdi,
        onKullaniciAdiGuncellendi: (yeniAd) {
          if (!mounted) return;
          setState(() => _kullaniciAdi = yeniAd);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: C.bg,
      extendBody: true,
      body: ekranlar[_sekme],
      bottomNavigationBar: _navBar(),
    );
  }

  static const _navItems = [
    (Icons.explore_outlined,               Icons.explore_rounded,               "Keşfet"),
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, "Portföy"),
    (Icons.school_outlined,                Icons.school_rounded,                "Akademi"),
    (Icons.person_outline_rounded,         Icons.person_rounded,                "Profil"),
  ];

  Widget _navBar() {
    return Container(
      decoration: BoxDecoration(
        color: C.bg.withOpacity(0.94),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: C.onSurface.withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final (offIcon, onIcon, label) = _navItems[i];
              final aktif = _sekme == i;
              return GestureDetector(
                onTap: () => setState(() => _sekme = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: aktif ? 18 : 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: aktif ? C.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        aktif ? onIcon : offIcon,
                        color: aktif ? Colors.white : C.secondary,
                        size: 22,
                      ),
                      if (aktif) ...[
                        const SizedBox(width: 6),
                        Text(label,
                            style: bd(11,
                                color: Colors.white,
                                fw: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  KEŞFET EKRANI
// ══════════════════════════════════════════════════════════════════

class KesfetEkrani extends StatefulWidget {
  final String kullaniciAdi;
  final Set<String> favoriler;
  final Function(String) favoriDegistir;

  const KesfetEkrani({
    super.key,
    required this.kullaniciAdi,
    required this.favoriler,
    required this.favoriDegistir,
  });

  @override
  State<KesfetEkrani> createState() => _KesfetEkraniState();
}

class _KesfetEkraniState extends State<KesfetEkrani> {
  final _aramaCtrl  = TextEditingController();
  final _haberCtrl  = PageController(viewportFraction: 0.88);
  Timer? _haberTimer;

  List<dynamic> sonuclar    = [];
  List<dynamic> haberler    = [];
  List<String>  aramaGecmisi = [];
  bool yukleniyor   = false;
  bool aramaAktif   = false;
  int aktifPazar    = 0;
  int aktifFiltre   = -1;

  static const pazarlar    = ["NASDAQ", "BIST 100", "Kripto"];
  static const pazarlarApi = ["NASDAQ", "BİST",    "Kripto"];
  static const filtreler   = [
    "Yapay Zeka AL", "Yapay Zeka SAT",
    "Güvenli Liman", "Temettü", "Kazananlar", "Kaybedenler",
  ];
  static const filtrelerApi = [
    "AL", "SAT", "Batmayacak", "Temettü", "Kazananlar", "Kaybedenler",
  ];
  static const filtreIkonlar = [
    Icons.trending_up_rounded,
    Icons.trending_down_rounded,
    Icons.shield_rounded,
    Icons.payments_rounded,
    Icons.rocket_launch_rounded,
    Icons.keyboard_double_arrow_down_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _haberlerCek();
    _gecmisiYukle();
  }

  Future<void> _gecmisiYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final kapsam = await _aktifKullaniciKapsami();
    final anahtar = _kullaniciBazliAnahtar('arama_gecmisi', kapsam);
    if (mounted) {
      setState(() {
        aramaGecmisi = prefs.getStringList(anahtar) ?? [];
      });
    }
  }

  Future<void> _gecmiseEkle(String kod) async {
    final prefs = await SharedPreferences.getInstance();
    final kapsam = await _aktifKullaniciKapsami();
    final anahtar = _kullaniciBazliAnahtar('arama_gecmisi', kapsam);
    final liste = prefs.getStringList(anahtar) ?? [];
    liste.remove(kod);
    liste.insert(0, kod);
    final yeni = liste.take(5).toList();
    await prefs.setStringList(anahtar, yeni);
    if (mounted) setState(() => aramaGecmisi = yeni);
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    _haberCtrl.dispose();
    _haberTimer?.cancel();
    super.dispose();
  }

  Future<void> _haberlerCek() async {
    try {
      final res = await http
          .get(Uri.parse("$kBaseUrl/haberler"))
          .timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) {
          setState(() => haberler = data['haberler'] ?? []);
          _haberOtomatikBaslat();
        }
      }
    } catch (_) {}
  }

  void _haberOtomatikBaslat() {
    _haberTimer?.cancel();
    if (haberler.isEmpty) return;
    _haberTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_haberCtrl.hasClients) return;
      final simdiki = _haberCtrl.page?.round() ?? 0;
      final sonraki = (simdiki + 1) % haberler.length;
      _haberCtrl.animateToPage(
        sonraki,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _ara(String sorgu) async {
    if (sorgu.trim().isEmpty) {
      setState(() => sonuclar = []);
      return;
    }
    setState(() => yukleniyor = true);
    try {
      final res = await http.get(Uri.parse(
          "https://query2.finance.yahoo.com/v1/finance/search?q=$sorgu&quotesCount=100&newsCount=0"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          sonuclar = (data['quotes'] as List)
              .where((q) =>
                  ['EQUITY', 'ETF', 'CRYPTOCURRENCY'].contains(q['quoteType']))
              .toList();
          yukleniyor = false;
        });
      } else {
        setState(() => yukleniyor = false);
      }
    } catch (_) {
      setState(() => yukleniyor = false);
    }
  }

  Future<void> _filtreGetir(int i) async {
    setState(() { yukleniyor = true; sonuclar = []; aktifFiltre = i; });
    try {
      final pazar = pazarlarApi[aktifPazar];
      final kat   = filtrelerApi[i];
        final res = await http
          .get(Uri.parse("$kBaseUrl/tarayici?pazar=$pazar&kategori=$kat"))
          .timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        setState(() {
          sonuclar = json.decode(res.body)['sonuclar'];
          yukleniyor = false;
        });
      } else {
        setState(() => yukleniyor = false);
      }
    } catch (_) {
      setState(() => yukleniyor = false);
    }
  }

  Future<void> _yenile() async {
    if (aktifFiltre >= 0) {
      await _filtreGetir(aktifFiltre);
    } else if (_aramaCtrl.text.isNotEmpty) {
      await _ara(_aramaCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _yenile,
      color: C.primary,
      backgroundColor: C.surfaceLowest,
      displacement: 80,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(child: _searchBar()),
          SliverToBoxAdapter(child: _marketTabs()),
          SliverToBoxAdapter(child: _filterPills()),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          if (aramaAktif && _aramaCtrl.text.isEmpty && aktifFiltre < 0 && aramaGecmisi.isNotEmpty)
            _sonAramalar(),
          if (yukleniyor)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: C.primary, strokeWidth: 2),
              ),
            )
          else if (_aramaCtrl.text.isNotEmpty || aktifFiltre >= 0)
            _sonucListesi()
          else if (!aramaAktif)
            _featuredAndQuick(),
          const SliverToBoxAdapter(child: SizedBox(height: 130)),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [C.bg, C.surfaceLow],
        ),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Merhaba, ${widget.kullaniciAdi}",
                style: hl(22, color: C.primary, fw: FontWeight.w700)),
            const SizedBox(height: 2),
            Text("Piyasaları keşfetmeye devam et.",
                style: bd(13, color: C.secondary)),
          ]),
        ),
        GestureDetector(
          onTap: () => bildirimSheet(context),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: C.surfaceLow,
                borderRadius: BorderRadius.circular(9999)),
            child: const Icon(Icons.notifications_outlined,
                color: C.primary, size: 22),
          ),
        ),
      ]),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: TextField(
        controller: _aramaCtrl,
        onChanged: _ara,
        onTap: () => setState(() => aramaAktif = true),
        onTapOutside: (_) => setState(() => aramaAktif = false),
        style: bd(15),
        decoration: InputDecoration(
          hintText: "Hisse, ETF veya Kripto ara...",
          hintStyle: bd(15, color: C.outline.withOpacity(0.7)),
          prefixIcon:
              Icon(Icons.search_rounded, color: C.outline, size: 22),
          suffixIcon: _aramaCtrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: C.outline, size: 20),
                  onPressed: () {
                    _aramaCtrl.clear();
                    setState(() { sonuclar = []; aramaAktif = false; });
                  })
              : null,
          filled: true, fillColor: C.surfaceLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: C.outlineVar),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: C.outlineVar),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: C.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _sonAramalar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Son Aramalar", style: bd(13, color: C.secondary, fw: FontWeight.w600)),
            GestureDetector(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                final kapsam = await _aktifKullaniciKapsami();
                final anahtar = _kullaniciBazliAnahtar('arama_gecmisi', kapsam);
                await prefs.remove(anahtar);
                if (mounted) setState(() => aramaGecmisi = []);
              },
              child: Text("Temizle", style: bd(12, color: C.tertiary, fw: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: aramaGecmisi.map((kod) {
            return GestureDetector(
              onTap: () {
                _aramaCtrl.text = kod;
                _ara(kod);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: C.surfaceLowest,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: C.outlineVar),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.history_rounded, size: 14, color: C.secondary),
                  const SizedBox(width: 6),
                  Text(kod, style: bd(13, fw: FontWeight.w600)),
                ]),
              ),
            );
          }).toList()),
        ]),
      ),
    );
  }

  Widget _marketTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: List.generate(pazarlar.length, (i) {
          final aktif = aktifPazar == i;
          return GestureDetector(
            onTap: () => setState(() {
              aktifPazar  = i;
              aktifFiltre = -1;
              sonuclar    = [];
            }),
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  pazarlar[i],
                  style: bd(14,
                      color: aktif ? C.onSurface : C.secondary,
                      fw: aktif ? FontWeight.w700 : FontWeight.w500),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  width: aktif ? 24 : 0,
                  decoration: BoxDecoration(
                    color: C.primary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }

  Widget _filterPills() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filtreler.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final aktif = aktifFiltre == i;
          return GestureDetector(
            onTap: () {
              if (aktif) {
                setState(() { aktifFiltre = -1; sonuclar = []; });
              } else {
                _filtreGetir(i);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: aktif ? C.primary : C.surfaceLowest,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: aktif ? C.primary : C.outlineVar),
                boxShadow: aktif
                    ? [BoxShadow(color: C.primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  filtreIkonlar[i],
                  size: 15,
                  color: aktif ? Colors.white : C.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  filtreler[i],
                  style: bd(13,
                      color: aktif ? Colors.white : C.secondary,
                      fw: aktif ? FontWeight.w600 : FontWeight.w500),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _featuredAndQuick() {
    return SliverToBoxAdapter(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        // Featured hero card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: C.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text("AI TAHMIN",
                        style: bd(11,
                            color: Colors.white, fw: FontWeight.w600)),
                  ),
                  const SizedBox(height: 10),
                  Text("Piyasaları AI ile Oku",
                      style: hl(20, color: Colors.white, fw: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    "LSTM modelimiz 60 günlük veriyi analiz ederek sinyaller üretiyor.",
                    style: bd(12,
                        color: C.primaryFixed.withOpacity(0.9)),
                  ),
                ]),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.auto_graph_rounded,
                  color: Colors.white, size: 52),
            ]),
          ),
        ),
        // ── Haber Carousel
        if (haberler.isNotEmpty) ...[
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Son Haberler", style: hl(18, fw: FontWeight.w700)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: C.primaryFixed.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.newspaper_rounded, size: 12, color: C.primary),
                    const SizedBox(width: 4),
                    Text("Canlı", style: bd(11, color: C.primary, fw: FontWeight.w600)),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 148,
            child: PageView.builder(
              controller: _haberCtrl,
              itemCount: haberler.length,
              itemBuilder: (_, i) => _haberKarti(haberler[i] as Map<String, dynamic>),
            ),
          ),
          const SizedBox(height: 10),
          // Dot göstergesi
          _haberDotlar(),
        ],
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text("Hızlı Erişim", style: hl(18, fw: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 10, runSpacing: 10,
            children: ["AAPL", "TSLA", "NVDA", "BTC-USD", "ETH-USD", "THYAO.IS"]
                .map((s) => GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => HisseDetaySayfasi(
                                  hisseKodu: s,
                                  favoriBaslangic: widget.favoriler.contains(s),
                                  onFavori: widget.favoriDegistir,
                                )),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: C.surfaceLowest,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: C.outlineVar),
                        ),
                        child: Text(s,
                            style: bd(13,
                                color: C.primary, fw: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
        ),
      ]),
    );
  }

  SliverList _sonucListesi() {
    if (sonuclar.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Column(children: [
                Icon(Icons.search_off_rounded, size: 56, color: C.outlineVar),
                const SizedBox(height: 16),
                Text("Sonuç bulunamadı", style: hl(18)),
                const SizedBox(height: 8),
                Text("Farklı bir filtre deneyin",
                    style: bd(14, color: C.secondary)),
              ]),
            ),
          ),
        ]),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _hisseKarti(sonuclar[i] as Map<String, dynamic>),
        childCount: sonuclar.length,
      ),
    );
  }

  Widget _hisseKarti(Map<String, dynamic> item) {
    final kod    = (item['symbol'] ?? '') as String;
    final ad     = (item['shortname'] ?? item['longname'] ?? 'Bilinmeyen') as String;
    final favori = widget.favoriler.contains(kod);

    final double? fiyat   = item['regularMarketPrice'] != null
        ? (item['regularMarketPrice'] as num).toDouble()
        : null;
    final double? degisim = item['regularMarketChangePercent'] != null
        ? (item['regularMarketChangePercent'] as num).toDouble()
        : null;

    return GestureDetector(
      onTap: () {
        _gecmiseEkle(kod);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => HisseDetaySayfasi(
                    hisseKodu: kod,
                    favoriBaslangic: widget.favoriler.contains(kod),
                    onFavori: widget.favoriDegistir,
                  )),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: C.surfaceLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: C.onSurface.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: C.primaryFixed.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                kod.length > 2 ? kod.substring(0, 2) : kod,
                style: hl(14, color: C.primary, fw: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(kod, style: bd(15, fw: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(ad,
                  style: bd(13, color: C.secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          // ── Fiyat + % değişim
          if (fiyat != null) ...[
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                '\$${fiyat >= 1000 ? fiyat.toStringAsFixed(0) : fiyat.toStringAsFixed(2)}',
                style: bd(14, fw: FontWeight.w700),
              ),
              if (degisim != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: degisim >= 0
                        ? C.primary.withOpacity(0.10)
                        : C.error.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${degisim >= 0 ? "+" : ""}${degisim.toStringAsFixed(2)}%',
                    style: bd(11,
                        color: degisim >= 0 ? C.primary : C.error,
                        fw: FontWeight.w600),
                  ),
                ),
              ],
            ]),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: Icon(
              favori ? Icons.star_rounded : Icons.star_outline_rounded,
              color: favori ? const Color(0xFFFBBF24) : C.outlineVar,
              size: 22,
            ),
            onPressed: () => widget.favoriDegistir(kod),
          ),
          Icon(Icons.chevron_right_rounded,
              color: C.outlineVar, size: 20),
        ]),
      ),
    );
  }

  // ── Haber kartı
  Widget _haberKarti(Map<String, dynamic> haber) {
    final baslik = (haber['baslik'] as String? ?? '').trim();
    final kaynak = (haber['kaynak'] as String? ?? '');
    final url    = (haber['url']    as String? ?? '');
    final resim  = (haber['resim']  as String? ?? '');
    final zaman  = (haber['zaman']  as int?    ?? 0);

    String zamanStr = '';
    if (zaman > 0) {
      final fark = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(zaman * 1000));
      if (fark.inMinutes < 60) {
        zamanStr = '${fark.inMinutes}dk önce';
      } else if (fark.inHours < 24) {
        zamanStr = '${fark.inHours}s önce';
      } else {
        zamanStr = '${fark.inDays}g önce';
      }
    }

    return GestureDetector(
      onTap: () async {
        if (url.isNotEmpty) {
          try {
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          } catch (_) {}
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: C.surfaceLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: C.onSurface.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Kaynak + zaman
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: C.primaryFixed.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(kaynak,
                        style: bd(10, color: C.primary, fw: FontWeight.w600)),
                  ),
                  if (zamanStr.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(zamanStr,
                        style: bd(10, color: C.secondary)),
                  ],
                ]),
                const SizedBox(height: 10),
                // Başlık
                Text(
                  baslik,
                  style: hl(13, fw: FontWeight.w700),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Thumbnail
          if (resim.isNotEmpty) ...[
            const SizedBox(width: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                resim,
                width: 76, height: 76,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => const SizedBox.shrink(),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  // ── Dot göstergesi (PageView pozisyonunu takip eder)
  Widget _haberDotlar() {
    return StatefulBuilder(
      builder: (ctx, setDot) {
        _haberCtrl.addListener(() {
          if (ctx.mounted) setDot(() {});
        });
        final aktif = _haberCtrl.hasClients
            ? (_haberCtrl.page?.round() ?? 0)
            : 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(haberler.length, (i) {
            final secili = i == aktif;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: secili ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: secili ? C.primary : C.outlineVar,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  PORTFOLIO EKRANI
// ══════════════════════════════════════════════════════════════════

class PortfolioEkrani extends StatefulWidget {
  final Set<String> favoriler;
  final Function(String) favoriDegistir;

  const PortfolioEkrani({
    super.key,
    required this.favoriler,
    required this.favoriDegistir,
  });

  @override
  State<PortfolioEkrani> createState() => _PortfolioEkraniState();
}

class _PortfolioEkraniState extends State<PortfolioEkrani> {
  // symbol -> {fiyat, degisim, ad}
  Map<String, Map<String, dynamic>> fiyatlar = {};
  Map<String, double> varliklar = {};
  Map<String, double> maliyetler = {};
  bool yukleniyor = false;
  DateTime? sonGuncelleme;

  @override
  void initState() {
    super.initState();
    _varliklariYukle();
  }

  @override
  void didUpdateWidget(PortfolioEkrani old) {
    super.didUpdateWidget(old);
    if (old.favoriler.length != widget.favoriler.length) {
      _fiyatlarCek();
    }
  }

  Future<void> _varliklariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final kapsam = await _aktifKullaniciKapsami();
    final anahtar = _kullaniciBazliAnahtar('portfoy_varliklari', kapsam);
    final ham = prefs.getString(anahtar);
    if (ham != null && ham.isNotEmpty) {
      try {
        final decoded = json.decode(ham) as Map<String, dynamic>;
        final yuklenen = <String, double>{};
        final yuklenenMaliyet = <String, double>{};
        for (final e in decoded.entries) {
          final kod = e.key.trim().toUpperCase();
          double adet = 0;
          double maliyet = 0;

          if (e.value is num) {
            // Eski kayıt formatı: { "AAPL": 10.0 }
            adet = (e.value as num).toDouble();
          } else if (e.value is Map<String, dynamic>) {
            // Yeni kayıt formatı: { "AAPL": {"adet": 10.0, "maliyet": 180.5} }
            final item = e.value as Map<String, dynamic>;
            adet = (item['adet'] as num?)?.toDouble() ?? 0;
            maliyet = (item['maliyet'] as num?)?.toDouble() ?? 0;
          }

          if (kod.isNotEmpty && adet > 0) {
            yuklenen[kod] = adet;
            if (maliyet > 0) yuklenenMaliyet[kod] = maliyet;
          }
        }
        if (mounted) {
          setState(() {
            varliklar = yuklenen;
            maliyetler = yuklenenMaliyet;
          });
        }
      } catch (_) {}
    }
    await _fiyatlarCek();
  }

  Future<void> _varliklariKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    final kapsam = await _aktifKullaniciKapsami();
    final anahtar = _kullaniciBazliAnahtar('portfoy_varliklari', kapsam);
    final kayit = <String, dynamic>{};
    for (final e in varliklar.entries) {
      kayit[e.key] = {
        'adet': e.value,
        'maliyet': maliyetler[e.key] ?? 0,
      };
    }
    await prefs.setString(anahtar, json.encode(kayit));
  }

  Set<String> _takipSembolleri() {
    return {...widget.favoriler, ...varliklar.keys};
  }

  Future<void> _fiyatlarCek() async {
    final semboller = _takipSembolleri().toList();
    if (semboller.isEmpty) {
      if (mounted) {
        setState(() {
          fiyatlar = {};
          yukleniyor = false;
          sonGuncelleme = DateTime.now();
        });
      }
      return;
    }

    setState(() => yukleniyor = true);
    try {
      final futures = semboller.map((sembol) => http.get(
        Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$sembol?interval=1d&range=1d',
        ),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 60)));

      final yanitlar = await Future.wait(futures, eagerError: false);
      final yeni = <String, Map<String, dynamic>>{};

      for (int i = 0; i < semboller.length; i++) {
        try {
          final res = yanitlar[i];
          if (res.statusCode != 200) continue;
          final data = json.decode(res.body);
          final meta = data['chart']?['result']?[0]?['meta'];
          if (meta == null) continue;
          final double fiyat = (meta['regularMarketPrice'] as num).toDouble();
          final double onceki = (meta['chartPreviousClose'] as num).toDouble();
          final double degisim = onceki > 0 ? (fiyat - onceki) / onceki * 100 : 0;
          yeni[semboller[i]] = {
            'fiyat': fiyat,
            'degisim': degisim,
            'ad': meta['shortName'] ?? meta['longName'] ?? '',
          };
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          fiyatlar = yeni;
          sonGuncelleme = DateTime.now();
          yukleniyor = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => yukleniyor = false);
    }
  }

  double _netDeger() {
    double toplam = 0;
    for (final e in varliklar.entries) {
      final fiyat = fiyatlar[e.key]?['fiyat'] as double?;
      if (fiyat != null) toplam += e.value * fiyat;
    }
    return toplam;
  }

  double _oncekiNetDeger() {
    double toplam = 0;
    for (final e in varliklar.entries) {
      final fiyat = fiyatlar[e.key]?['fiyat'] as double?;
      final degisim = fiyatlar[e.key]?['degisim'] as double?;
      if (fiyat == null || degisim == null) continue;
      final bolen = 1 + (degisim / 100);
      if (bolen <= 0) continue;
      toplam += e.value * (fiyat / bolen);
    }
    return toplam;
  }

  double _gunlukDegisimYuzde() {
    final onceki = _oncekiNetDeger();
    final simdiki = _netDeger();
    if (onceki <= 0) return 0;
    return ((simdiki - onceki) / onceki) * 100;
  }

  double _toplamKarZarar() {
    double toplam = 0;
    for (final e in varliklar.entries) {
      final kod = e.key;
      final adet = e.value;
      final fiyat = fiyatlar[kod]?['fiyat'] as double?;
      final maliyet = maliyetler[kod];
      if (fiyat == null || maliyet == null || maliyet <= 0) continue;
      toplam += (fiyat - maliyet) * adet;
    }
    return toplam;
  }

  double _toplamKarZararYuzde() {
    double toplamMaliyet = 0;
    for (final e in varliklar.entries) {
      final maliyet = maliyetler[e.key];
      if (maliyet == null || maliyet <= 0) continue;
      toplamMaliyet += maliyet * e.value;
    }
    if (toplamMaliyet <= 0) return 0;
    return (_toplamKarZarar() / toplamMaliyet) * 100;
  }

  Future<void> _varlikEkleSheet() async {
    final sembolCtrl = TextEditingController();
    final adetCtrl = TextEditingController();
    final maliyetCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              media.viewInsets.bottom + media.padding.bottom + 24,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: C.outlineVar,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text("Varlık Ekle", style: hl(20, fw: FontWeight.w700)),
              const SizedBox(height: 14),
              Text("Hisse Kodu", style: bd(13, color: C.secondary, fw: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: sembolCtrl,
                textCapitalization: TextCapitalization.characters,
                style: bd(15),
                decoration: InputDecoration(
                  hintText: "Örn: AAPL veya THYAO.IS",
                  hintStyle: bd(14, color: C.outline.withOpacity(0.7)),
                  filled: true,
                  fillColor: C.surfaceHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text("Adet", style: bd(13, color: C.secondary, fw: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: adetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: bd(15),
                decoration: InputDecoration(
                  hintText: "Örn: 12.5",
                  hintStyle: bd(14, color: C.outline.withOpacity(0.7)),
                  filled: true,
                  fillColor: C.surfaceHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text("Birim Maliyet", style: bd(13, color: C.secondary, fw: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: maliyetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: bd(15),
                decoration: InputDecoration(
                  hintText: "Örn: 185.40",
                  hintStyle: bd(14, color: C.outline.withOpacity(0.7)),
                  filled: true,
                  fillColor: C.surfaceHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final kod = sembolCtrl.text.trim().toUpperCase();
                    final adet = double.tryParse(adetCtrl.text.replaceAll(',', '.'));
                    final maliyet = double.tryParse(maliyetCtrl.text.replaceAll(',', '.'));
                    if (kod.isEmpty || adet == null || adet <= 0 || maliyet == null || maliyet <= 0) {
                      yakinda(context, "Kod, adet ve birim maliyet alanlarını doğru girin.");
                      return;
                    }

                    setState(() {
                      final eskiAdet = varliklar[kod] ?? 0;
                      final yeniAdet = eskiAdet + adet;
                      final eskiMaliyet = maliyetler[kod] ?? maliyet;
                      final ortalamaMaliyet =
                          ((eskiAdet * eskiMaliyet) + (adet * maliyet)) / yeniAdet;

                      varliklar[kod] = yeniAdet;
                      maliyetler[kod] = ortalamaMaliyet;
                    });
                    await _varliklariKaydet();
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _fiyatlarCek();
                    if (mounted) yakinda(context, "$kod portföye eklendi.");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Ekle", style: bd(15, color: Colors.white, fw: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _varlikSil(String kod) async {
    setState(() {
      varliklar.remove(kod);
      maliyetler.remove(kod);
    });
    await _varliklariKaydet();
    await _fiyatlarCek();
  }

  @override
  Widget build(BuildContext context) {
    final favoriListe = widget.favoriler.toList();
    final varlikListe = varliklar.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _fiyatlarCek,
      color: C.primary,
      backgroundColor: C.surfaceLowest,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(child: _bentoGrid(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Varlıklarım", style: hl(20, fw: FontWeight.w700)),
                  GestureDetector(
                    onTap: _varlikEkleSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: C.primary,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text("Ekle", style: bd(12, color: Colors.white, fw: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (varlikListe.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: C.surfaceLowest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    const Icon(Icons.account_balance_wallet_outlined, color: C.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Henüz hisse eklemedin. Hisse kodu ve adet girerek net değer takibi yapabilirsin.",
                        style: bd(12, color: C.secondary),
                      ),
                    ),
                  ]),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _varlikKarti(ctx, varlikListe[i]),
                childCount: varlikListe.length,
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Favorilerim", style: hl(22, fw: FontWeight.w700)),
                  Row(children: [
                    if (yukleniyor)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: C.primary),
                      )
                    else if (sonGuncelleme != null) ...[
                      Icon(Icons.circle, size: 7, color: C.primary),
                      const SizedBox(width: 5),
                      Text(_guncellemeSuresi(), style: bd(11, color: C.secondary)),
                    ],
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => yakinda(context, "Yıldız ikonuna basarak favorilerden çıkarabilirsiniz."),
                      child: Text("Düzenle", style: bd(13, color: C.primary, fw: FontWeight.w600)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          if (favoriListe.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: C.surfaceLowest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Icon(Icons.star_outline_rounded, color: C.outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text("Keşfet sekmesinden favori hisse ekleyebilirsin.", style: bd(12, color: C.secondary)),
                    ),
                  ]),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _portfoyKarti(ctx, favoriListe[i]),
                childCount: favoriListe.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 130)),
        ],
      ),
    );
  }

  String _guncellemeSuresi() {
    if (sonGuncelleme == null) return '';
    final fark = DateTime.now().difference(sonGuncelleme!);
    if (fark.inSeconds < 60) return 'Az önce';
    if (fark.inMinutes < 60) return '${fark.inMinutes}dk önce';
    return '${fark.inHours}s önce';
  }

  String _usd(double deger, {int hassasiyet = 2}) {
    return '\$${deger.toStringAsFixed(hassasiyet)}';
  }

  Widget _varlikKarti(BuildContext ctx, String kod) {
    final bilgi = fiyatlar[kod];
    final fiyat = bilgi?['fiyat'] as double?;
    final degisim = bilgi?['degisim'] as double?;
    final ad = (bilgi?['ad'] as String?) ?? kod;
    final adet = varliklar[kod] ?? 0;
    final maliyet = maliyetler[kod];
    final deger = fiyat != null ? fiyat * adet : null;
    final karZarar = (fiyat != null && maliyet != null) ? (fiyat - maliyet) * adet : null;
    final karZararYuzde = (fiyat != null && maliyet != null && maliyet > 0)
        ? ((fiyat - maliyet) / maliyet) * 100
        : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => HisseDetaySayfasi(
            hisseKodu: kod,
            favoriBaslangic: widget.favoriler.contains(kod),
            onFavori: widget.favoriDegistir,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.surfaceLowest,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: C.onSurface.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(kod, style: bd(16, fw: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(ad, style: bd(12, color: C.secondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            if (degisim != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: degisim >= 0 ? C.primary.withOpacity(0.1) : C.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  degisim >= 0 ? "Artıyor" : "Azalıyor",
                  style: bd(11, fw: FontWeight.w700, color: degisim >= 0 ? C.primary : C.error),
                ),
              ),
            IconButton(
              onPressed: () => _varlikSil(kod),
              icon: const Icon(Icons.delete_outline_rounded, color: C.error, size: 20),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 14, runSpacing: 8, children: [
            Text("Adet: ${adet.toStringAsFixed(adet % 1 == 0 ? 0 : 2)}", style: bd(12, color: C.secondary)),
            if (fiyat != null) Text("Fiyat: ${_usd(fiyat)}", style: bd(12, color: C.secondary)),
            if (maliyet != null) Text("Maliyet: ${_usd(maliyet)}", style: bd(12, color: C.secondary)),
            if (deger != null) Text("Toplam: ${_usd(deger)}", style: bd(12, fw: FontWeight.w700, color: C.primary)),
            if (karZarar != null)
              Text(
                "K/Z: ${karZarar >= 0 ? '+' : ''}${_usd(karZarar.abs())}${karZararYuzde != null ? ' (${karZararYuzde >= 0 ? '+' : ''}${karZararYuzde.toStringAsFixed(2)}%)' : ''}",
                style: bd(12, fw: FontWeight.w700, color: karZarar >= 0 ? C.primary : C.error),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _portfoyKarti(BuildContext ctx, String kod) {
    final bilgi = fiyatlar[kod];
    final fiyat = bilgi?['fiyat'] as double?;
    final degisim = bilgi?['degisim'] as double?;
    final ad = (bilgi?['ad'] as String?) ?? '';
    final yukYapiliyor = yukleniyor && bilgi == null;

    return GestureDetector(
      onTap: () => Navigator.push(
        ctx,
        MaterialPageRoute(
            builder: (_) => HisseDetaySayfasi(
                  hisseKodu: kod,
                  favoriBaslangic: widget.favoriler.contains(kod),
                  onFavori: widget.favoriDegistir,
                )),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: C.surfaceLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: C.onSurface.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: C.primaryFixed.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                kod.length > 2 ? kod.substring(0, 2) : kod,
                style: hl(14, color: C.primary, fw: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kod, style: bd(16, fw: FontWeight.w700)),
              Text(
                ad.isNotEmpty ? ad : kod,
                style: bd(12, color: C.secondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          if (yukYapiliyor)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: C.outlineVar),
            )
          else if (fiyat != null) ...[
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_usd(fiyat), style: bd(15, fw: FontWeight.w700)),
              if (degisim != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: degisim >= 0 ? C.primary.withOpacity(0.10) : C.error.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${degisim >= 0 ? "+" : ""}${degisim.toStringAsFixed(2)}%',
                    style: bd(11, color: degisim >= 0 ? C.primary : C.error, fw: FontWeight.w600),
                  ),
                ),
              ],
            ]),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 22),
            onPressed: () => widget.favoriDegistir(kod),
          ),
          Icon(Icons.chevron_right_rounded, color: C.outlineVar, size: 20),
        ]),
      ),
    );
  }

  Widget _header() {
    final net = _netDeger();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("GENEL BAKIŞ", style: bd(11, color: C.secondary, fw: FontWeight.w700)),
                const SizedBox(height: 4),
                Text("Portföyüm", style: hl(28, fw: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Net Değer", style: bd(11, color: C.secondary)),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      net > 0 ? _usd(net) : "—",
                      style: hl(22, color: C.primary, fw: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bentoGrid(BuildContext context) {
    final degisim = _gunlukDegisimYuzde();
    final renk = degisim >= 0 ? C.primary : C.error;
    final toplamKz = _toplamKarZarar();
    final toplamKzYuzde = _toplamKarZararYuzde();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: C.surfaceLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: C.onSurface.withOpacity(0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Günlük Değişim", style: bd(13, fw: FontWeight.w600)),
              const SizedBox(height: 4),
              Text("Girilen varlıkların bugünkü hareketi.", style: bd(11, color: C.secondary)),
              const SizedBox(height: 16),
              Text('${degisim >= 0 ? "+" : ""}${degisim.toStringAsFixed(2)}%', style: hl(28, color: renk, fw: FontWeight.w800)),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 140,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: C.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Toplam K/Z", style: bd(13, color: Colors.white, fw: FontWeight.w600)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  "${toplamKz >= 0 ? '+' : '-'}${_usd(toplamKz.abs())}",
                  maxLines: 1,
                  softWrap: false,
                  style: hl(17, color: Colors.white, fw: FontWeight.w800),
                ),
              ),
            ),
            Text(
              "${toplamKzYuzde >= 0 ? '+' : ''}${toplamKzYuzde.toStringAsFixed(2)}%",
              style: bd(11, color: C.primaryFixed.withOpacity(0.95), fw: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: GestureDetector(
                onTap: _varlikEkleSheet,
                child: Text("Yeni Ekle", style: bd(11, color: Colors.white, fw: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  AKADEMİ EKRANI
// ══════════════════════════════════════════════════════════════════

class AkademiEkrani extends StatefulWidget {
  const AkademiEkrani({super.key});
  @override
  State<AkademiEkrani> createState() => _AkademiEkraniState();
}

class _AkademiEkraniState extends State<AkademiEkrani> {
  Set<int> tamamlananlar = {};
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _tamamlananYukle();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _derslereScrolla() {
    _scrollCtrl.animateTo(
      340,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _tamamlananYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final kapsam = await _aktifKullaniciKapsami();
    final anahtar = _kullaniciBazliAnahtar('tamamlanan_dersler', kapsam);
    final liste = prefs.getStringList(anahtar) ?? [];
    if (mounted) setState(() => tamamlananlar = liste.map(int.parse).toSet());
  }

  Future<void> _dersiTamamla(int idx) async {
    final prefs = await SharedPreferences.getInstance();
    final kapsam = await _aktifKullaniciKapsami();
    final anahtar = _kullaniciBazliAnahtar('tamamlanan_dersler', kapsam);
    setState(() => tamamlananlar.add(idx));
    await prefs.setStringList(anahtar, tamamlananlar.map((e) => e.toString()).toList());
  }

  Future<void> _dersDetayaGit(int idx, Map<String, dynamic> d) async {
    final sonuc = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DersDetayEkrani(
          baslik: d["baslik"] as String,
          sure: d["sure"] as String,
          seviye: d["seviye"] as String,
          ikon: d["ikon"] as IconData,
          detayMetin: _detayIcerik(idx, d),
          tamamlandi: tamamlananlar.contains(idx),
        ),
      ),
    );

    if (sonuc == true && !tamamlananlar.contains(idx)) {
      await _dersiTamamla(idx);
    }
  }

    String _detayIcerik(int idx, Map<String, dynamic> d) {
    final icerik = d["icerik"] as String;
    final detayParca = _detayMakaleler[idx % _detayMakaleler.length];
    return "$icerik\n\n$detayParca";
  }

    static final List<String> _detayMakaleler = [
    "Nasıl Çalışır?\n"
      "LSTM modeli zaman serisini adım adım işler. Her adımda geçmiş bilginin ne kadarını tutacağına, ne kadarını unutacağına karar verir. "
      "Bu sayede kısa dönem gürültü ile uzun dönem trend ayrışır.\n\n"
      "Pratik Örnek\n"
      "- Fiyat son 10 günde yatay ama hacim artıyor.\n"
      "- MA20 yukarı kırıldı.\n"
      "- RSI nötrden yukarı dönüyor.\n"
      "Model bu kombinasyonu ivme başlangıcı olarak puanlayabilir.\n\n"
      "Uygulama Rutini\n"
      "1) Önce trendi tespit et (MA20/MA50).\n"
      "2) Sinyali hacimle doğrula.\n"
      "3) Stop-loss seviyeni işlem açmadan belirle.\n\n"
      "Kontrol\n"
      "- Tek sinyalle karar verme.\n"
      "- Sinyal gücü düşükse pozisyon boyutunu azalt.",
    "RSI Derin Okuma\n"
      "RSI tek başına AL/SAT butonu değildir; momentumun yorulup yorulmadığını anlatır. Aşırı alım bölgesinde uzun süre kalması da mümkündür.\n\n"
      "Kural Seti\n"
      "- RSI > 65 ise yükselişin gücünü teyit etmeden ek alım yapma.\n"
      "- RSI < 50 ise düşüşte panik satış yerine hacim teyidi ara.\n"
      "- RSI dönüşünü fiyat yapısıyla birlikte oku.\n\n"
      "Sık Hata\n"
      "RSI 70 oldu diye otomatik satış yapmak. Trend güçlü ise RSI uzun süre yüksek kalabilir.",
    "Volatilite Filtresi Neden Şart?\n"
      "Yüksek oynaklık döneminde model tahmini doğru yönde olsa bile fiyat yolu sert olabilir. Volatilite filtresi bu nedenle tahmini makul bantlara çeker.\n\n"
      "Nasıl Kullanılır\n"
      "1) Volatilite yüksekse pozisyonu küçült.\n"
      "2) Hedef ve stop mesafesini genişlet.\n"
      "3) Tek işlem yerine kademeli giriş yap.\n\n"
      "Kontrol Listesi\n"
      "- Son 20 gündeki ortalama günlük hareket nedir?\n"
      "- Haber akışı fiyatı aniden bozabilir mi?",
    "İşlem Hacmi Rehberi\n"
      "Hacim, fiyat hareketinin ciddiyetini gösterir. Yükseliş hacimsizse kalıcılık düşüktür; hacim destekliyorsa trend daha sağlıklıdır.\n\n"
      "Okuma Metodu\n"
      "- Fiyat yukarı + hacim yukarı: Güçlü trend olasılığı.\n"
      "- Fiyat yukarı + hacim aşağı: Dikkat, tuzak olabilir.\n"
      "- Fiyat yatay + hacim artışı: Yakında sert kırılım gelebilir.\n\n"
      "Disiplin\n"
      "Hacim teyidi olmayan sinyallerde pozisyonu azalt.",
    "MA20 & MA50 Stratejisi\n"
      "Hareketli ortalamalar trendin omurgasıdır. MA20 kısa vadeyi, MA50 orta vadeyi temsil eder.\n\n"
      "Yorumlama\n"
      "- MA20 > MA50 ve fiyat üstünde: Trend pozitif.\n"
      "- MA20 < MA50 ve fiyat altında: Trend zayıf.\n"
      "- Kesişim bölgeleri: Sahte sinyal riskine açık; hacimle teyit et.\n\n"
      "Uygulama\n"
      "Trend yönünde işlem aç, ters yönde acele etme.",
    "Diversifikasyon Planı\n"
      "Sepet yaklaşımı tek hisse riskini dağıtır. Amaç, tek bir kötü haberde tüm portföyün zarar görmesini engellemektir.\n\n"
      "Basit Dağılım Örneği\n"
      "- %50 ana hisse grubu\n"
      "- %20 büyüme teması\n"
      "- %20 döngüsel/emtia\n"
      "- %10 nakit tamponu\n\n"
      "Kontrol\n"
      "- Aynı sektörde aşırı yığılma var mı?\n"
      "- Korelasyonu yüksek varlıklara fazla mı yüklendin?",
    ];

  static final _dersler = [
    {
      "baslik": "LSTM Yapay Zekası Nasıl Çalışır?",
      "icerik":
          "Modelimiz sadece son fiyata bakmaz. Geçmiş 60 zaman dilimindeki fiyat hareketleri, işlem hacmi ve hareketli ortalamaları analiz ederek bir sonraki fiyat hareketini matematiksel olarak tahmin eder.\n\nLSTM (Long Short-Term Memory), geçmiş verilerdeki kalıpları öğrenerek geleceği tahmin eden özel bir sinir ağıdır.",
      "ikon": Icons.memory_rounded,
      "sure": "5 dk okuma",
      "seviye": "Başlangıç",
    },
    {
      "baslik": "RSI: Hisse Yorgunluk Göstergesi",
      "icerik":
          "RSI (Relative Strength Index), bir hissenin ne kadar alınıp satıldığını ölçer.\n\n• RSI > 65 → Aşırı alım (Şişkin) → SAT sinyali\n• RSI < 50 → Aşırı satım (Ucuzladı) → AL sinyali\n• RSI 50–65 → Nötr bölge",
      "ikon": Icons.show_chart_rounded,
      "sure": "7 dk okuma",
      "seviye": "Orta",
    },
    {
      "baslik": "Volatilite Filtresi",
      "icerik":
          "Yapay zeka bazen hayalperest tahminler yapabilir. Sisteme eklediğimiz volatilite filtresi, hissenin tarihsel dalgalanma kapasitesini hesaplar ve aşırı uç tahminleri gerçekçi sınırlar içine çeker.",
      "ikon": Icons.filter_list_rounded,
      "sure": "4 dk okuma",
      "seviye": "Orta",
    },
    {
      "baslik": "İşlem Hacmi Neden Önemli?",
      "icerik":
          "Fiyat artışı tek başına yeterli değildir. Düşük hacimle gelen artış bir tuzak olabilir.\n\nFiyat artarken yüksek hacim → Gerçek yükseliş trendi\nFiyat artarken düşük hacim → Sahte sinyal",
      "ikon": Icons.bar_chart_rounded,
      "sure": "8 dk okuma",
      "seviye": "İleri",
    },
    {
      "baslik": "Hareketli Ortalamalar (MA20 & MA50)",
      "icerik":
          "Hareketli ortalamalar, fiyatın kısa ve uzun vadeli eğilimini gösterir.\n\n• MA20: Son 20 günün ortalaması — kısa vadeli trend\n• MA50: Son 50 günün ortalaması — orta vadeli trend\n\nMA20, MA50'yi yukarı kestiğinde → Altın Kesişim (güçlü AL sinyali)\nMA20, MA50'yi aşağı kestiğinde → Ölüm Kesişimi (güçlü SAT sinyali)",
      "ikon": Icons.timeline_rounded,
      "sure": "6 dk okuma",
      "seviye": "Orta",
    },
    {
      "baslik": "Diversifikasyon: Sepete Koy",
      "icerik":
          "Tüm paranı tek bir hisseye yatırmak büyük risk taşır. Diversifikasyon farklı sektörlere, coğrafyalara ve varlık tiplerine yayılmak demektir.\n\n• Hisse + Kripto + Emtia karışımı riski dengeler\n• Korelasyonu düşük varlıklar birbirini dengeler\n• Hedef: Tek bir kötü haberden tüm portföyün etkilenmemesi",
      "ikon": Icons.pie_chart_rounded,
      "sure": "5 dk okuma",
      "seviye": "Başlangıç",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollCtrl,
      slivers: [
        SliverToBoxAdapter(child: _hero(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text("Temel Kavramlar", style: hl(22, fw: FontWeight.w700)),
              Text(
                "Modern yatırımcı için temel bilgiler.",
                style: bd(13, color: C.secondary),
              ),
            ]),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _dersKarti(i, _dersler[i]),
            childCount: _dersler.length,
          ),
        ),
        SliverToBoxAdapter(child: _progressSection(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 130)),
      ],
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: C.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: C.primaryCont,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Text("YENİ KURS",
              style: bd(11, color: Colors.white, fw: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        Text("AI Piyasalarında\nUzmanlaş",
            style: hl(28, color: Colors.white, fw: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          "Algoritmik ticaretin mekaniklerine dalın ve LSTM sinir ağlarımızın piyasaları nasıl yorumladığını öğrenin.",
          style: bd(13, color: C.primaryFixed.withOpacity(0.9)),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _derslereScrolla,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: C.surfaceLowest,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text("Öğrenmeye Başla",
                  style: bd(14, color: C.primary, fw: FontWeight.w700)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: C.primary, size: 16),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _dersKarti(int idx, Map<String, dynamic> d) {
    final tamamlandi = tamamlananlar.contains(idx);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: C.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: C.onSurface.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: tamamlandi ? C.primary.withOpacity(0.12) : C.primaryFixed.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: tamamlandi
                ? const Icon(Icons.check_circle_rounded, color: C.primary, size: 26)
                : Icon(d["ikon"] as IconData, color: C.primary, size: 24),
          ),
          title: Text(d["baslik"] as String,
              style: hl(15, fw: FontWeight.w700,
                  color: tamamlandi ? C.secondary : C.onSurface)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tamamlandi ? C.surfaceHigh : C.primaryFixed.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(d["sure"] as String,
                    style: bd(10, color: tamamlandi ? C.secondary : C.primary, fw: FontWeight.w600)),
              ),
              Text(d["seviye"] as String,
                  style: bd(10, color: C.secondary, fw: FontWeight.w600)),
              if (tamamlandi) ...[
                Text("✓ Tamamlandı", style: bd(10, color: C.primary, fw: FontWeight.w700)),
              ],
            ]),
          ),
          iconColor: C.primary, collapsedIconColor: C.outline,
          children: [
            Text(
              d["icerik"] as String,
              style: bd(14, color: C.secondary),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tamamlandi
                      ? "Bu ders tamamlandı. Dilersen tekrar göz atabilirsin."
                      : "Detaylı makaleyi açıp dersi tamamlayabilirsin.",
                  style: bd(12, color: C.secondary),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => _dersDetayaGit(idx, d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: C.primary,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.article_outlined, color: Colors.white, size: 15),
                        const SizedBox(width: 6),
                        Text("Okumaya Devam Et", style: bd(12, color: Colors.white, fw: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressSection(BuildContext context) {
    final toplam = _dersler.length;
    final tamamlanan = tamamlananlar.length;
    final oran = toplam > 0 ? tamamlanan / toplam : 0.0;
    final yuzde = (oran * 100).round();
    final kalan = toplam - tamamlanan;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: C.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        SizedBox(
          width: 72, height: 72,
          child: Stack(fit: StackFit.expand, children: [
            CircularProgressIndicator(
              value: oran,
              backgroundColor: C.surfaceHighest,
              color: C.primary,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
            ),
            Center(child: Text("$yuzde%", style: hl(16, fw: FontWeight.w800))),
          ]),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Yatırım Olgunluğun", style: hl(16, fw: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              tamamlanan == toplam
                  ? "Tebrikler! Tüm dersleri tamamladın 🎉"
                  : kalan == 1
                      ? "Son 1 ders kaldı, neredeyse bitirdin!"
                      : "$tamamlanan/$toplam ders tamamlandı. $kalan ders daha kaldı.",
              style: bd(12, color: C.secondary),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: oran,
                backgroundColor: C.surfaceHighest,
                color: C.primary,
                minHeight: 6,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class DersDetayEkrani extends StatelessWidget {
  final String baslik;
  final String sure;
  final String seviye;
  final IconData ikon;
  final String detayMetin;
  final bool tamamlandi;

  const DersDetayEkrani({
    super.key,
    required this.baslik,
    required this.sure,
    required this.seviye,
    required this.ikon,
    required this.detayMetin,
    required this.tamamlandi,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text("Ders Detayı", style: hl(18, fw: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: C.primaryFixed.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(ikon, color: C.primary, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(baslik, style: hl(24, fw: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: C.primaryFixed.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(sure, style: bd(11, color: C.primary, fw: FontWeight.w700)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: C.surfaceHigh,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(seviye, style: bd(11, color: C.secondary, fw: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: C.surfaceLowest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(detayMetin, style: bd(14, color: C.secondary, fw: FontWeight.w500,)),
                  ),
                ]),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: C.bg,
                boxShadow: [
                  BoxShadow(
                    color: C.onSurface.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (tamamlandi) {
                      Navigator.pop(context, false);
                    } else {
                      Navigator.pop(context, true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tamamlandi ? C.surfaceHigh : C.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    tamamlandi ? "Ders Tamamlandı" : "Bu Dersi Okudum",
                    style: bd(15, color: tamamlandi ? C.secondary : Colors.white, fw: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  PROFİL EKRANI
// ══════════════════════════════════════════════════════════════════

class ProfilEkrani extends StatefulWidget {
  final String kullaniciAdi;
  final ValueChanged<String>? onKullaniciAdiGuncellendi;
  const ProfilEkrani({
    super.key,
    required this.kullaniciAdi,
    this.onKullaniciAdiGuncellendi,
  });

  @override
  State<ProfilEkrani> createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  bool _bildirimFiyat    = true;
  bool _bildirimPiyasa   = false;
  bool _bildirimHaftalik = true;
  late String _kullaniciAdi;

  @override
  void initState() {
    super.initState();
    _kullaniciAdi = widget.kullaniciAdi;
    _bildirimleriYukle();
    _kullaniciAdiniYukle();
  }

  @override
  void didUpdateWidget(covariant ProfilEkrani oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kullaniciAdi != widget.kullaniciAdi) {
      _kullaniciAdi = widget.kullaniciAdi;
    }
  }

  Future<void> _bildirimleriYukle() async {
    final p = await SharedPreferences.getInstance();
    final kapsam = await _aktifKullaniciKapsami();
    final fiyatAnahtar = _kullaniciBazliAnahtar('bildirim_fiyat', kapsam);
    final piyasaAnahtar = _kullaniciBazliAnahtar('bildirim_piyasa', kapsam);
    final haftalikAnahtar = _kullaniciBazliAnahtar('bildirim_haftalik', kapsam);
    if (mounted) setState(() {
      _bildirimFiyat    = p.getBool(fiyatAnahtar) ?? true;
      _bildirimPiyasa   = p.getBool(piyasaAnahtar) ?? false;
      _bildirimHaftalik = p.getBool(haftalikAnahtar) ?? true;
    });
  }

  Future<void> _kullaniciAdiniYukle() async {
    final p = await SharedPreferences.getInstance();
    final kayitliAd = (p.getString('kullanici_adi') ?? '').trim();
    if (kayitliAd.isNotEmpty && mounted) {
      setState(() => _kullaniciAdi = kayitliAd);
    }
  }

  void _hesapAyarlariSheet() {
    final ctrl = TextEditingController(text: _kullaniciAdi);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.surfaceLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              media.viewInsets.bottom + media.padding.bottom + 24,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.outlineVar, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text("Hesap Ayarları", style: hl(20, fw: FontWeight.w700)),
              const SizedBox(height: 20),
              Text("Görünen Ad", style: bd(13, color: C.secondary, fw: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                style: bd(15),
                decoration: InputDecoration(
                  filled: true, fillColor: C.surfaceHigh,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final yeniAd = ctrl.text.trim();
                    if (yeniAd.isEmpty) {
                      yakinda(context, "Görünen ad boş bırakılamaz.");
                      return;
                    }
                    final prefs = await SharedPreferences.getInstance();
                    final email = (prefs.getString('kullanici_email') ?? '').trim();
                    await prefs.setString('kullanici_adi', yeniAd);

                    String? hata;
                    if (email.isNotEmpty) {
                      try {
                        final res = await http
                            .post(
                              Uri.parse("$kBaseUrl/ad-guncelle"),
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({
                                "email": email,
                                "yeni_ad": yeniAd,
                              }),
                            )
                            .timeout(const Duration(seconds: 60));
                        if (res.statusCode != 200) {
                          final data = json.decode(utf8.decode(res.bodyBytes));
                          hata = data["detail"]?.toString() ?? "Ad sunucuya kaydedilemedi.";
                        }
                      } catch (_) {
                        hata = "Sunucuya bağlanılamadı. Ad sadece cihazda güncellendi.";
                      }
                    }

                    if (mounted) {
                      setState(() => _kullaniciAdi = yeniAd);
                      widget.onKullaniciAdiGuncellendi?.call(yeniAd);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) yakinda(context, hata ?? "Ad güncellendi.");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Kaydet", style: bd(15, color: Colors.white, fw: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  void _bildirimSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.surfaceLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final media = MediaQuery.of(ctx);
          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                media.viewInsets.bottom + media.padding.bottom + 24,
              ),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.outlineVar, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text("Bildirim Tercihleri", style: hl(20, fw: FontWeight.w700)),
                const SizedBox(height: 16),
                _bildirimSatiri(ctx, setS, "Fiyat Uyarıları", "Belirlediğin hedef fiyatlara ulaşınca", _bildirimFiyat, (v) async {
                  setS(() => _bildirimFiyat = v);
                  setState(() => _bildirimFiyat = v);
                  final prefs = await SharedPreferences.getInstance();
                  final kapsam = await _aktifKullaniciKapsami();
                  final anahtar = _kullaniciBazliAnahtar('bildirim_fiyat', kapsam);
                  await prefs.setBool(anahtar, v);
                }),
                _bildirimSatiri(ctx, setS, "Piyasa Özeti", "Günlük piyasa açılış/kapanış özeti", _bildirimPiyasa, (v) async {
                  setS(() => _bildirimPiyasa = v);
                  setState(() => _bildirimPiyasa = v);
                  final prefs = await SharedPreferences.getInstance();
                  final kapsam = await _aktifKullaniciKapsami();
                  final anahtar = _kullaniciBazliAnahtar('bildirim_piyasa', kapsam);
                  await prefs.setBool(anahtar, v);
                }),
                _bildirimSatiri(ctx, setS, "Haftalık Rapor", "Her Pazartesi portföy özeti", _bildirimHaftalik, (v) async {
                  setS(() => _bildirimHaftalik = v);
                  setState(() => _bildirimHaftalik = v);
                  final prefs = await SharedPreferences.getInstance();
                  final kapsam = await _aktifKullaniciKapsami();
                  final anahtar = _kullaniciBazliAnahtar('bildirim_haftalik', kapsam);
                  await prefs.setBool(anahtar, v);
                }),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _bildirimSatiri(BuildContext ctx, StateSetter setS, String baslik, String aciklama, bool deger, Function(bool) onDegistir) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(baslik, style: bd(15, fw: FontWeight.w600)),
          Text(aciklama, style: bd(12, color: C.secondary)),
        ])),
        Switch(
          value: deger,
          onChanged: onDegistir,
          activeColor: Colors.white,
          activeTrackColor: C.primary,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: C.outlineVar,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );
  }

  void _guvenlikSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.surfaceLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              media.viewInsets.bottom + media.padding.bottom + 24,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.outlineVar, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text("Güvenlik & Biyometrik", style: hl(20, fw: FontWeight.w700)),
              const SizedBox(height: 20),
              _guvenlikSatiri(
                Icons.lock_outline_rounded,
                "Şifre Değiştir",
                "Son değişim: Bugün",
                onTap: () => _sifreDegistirSayfasiAc(ctx),
              ),
              const SizedBox(height: 12),
              _guvenlikSatiri(Icons.fingerprint_rounded, "Biyometrik Giriş", "Parmak izi / Yüz tanıma"),
              const SizedBox(height: 12),
              _guvenlikSatiri(Icons.shield_outlined, "İki Faktörlü Doğrulama", "SMS ile ek güvenlik"),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: C.primaryFixed.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: C.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text("Tüm veriler cihazında şifreli olarak saklanır.", style: bd(12, color: C.primary))),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _guvenlikSatiri(IconData ikon, String baslik, String alt, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => yakinda(context, "$baslik yakında aktif olacak."),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.surfaceLow, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(ikon, color: C.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(baslik, style: bd(14, fw: FontWeight.w600)),
            Text(alt, style: bd(11, color: C.secondary)),
          ])),
          Icon(Icons.chevron_right_rounded, color: C.outlineVar, size: 20),
        ]),
      ),
    );
  }

  void _destekSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.surfaceLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              media.viewInsets.bottom + media.padding.bottom + 24,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.outlineVar, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text("Destek", style: hl(20, fw: FontWeight.w700)),
              const SizedBox(height: 16),
              _destekKarti(
                Icons.help_outline_rounded,
                "Sık Sorulan Sorular",
                "Temel konular hakkında yanıtlar",
                onTap: () => _sssSayfasiAc(ctx),
              ),
              const SizedBox(height: 10),
              _destekKarti(Icons.mail_outline_rounded, "E-posta Gönder", "destek@aipredict.app"),
              const SizedBox(height: 10),
              _destekKarti(Icons.info_outline_rounded, "Uygulama Hakkında", "Versiyon 1.0.0"),
            ]),
          ),
        );
      },
    );
  }

  Widget _destekKarti(IconData ikon, String baslik, String alt, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => yakinda(context, "$baslik yakında aktif olacak."),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.surfaceLow, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(ikon, color: C.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(baslik, style: bd(14, fw: FontWeight.w600)),
            Text(alt, style: bd(11, color: C.secondary)),
          ])),
          Icon(Icons.chevron_right_rounded, color: C.outlineVar, size: 20),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final harf = _kullaniciAdi.isNotEmpty
      ? _kullaniciAdi[0].toUpperCase()
        : "?";

    return CustomScrollView(
      slivers: [
        // ── Top App Bar
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [C.bg, C.surfaceLow],
              ),
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration:
                    const BoxDecoration(color: C.primary, shape: BoxShape.circle),
                child: const Icon(Icons.insights_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text("AIPredict-Borsa",
                  style: hl(18, color: C.primary, fw: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: () => bildirimSheet(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: C.surfaceLow,
                      borderRadius: BorderRadius.circular(9999)),
                  child: const Icon(Icons.notifications_outlined,
                      color: C.primary, size: 20),
                ),
              ),
            ]),
          ),
        ),

        // ── Avatar + isim (kompakt)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: C.surfaceLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [C.primary, C.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: C.primaryFixed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(harf, style: hl(20, color: C.primary, fw: FontWeight.w800))),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: C.tertiary,
                        shape: BoxShape.circle,
                        border: Border.all(color: C.bg, width: 1.5),
                      ),
                      child: const Icon(Icons.verified_rounded, color: Colors.white, size: 10),
                    ),
                  ),
                ]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _kullaniciAdi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: hl(22, fw: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: C.primaryCont,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text("Premium", style: bd(11, color: Colors.white, fw: FontWeight.w700)),
                ),
              ]),
            ),
          ),
        ),

        // ── Hesap Yönetimi
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text("Hesap Yönetimi",
                    style: hl(16, color: C.onSurfaceVar, fw: FontWeight.w700)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: C.surfaceLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  _ayarSatiri(Icons.manage_accounts_rounded, "Hesap Ayarları", context, onTap: _hesapAyarlariSheet),
                  _ayarBolgu(),
                  _ayarSatiri(Icons.notifications_active_rounded, "Bildirim Tercihleri", context, onTap: _bildirimSheet),
                  _ayarBolgu(),
                  _ayarSatiri(Icons.fingerprint_rounded, "Güvenlik & Biyometrik", context, onTap: _guvenlikSheet),
                  _ayarBolgu(),
                  // Tema toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: C.surfaceLowest,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: const Icon(Icons.dark_mode_outlined,
                            color: C.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Text("Uygulama Teması",
                              style: bd(15, fw: FontWeight.w500))),
                      Switch(
                        value: appDarkMode.value,
                        onChanged: (v) async {
                          appDarkMode.value = v;
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('dark_mode', v);
                        },
                        activeColor: Colors.white,
                        activeTrackColor: C.primaryCont,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: C.outlineVar,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ]),
                  ),
                  _ayarBolgu(),
                  _ayarSatiri(Icons.contact_support_rounded, "Destek", context, onTap: _destekSheet),
                ]),
              ),
            ]),
          ),
        ),

        // ── Oturumu Kapat
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginEkrani()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: C.surfaceHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.logout_rounded, color: C.error, size: 20),
                  const SizedBox(width: 10),
                  Text("Oturumu Kapat",
                      style: hl(15, color: C.error, fw: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 130)),
      ],
    );
  }

  Widget _ayarSatiri(IconData ikon, String baslik, BuildContext context, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: C.surfaceLowest,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Icon(ikon, color: C.primary, size: 20),
      ),
      title: Text(baslik, style: bd(15, fw: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right_rounded, color: C.outlineVar, size: 22),
      onTap: onTap ?? () => yakinda(context, "$baslik yakında aktif olacak."),
    );
  }

  Widget _ayarBolgu() => Divider(
        height: 1, indent: 70, endIndent: 16,
        color: C.outlineVar.withOpacity(0.4),
      );

  void _sifreDegistirSayfasiAc(BuildContext sheetCtx) {
    Navigator.pop(sheetCtx);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SifreDegistirEkrani()),
    );
  }

  void _sssSayfasiAc(BuildContext sheetCtx) {
    Navigator.pop(sheetCtx);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SssEkrani()),
    );
  }
}

class SifreDegistirEkrani extends StatefulWidget {
  const SifreDegistirEkrani({super.key});

  @override
  State<SifreDegistirEkrani> createState() => _SifreDegistirEkraniState();
}

class _SifreDegistirEkraniState extends State<SifreDegistirEkrani> {
  final _eskiCtrl = TextEditingController();
  final _yeniCtrl = TextEditingController();
  final _tekrarCtrl = TextEditingController();
  bool _eskiGoster = false;
  bool _yeniGoster = false;
  bool _tekrarGoster = false;
  bool _yukleniyor = false;

  @override
  void dispose() {
    _eskiCtrl.dispose();
    _yeniCtrl.dispose();
    _tekrarCtrl.dispose();
    super.dispose();
  }

  Future<void> _sifreGuncelle() async {
    final eski = _eskiCtrl.text.trim();
    final yeni = _yeniCtrl.text.trim();
    final tekrar = _tekrarCtrl.text.trim();

    if (eski.isEmpty || yeni.isEmpty || tekrar.isEmpty) {
      yakinda(context, "Lütfen tüm alanları doldurun.");
      return;
    }
    if (yeni.length < 6) {
      yakinda(context, "Yeni şifre en az 6 karakter olmalı.");
      return;
    }
    if (yeni != tekrar) {
      yakinda(context, "Yeni şifreler eşleşmiyor.");
      return;
    }

    setState(() => _yukleniyor = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = (prefs.getString('kullanici_email') ?? '').trim();
      if (email.isEmpty) {
        yakinda(context, "Kullanıcı e-postası bulunamadı. Lütfen yeniden giriş yap.");
        return;
      }

      final res = await http
          .post(
            Uri.parse("$kBaseUrl/sifre-degistir"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email,
              "eski_sifre": eski,
              "yeni_sifre": yeni,
            }),
          )
          .timeout(const Duration(seconds: 60));

      final data = json.decode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 200) {
        yakinda(context, "Şifre başarıyla güncellendi.");
        if (mounted) Navigator.pop(context);
      } else {
        yakinda(context, data["detail"]?.toString() ?? "Şifre güncellenemedi.");
      }
    } catch (_) {
      yakinda(context, "Sunucuya bağlanılamadı.");
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text("Şifre Değiştir", style: hl(18, fw: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              "Hesabını daha güvenli tutmak için güçlü bir şifre belirle.",
              style: bd(13, color: C.secondary),
            ),
            const SizedBox(height: 20),
            _alanEtiket("Mevcut Şifre"),
            const SizedBox(height: 6),
            _sifreInput(
              _eskiCtrl,
              "Mevcut şifren",
              _eskiGoster,
              () => setState(() => _eskiGoster = !_eskiGoster),
            ),
            const SizedBox(height: 16),
            _alanEtiket("Yeni Şifre"),
            const SizedBox(height: 6),
            _sifreInput(
              _yeniCtrl,
              "En az 6 karakter",
              _yeniGoster,
              () => setState(() => _yeniGoster = !_yeniGoster),
            ),
            const SizedBox(height: 16),
            _alanEtiket("Yeni Şifre (Tekrar)"),
            const SizedBox(height: 6),
            _sifreInput(
              _tekrarCtrl,
              "Yeni şifreyi tekrar gir",
              _tekrarGoster,
              () => setState(() => _tekrarGoster = !_tekrarGoster),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.primaryFixed.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.shield_outlined, color: C.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Öneri: Harf, sayı ve özel karakter birlikte kullan.",
                    style: bd(12, color: C.primary, fw: FontWeight.w600),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _yukleniyor ? null : _sifreGuncelle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _yukleniyor
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        "Şifreyi Güncelle",
                        style: bd(15, color: Colors.white, fw: FontWeight.w700),
                      ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _alanEtiket(String text) =>
      Text(text, style: bd(13, color: C.onSurfaceVar, fw: FontWeight.w600));

  Widget _sifreInput(
    TextEditingController ctrl,
    String hint,
    bool goster,
    VoidCallback onToggle,
  ) {
    return TextField(
      controller: ctrl,
      obscureText: !goster,
      style: bd(15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: bd(14, color: C.outline.withOpacity(0.7)),
        filled: true,
        fillColor: C.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            goster ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: C.outline,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class SssEkrani extends StatelessWidget {
  const SssEkrani({super.key});

  static const _sss = [
    (
      "AIPredict-Borsa tahminleri nasıl üretiliyor?",
      "Tahminler; fiyat, hacim, volatilite ve haber etkisini birleştiren model çıktılarından üretilir. Uygulama yatırım tavsiyesi vermez, karar desteği sağlar."
    ),
    (
      "AL/SAT sinyali kesin midir?",
      "Hayır. Sinyaller olasılıksal bir değerlendirmedir. Özellikle yüksek volatilite dönemlerinde risk yönetimi (stop-loss, pozisyon boyutu) zorunludur."
    ),
    (
      "Portföyüm neden dalgalı görünüyor?",
      "Canlı piyasa akışı nedeniyle değerler anlık değişir. Ayrıca farklı varlık sınıfları farklı saatlerde hareket ettiği için toplam portföy gün içinde dalgalanır."
    ),
    (
      "Bildirimler bana neden geç geliyor?",
      "Cihazın pil optimizasyonu, internet bağlantısı ve işletim sistemi kısıtlamaları bildirimleri geciktirebilir. Profil > Bildirim Tercihleri bölümünden ayarları kontrol edin."
    ),
    (
      "Şifremi unuttum, ne yapmalıyım?",
      "Giriş ekranındaki 'Şifremi unuttum' bağlantısını kullanarak e-posta adresine sıfırlama bağlantısı gönderin. Bağlantı belirli süre içinde geçerlidir."
    ),
    (
      "Hangi piyasalarda analiz yapabiliyorum?",
      "Uygulama şu anda NASDAQ, BIST ve kripto tarafında temel tarama ve içerik desteği sunar. Kapsam yeni sürümlerde genişletilir."
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text("Sık Sorulan Sorular", style: hl(18, fw: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.surfaceLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.support_agent_rounded, color: C.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "En çok merak edilen konuları burada topladık.",
                  style: bd(13, color: C.secondary),
                ),
              ),
            ]),
          ),
          ..._sss.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: C.surfaceLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: C.outlineVar.withOpacity(0.35)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide.none,
                    ),
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide.none,
                    ),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    iconColor: C.primary,
                    collapsedIconColor: C.outline,
                    title: Text(item.$1, style: bd(14, fw: FontWeight.w700)),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(item.$2, style: bd(13, color: C.secondary, fw: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 4),
          Text(
            "Başka soruların için destek@aipredict.app adresine yazabilirsin.",
            textAlign: TextAlign.center,
            style: bd(12, color: C.secondary),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TARİH FORMATLAYICI — İngilizce ay adlarını Türkçe'ye çevirir
// ══════════════════════════════════════════════════════════════════

String turkceTarih(String t) {
  const ayIsim = ['Oca','Şub','Mar','Nis','May','Haz',
                  'Tem','Ağu','Eyl','Eki','Kas','Ara'];
  const gunIsim = ['Pzt','Sal','Çar','Per','Cum','Cmt','Paz'];
  const ayTam = {
    'January':   'Ocak',   'February': 'Şubat',   'March':     'Mart',
    'April':     'Nisan',  'May':      'Mayıs',    'June':      'Haziran',
    'July':      'Temmuz', 'August':   'Ağustos',  'September': 'Eylül',
    'October':   'Ekim',   'November': 'Kasım',    'December':  'Aralık',
  };
  const ayKisa = {
    'Jan': 'Oca', 'Feb': 'Şub', 'Mar': 'Mar', 'Apr': 'Nis',
    'May': 'May', 'Jun': 'Haz', 'Jul': 'Tem', 'Aug': 'Ağu',
    'Sep': 'Eyl', 'Oct': 'Eki', 'Nov': 'Kas', 'Dec': 'Ara',
  };
  // ISO datetime: "2024-01-15 14:30:00" veya "2024-01-15T14:30"
  // → "Sal, 15 Oca  14:30"  (gün adı + tarih + saat)
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})');
  final isoM = iso.firstMatch(t);
  if (isoM != null) {
    final yil = int.tryParse(isoM.group(1)!) ?? 2024;
    final ay  = int.tryParse(isoM.group(2)!) ?? 1;
    final gun = int.tryParse(isoM.group(3)!) ?? 1;
    final dt  = DateTime(yil, ay, gun);
    final gunAd = gunIsim[dt.weekday - 1]; // weekday: 1=Mon … 7=Sun
    return '$gunAd, ${isoM.group(3)} ${ayIsim[ay - 1]}  ${isoM.group(4)}:${isoM.group(5)}';
  }
  // ISO date only: "2024-01-15" → "Sal, 15 Oca 2024"
  final isoD = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  final isoDM = isoD.firstMatch(t);
  if (isoDM != null) {
    final yil = int.tryParse(isoDM.group(1)!) ?? 2024;
    final ay  = int.tryParse(isoDM.group(2)!) ?? 1;
    final gun = int.tryParse(isoDM.group(3)!) ?? 1;
    final dt  = DateTime(yil, ay, gun);
    final gunAd = gunIsim[dt.weekday - 1];
    return '$gunAd, ${isoDM.group(3)} ${ayIsim[ay - 1]} ${isoDM.group(1)}';
  }
  // Sadece saat: "14:30" veya "14:30:00" → olduğu gibi bırak
  if (RegExp(r'^\d{2}:\d{2}').hasMatch(t)) return t;
  // Tam & kısa ay adlarını Türkçe'ye çevir
  var s = t;
  ayTam.forEach((en, tr) { s = s.replaceAll(en, tr); });
  ayKisa.forEach((en, tr) { s = s.replaceAll(en, tr); });
  return s;
}

// ══════════════════════════════════════════════════════════════════
//  HİSSE DETAY EKRANI
// ══════════════════════════════════════════════════════════════════

class HisseDetaySayfasi extends StatefulWidget {
  final String hisseKodu;
  final bool favoriBaslangic;
  final Function(String)? onFavori;

  const HisseDetaySayfasi({
    super.key,
    required this.hisseKodu,
    this.favoriBaslangic = false,
    this.onFavori,
  });

  @override
  State<HisseDetaySayfasi> createState() => _HisseDetaySayfasiState();
}

class _HisseDetaySayfasiState extends State<HisseDetaySayfasi> {
  Map<String, dynamic>? veri;
  bool yukleniyor = true;
  late bool _favori;
  String aktifDilim = "1A";
  final List<String> dilimler    = ["1G", "1H", "1A", "1Y", "5Y"];
  static const List<String> dilimEtiket = ["1G", "1H", "1A", "1Y", "5Y"];

  List<dynamic> haberler       = [];
  bool haberYukleniyor         = false;

  // Grafik tooltip kalıcı gösterim
  int?   _persistentSpot;
  int?   _lastTouchedSpot; // setState olmadan güncellenir
  Timer? _tooltipTimer;

  @override
  void initState() {
    super.initState();
    _favori = widget.favoriBaslangic;
    _veriCek();
    _haberlerCek();
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }

  Future<void> _veriCek() async {
    setState(() => yukleniyor = true);
    try {
      final res = await http.get(Uri.parse(
          "$kBaseUrl/tahmin/${widget.hisseKodu}?zaman_dilimi=$aktifDilim"));
      if (res.statusCode == 200) {
        setState(() { veri = json.decode(res.body); yukleniyor = false; });
      } else {
        setState(() => yukleniyor = false);
      }
    } catch (_) {
      setState(() => yukleniyor = false);
    }
  }

  Future<void> _haberlerCek() async {
    setState(() => haberYukleniyor = true);
    try {
      final res = await http
          .get(Uri.parse("$kBaseUrl/haberler/${widget.hisseKodu}"))
          .timeout(const Duration(seconds: 60));
      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body);
        setState(() {
          haberler       = data['haberler'] ?? [];
          haberYukleniyor = false;
        });
      } else {
        if (mounted) setState(() => haberYukleniyor = false);
      }
    } catch (_) {
      if (mounted) setState(() => haberYukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: C.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.hisseKodu, style: hl(18, fw: FontWeight.w700)),
        centerTitle: true,
        actions: [
          if (widget.onFavori != null)
            IconButton(
              icon: Icon(
                _favori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _favori ? C.error : C.secondary,
                size: 24,
              ),
              onPressed: () {
                setState(() => _favori = !_favori);
                widget.onFavori!(widget.hisseKodu);
              },
            ),
        ],
      ),
      body: yukleniyor
          ? const Center(
              child: CircularProgressIndicator(
                  color: C.primary, strokeWidth: 2))
          : veri == null
              ? _hataEkrani()
              : _icerik(),
    );
  }

  Widget _hataEkrani() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.wifi_off_rounded, size: 56, color: C.outlineVar),
        const SizedBox(height: 16),
        Text("Veri alınamadı", style: hl(18)),
        const SizedBox(height: 8),
        Text("Sunucunun çalıştığından emin olun",
            style: bd(14, color: C.secondary)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _veriCek,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text("Tekrar Dene",
              style: bd(14, color: Colors.white, fw: FontWeight.w600)),
          style: ElevatedButton.styleFrom(backgroundColor: C.primary),
        ),
      ]),
    );
  }

  Widget _icerik() {
    final double rsi = (veri!['rsi_durumu'] as num).toDouble();
    final Color rsiRenk =
        rsi > 65 ? C.error : rsi < 50 ? C.primary : C.secondary;
    final String rsiMood =
        rsi > 65 ? "Gergin" : rsi < 50 ? "Sakin" : "Dengeli";

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24),
      child: Column(children: [
      // ── Fiyat
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text("\$${veri!['son_fiyat']}",
                      style: hl(38, fw: FontWeight.w800)),
                ),
                const SizedBox(height: 2),
                Text("Son fiyat", style: bd(12, color: C.secondary)),
              ]),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: rsiRenk.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: rsiRenk.withOpacity(0.4)),
              ),
              child: Text(
                "RSI ${rsi.toStringAsFixed(1)}",
                style: bd(13, color: rsiRenk, fw: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      // ── Zaman seçici
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: C.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: List.generate(dilimler.length, (i) {
              final d     = dilimler[i];
              final etiket = dilimEtiket[i];
              final aktif  = aktifDilim == d;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => aktifDilim = d);
                    _veriCek();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: aktif ? C.surfaceLowest : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: aktif
                          ? [BoxShadow(
                              color: C.onSurface.withOpacity(0.06),
                              blurRadius: 8,
                            )]
                          : null,
                    ),
                    child: Text(etiket,
                        textAlign: TextAlign.center,
                        style: bd(13,
                            color: aktif ? C.primary : C.secondary,
                            fw: aktif ? FontWeight.w700 : FontWeight.w400)),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      // ── Grafik
      SizedBox(
        height: 260,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Builder(builder: (ctx) {
            final gecmisSpots = _noktalar(veri!['gecmis_grafik_verisi']);
            final gercekBar = LineChartBarData(
              spots: gecmisSpots,
              isCurved: true, curveSmoothness: 0.3,
              color: C.primary, barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [C.primary.withOpacity(0.15), C.primary.withOpacity(0.0)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            );
            final tahminBar = LineChartBarData(
              spots: [
                FlSpot((veri!['gecmis_grafik_verisi'].length - 1).toDouble(), (veri!['son_fiyat'] as num).toDouble()),
                FlSpot((veri!['gecmis_grafik_verisi'].length).toDouble(), (veri!['yarinki_tahmin'] as num).toDouble()),
              ],
              isCurved: false, color: C.primaryCont, barWidth: 2,
              isStrokeCapRound: true, dashArray: [6, 4],
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, _b, ____) => FlDotCirclePainter(radius: 5, color: C.primaryCont, strokeWidth: 0),
              ),
            );
            return LineChart(LineChartData(
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: C.outlineVar, strokeWidth: 0.5),
              ),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              showingTooltipIndicators: _persistentSpot != null && _persistentSpot! < gecmisSpots.length ? [
                ShowingTooltipIndicators([LineBarSpot(gercekBar, 0, gecmisSpots[_persistentSpot!])]),
              ] : [],
              lineTouchData: LineTouchData(
                touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                  final spots = response?.lineBarSpots;
                  if (spots != null && spots.isNotEmpty) {
                    final spot = spots.firstWhere((s) => s.barIndex == 0, orElse: () => spots.first);
                    final index = spot.spotIndex;
                    _lastTouchedSpot = index;

                    if (_persistentSpot != index) {
                      setState(() => _persistentSpot = index);
                    }

                    // Dokunulan noktadaki bilgi kutusunu 3 sn boyunca görünür tut.
                    _tooltipTimer?.cancel();
                    _tooltipTimer = Timer(const Duration(seconds: 3), () {
                      if (mounted) setState(() => _persistentSpot = null);
                    });
                  }
                },
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (_) => C.surfaceLowest,
                  tooltipBorder: BorderSide(color: C.outlineVar),
                  getTooltipItems: (spots) => spots.map((s) {
                    if (s.barIndex == 1) {
                      return LineTooltipItem('', const TextStyle(), children: [
                        TextSpan(text: '🤖 AI Tahmini\n', style: bd(10, color: C.secondary, fw: FontWeight.w500)),
                        TextSpan(text: '\$${s.y.toStringAsFixed(2)}', style: hl(14, color: C.primaryCont, fw: FontWeight.w800)),
                      ]);
                    }
                    final idx = s.spotIndex.toInt();
                    final ham = veri!['gecmis_zaman_verisi'] != null && idx < (veri!['gecmis_zaman_verisi'] as List).length
                        ? veri!['gecmis_zaman_verisi'][idx] as String : '';
                    final tarih = ham.isNotEmpty ? turkceTarih(ham) : '';
                    return LineTooltipItem('', const TextStyle(), children: [
                      if (tarih.isNotEmpty) TextSpan(text: '$tarih\n', style: bd(10, color: C.secondary, fw: FontWeight.w500)),
                      TextSpan(text: '\$${s.y.toStringAsFixed(2)}', style: hl(14, color: C.primary, fw: FontWeight.w800)),
                    ]);
                  }).toList(),
                ),
                getTouchedSpotIndicator: (barData, spotIndexes) =>
                    spotIndexes.map((i) => TouchedSpotIndicatorData(
                      FlLine(color: C.outlineVar, strokeWidth: 1, dashArray: [4, 4]),
                      FlDotData(getDotPainter: (_, __, b, d) => FlDotCirclePainter(radius: 5, color: C.surfaceLowest, strokeWidth: 2, strokeColor: C.primary)),
                    )).toList(),
              ),
              lineBarsData: [gercekBar, tahminBar],
            ));
          }),
        ),
      ),
      // ── RSI mood card
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: C.surfaceLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: C.onSurface.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(children: [
            const Icon(Icons.psychology_outlined,
                color: C.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Piyasa Ruh Hali: $rsiMood",
                    style: bd(13, fw: FontWeight.w600)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rsi / 100,
                    backgroundColor: C.surfaceHigh,
                    color: rsiRenk,
                    minHeight: 6,
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Text(rsi.toStringAsFixed(1),
                style: hl(20, color: rsiRenk, fw: FontWeight.w800)),
          ]),
        ),
      ),
      // ── AI prediction card
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: C.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("LSTM AI Tahmini",
                    style: bd(12,
                        color: C.primaryFixed.withOpacity(0.9))),
                const SizedBox(height: 2),
                Text(veri!['hedef_zaman'] ?? "",
                    style: bd(11,
                        color: C.primaryFixed.withOpacity(0.7))),
              ]),
            ),
            const SizedBox(width: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text("\$${veri!['yarinki_tahmin']}",
                  style: hl(26, color: Colors.white, fw: FontWeight.w800)),
            ),
          ]),
        ),
      ),
      // ── Haberler
      if (haberYukleniyor)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator(color: C.primary, strokeWidth: 2)),
        )
      else if (haberler.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(children: [
            const Icon(Icons.newspaper_rounded, color: C.primary, size: 18),
            const SizedBox(width: 8),
            Text("Haberler", style: bd(15, fw: FontWeight.w700)),
          ]),
        ),
        ...haberler.map((h) => _haberSatiri(h)),
        const SizedBox(height: 8),
      ],
    ])); // Column + SingleChildScrollView
  }

  Widget _haberSatiri(Map<String, dynamic> h) {
    final String baslik = h['baslik'] ?? '';
    final String kaynak = h['kaynak'] ?? '';
    final String url    = h['url']    ?? '';
    final String resim  = h['resim']  ?? '';
    final int    zaman  = (h['zaman'] as num?)?.toInt() ?? 0;
    final String tarihStr = zaman > 0
        ? turkceTarih(
            DateTime.fromMillisecondsSinceEpoch(zaman * 1000)
                .toIso8601String()
                .substring(0, 10))
        : '';

    return GestureDetector(
      onTap: () async {
        if (url.isEmpty) return;
        try { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); }
        catch (_) {}
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.surfaceLowest,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: C.onSurface.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (resim.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(resim, width: 64, height: 64, fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => const SizedBox.shrink()),
            ),
          if (resim.isNotEmpty) const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(baslik, style: bd(13, fw: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                if (kaynak.isNotEmpty) ...[
                  Flexible(child: Text(kaynak, style: bd(11, color: C.secondary), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  Text('·', style: bd(11, color: C.secondary)),
                  const SizedBox(width: 6),
                ],
                if (tarihStr.isNotEmpty)
                  Flexible(child: Text(tarihStr, style: bd(11, color: C.secondary), overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios_rounded, color: C.secondary, size: 12),
        ]),
      ),
    );
  }

  List<FlSpot> _noktalar(List<dynamic> fiyatlar) => [
        for (int i = 0; i < fiyatlar.length; i++)
          FlSpot(i.toDouble(), (fiyatlar[i] as num).toDouble())
      ];
}
