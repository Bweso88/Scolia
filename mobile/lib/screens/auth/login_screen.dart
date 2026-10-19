import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../widgets/falling_emoji_overlay.dart';

/// Palette propre à cet écran — reprise à l'identique du design de
/// référence fourni par l'utilisateur ("Lumina Scholastic"), distincte de
/// la charte navy/amber du reste de l'app (conservée partout ailleurs :
/// fond du chat, transition/fond de l'écran de démarrage).
class _Lumina {
  static const primary = Color(0xFF004AC6);
  static const primaryContainer = Color(0xFF2563EB);
  static const blue700 = Color(0xFF1D4ED8);
  static const indigo500 = Color(0xFF6366F1);
  static const surface = Color(0xFFF8F9FF);
  static const onSurface = Color(0xFF0B1C30);
  static const onSurfaceVariant = Color(0xFF434655);
  static const slate50 = Color(0xFFF8FAFC);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const emerald = Color(0xFF059669);
}

enum _EtatBiometrie { repos, verification, reconnu }

/// Écran de connexion — formulaire unique (le rôle est reconnu côté
/// serveur, pas d'onglet Parent/Enseignant/Direction), repris du design
/// fourni par l'utilisateur en gardant la marque Scolia et son logo.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey        = GlobalKey<FormState>();
  final _emailCtrl      = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  bool  _motDePasseVisible = false;
  bool  _seSouvenir = true;
  bool  _boutonPresse = false;
  _EtatBiometrie _bioEtat = _EtatBiometrie.repos;

  late AnimationController _animCtrl;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _fadeAnim;
  late AnimationController _flotteCtrl;
  late AnimationController _reflectCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
    // Fond animé (orbes dégradés + étincelles) et reflet qui balaie le
    // bouton principal — purement décoratifs, en boucle continue.
    _flotteCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
    _reflectCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _flotteCtrl.dispose();
    _reflectCtrl.dispose();
    _emailCtrl.dispose();
    _motDePasseCtrl.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    try {
      await auth.seConnecter(_emailCtrl.text.trim(), _motDePasseCtrl.text);
      if (!mounted) return;
      // Un compte lié à plusieurs écoles doit choisir laquelle consulter
      // avant d'entrer (docs/PRODUCT_ARCHITECTURE.md §9).
      final destination = auth.aPlusieursEcoles ? '/auth/ecole' : '/accueil';
      _jouerAnimationConnexion(destination);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  /// Petite animation ludique jouée juste après la connexion, avant
  /// d'entrer dans l'application (docs/PRODUCT_ARCHITECTURE.md — accueil).
  void _jouerAnimationConnexion(String destination) {
    late OverlayEntry entree;
    entree = OverlayEntry(
      builder: (_) => FallingEmojiOverlay(
        onDone: () {
          entree.remove();
          if (mounted) context.go(destination);
        },
      ),
    );
    Overlay.of(context).insert(entree);
  }

  /// Purement décoratif pour l'instant (pas de vraie empreinte/Face ID
  /// branchée) — reproduit la simulation du design de référence plutôt que
  /// de laisser croire à une fonctionnalité absente.
  Future<void> _essayerBiometrie() async {
    if (_bioEtat != _EtatBiometrie.repos) return;
    setState(() => _bioEtat = _EtatBiometrie.verification);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _bioEtat = _EtatBiometrie.reconnu);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _bioEtat = _EtatBiometrie.repos);
  }

  void _motDePasseOublie() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Contactez l'administration de votre école pour réinitialiser votre mot de passe."),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final peutRevenir = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: _Lumina.surface,
      body: Stack(
        children: [
          Positioned.fill(child: _FondAnime(animation: _flotteCtrl)),
          SafeArea(
            child: Column(
              children: [
                _enTete(peutRevenir),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: Column(
                      children: [
                        FadeTransition(opacity: _fadeAnim, child: _hero()),
                        const SizedBox(height: 18),
                        SlideTransition(
                          position: _slideAnim,
                          child: FadeTransition(opacity: _fadeAnim, child: _carteConnexion(auth)),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(opacity: _fadeAnim, child: _pied()),
                      ],
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

  Widget _enTete(bool peutRevenir) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
      child: Row(
        children: [
          if (peutRevenir)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: _Lumina.onSurface),
              onPressed: () => Navigator.maybePop(context),
            )
          else
            const SizedBox(width: 12),
          Container(
            width: 32, height: 32,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _Lumina.primaryContainer.withOpacity(0.18)),
              boxShadow: [BoxShadow(color: _Lumina.primary.withOpacity(0.10), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.school_rounded, color: AppColors.navy, size: 18),
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(colors: [_Lumina.primary, _Lumina.blue700]).createShader(bounds),
            child: Text(
              'Scolia',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.white, letterSpacing: -0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return Column(
      children: [
        SizedBox(
          width: 128, height: 128,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 112, height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [_Lumina.primaryContainer.withOpacity(0.30), Colors.transparent]),
                ),
              ),
              AnimatedBuilder(
                animation: _flotteCtrl,
                builder: (context, child) {
                  final t = _flotteCtrl.value * 2 * math.pi;
                  return Transform.translate(
                    offset: Offset(0, math.sin(t) * 6),
                    child: Transform.rotate(angle: math.sin(t * 0.6) * 0.03, child: child),
                  );
                },
                child: Container(
                  width: 84, height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: _Lumina.primaryContainer.withOpacity(0.35), blurRadius: 26, offset: const Offset(0, 14)),
                    ],
                  ),
                  child: const Icon(Icons.school_rounded, color: AppColors.white, size: 42),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _Lumina.primaryContainer.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _Lumina.primaryContainer.withOpacity(0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_rounded, size: 14, color: _Lumina.primary),
              const SizedBox(width: 6),
              Text(
                'Espace École & Familles',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: _Lumina.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: _Lumina.onSurface),
            children: [
              const TextSpan(text: 'Bienvenue sur '),
              TextSpan(
                text: 'Scolia',
                style: TextStyle(
                  foreground: Paint()
                    ..shader = const LinearGradient(colors: [_Lumina.primary, _Lumina.indigo500]).createShader(const Rect.fromLTWH(0, 0, 140, 32)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "L'école et les familles, réunies en toute confiance.",
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _Lumina.onSurfaceVariant, height: 1.4),
        ),
      ],
    );
  }

  Widget _carteConnexion(AuthProvider auth) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.9)),
            boxShadow: [
              BoxShadow(color: _Lumina.onSurface.withOpacity(0.08), blurRadius: 45, offset: const Offset(0, 20)),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  gradient: LinearGradient(colors: [Color(0xFF60A5FA), _Lumina.primary, _Lumina.indigo500]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _etiquette('IDENTIFIANT'),
                      const SizedBox(height: 6),
                      _champ(
                        controller: _emailCtrl,
                        hint: 'vous@exemple.fr',
                        icone: Icons.alternate_email_rounded,
                        type: TextInputType.emailAddress,
                        autofill: const [AutofillHints.username],
                        validator: (v) => (v == null || !v.contains('@')) ? 'E-mail invalide' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _etiquette('MOT DE PASSE'),
                          GestureDetector(
                            onTap: _motDePasseOublie,
                            child: Text('Oublié ?',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _Lumina.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _champ(
                        controller: _motDePasseCtrl,
                        hint: '••••••••••••',
                        icone: Icons.lock_outline_rounded,
                        obscure: !_motDePasseVisible,
                        autofill: const [AutofillHints.password],
                        suffixe: IconButton(
                          icon: Icon(_motDePasseVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _Lumina.slate400, size: 20),
                          onPressed: () => setState(() => _motDePasseVisible = !_motDePasseVisible),
                        ),
                        onSubmitted: (_) => _seConnecter(),
                        validator: (v) => (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () => setState(() => _seSouvenir = !_seSouvenir),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _seSouvenir,
                                    onChanged: (v) => setState(() => _seSouvenir = v ?? true),
                                    activeColor: _Lumina.primary,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text('Se souvenir de moi',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _Lumina.onSurfaceVariant)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _boutonBiometrie(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _boutonConnexion(auth),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _etiquette(String texte) => Text(
        texte,
        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: _Lumina.onSurfaceVariant, letterSpacing: 0.6),
      );

  Widget _champ({
    required TextEditingController controller,
    required String hint,
    required IconData icone,
    TextInputType? type,
    List<String>? autofill,
    bool obscure = false,
    Widget? suffixe,
    void Function(String)? onSubmitted,
    String? Function(String?)? validator,
  }) {
    final bordure = OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _Lumina.slate300));
    return TextFormField(
      controller: controller,
      keyboardType: type,
      autofillHints: autofill,
      obscureText: obscure,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: _Lumina.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: _Lumina.slate400, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icone, size: 20, color: _Lumina.slate400),
        suffixIcon: suffixe,
        filled: true,
        fillColor: _Lumina.slate50,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: bordure,
        enabledBorder: bordure,
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _Lumina.primaryContainer, width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.red)),
      ),
    );
  }

  Widget _boutonBiometrie() {
    final enCours = _bioEtat == _EtatBiometrie.verification;
    final reconnu = _bioEtat == _EtatBiometrie.reconnu;
    final couleur = reconnu ? _Lumina.emerald : _Lumina.primary;

    return GestureDetector(
      onTap: _essayerBiometrie,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: couleur.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: couleur.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (enCours)
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: couleur))
            else
              Icon(reconnu ? Icons.check_circle_rounded : Icons.fingerprint_rounded, size: 15, color: couleur),
            const SizedBox(width: 6),
            Text(
              reconnu ? 'Reconnu !' : (enCours ? 'Vérification...' : 'Biométrie'),
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: couleur),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boutonConnexion(AuthProvider auth) {
    return GestureDetector(
      onTapDown: auth.charge ? null : (_) => setState(() => _boutonPresse = true),
      onTapUp: auth.charge ? null : (_) => setState(() => _boutonPresse = false),
      onTapCancel: auth.charge ? null : () => setState(() => _boutonPresse = false),
      onTap: auth.charge ? null : _seConnecter,
      child: AnimatedScale(
        scale: _boutonPresse ? 0.98 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 50,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [_Lumina.primary, _Lumina.primaryContainer, _Lumina.blue700]),
            boxShadow: [BoxShadow(color: _Lumina.primaryContainer.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Reflet qui balaie le bouton — purement décoratif.
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: LayoutBuilder(builder: (context, constraints) {
                    return AnimatedBuilder(
                      animation: _reflectCtrl,
                      builder: (context, _) {
                        final l = -constraints.maxWidth * 0.6 + _reflectCtrl.value * constraints.maxWidth * 2.2;
                        return Transform.translate(
                          offset: Offset(l, 0),
                          child: SizedBox(
                            width: constraints.maxWidth * 0.3,
                            height: constraints.maxHeight + 20,
                            child: Transform.rotate(
                              angle: -0.35,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(0.32), Colors.transparent]),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
              auth.charge
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.2)),
                        const SizedBox(width: 10),
                        Text('Connexion en cours...', style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Se connecter', style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: AppColors.white, size: 19),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pied() {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, size: 14, color: _Lumina.slate400),
            const SizedBox(width: 6),
            Text('Connexion sécurisée', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _Lumina.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 6),
        Text('Version 1.0 · Scolia', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _Lumina.slate400)),
      ],
    );
  }
}

/// Fond animé : orbes dégradés qui dérivent lentement + étincelles qui
/// pulsent + grille de points très discrète — repris du design de
/// référence ("Lumina Scholastic"), propre à cet écran de connexion.
class _FondAnime extends StatelessWidget {
  final Animation<double> animation;
  const _FondAnime({required this.animation});

  static const _orbes = <(double left, double top, double taille, List<Color> couleurs, double phase, double amplitude)>[
    (-70, -60, 280, [Color(0x5960A5FA), Color(0x2AA5B4FC), Color(0x00BAE6FD)], 0.0, 36),
    (220, 140, 300, [Color(0x33FCD34D), Color(0x337DD3FC), Color(0x0060A5FA)], 2.1, 30),
    (-40, 520, 320, [Color(0x263B82F6), Color(0x33A5B4FC), Color(0x0099F6E4)], 4.3, 26),
  ];

  static const _etincelles = <(double left, double top, IconData icone, Color couleur, double taille, double phase)>[
    (40, 110, Icons.auto_awesome_rounded, Color(0x992563EB), 19, 0.0),
    (320, 220, Icons.auto_awesome_rounded, Color(0x99F59E0B), 16, 1.6),
    (30, 420, Icons.school_rounded, Color(0x806366F1), 15, 3.2),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value * 2 * math.pi;
            return Stack(
              children: [
                CustomPaint(size: Size.infinite, painter: _GrillePoints()),
                ..._orbes.map((o) {
                  final a = t + o.$5;
                  final dx = math.sin(a) * o.$6;
                  final dy = math.cos(a * 0.8) * o.$6;
                  return Positioned(
                    left: o.$1 + dx, top: o.$2 + dy,
                    child: Container(
                      width: o.$3, height: o.$3,
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: o.$4)),
                    ),
                  );
                }),
                ..._etincelles.map((e) {
                  final a = t * 1.4 + e.$6;
                  final opacite = 0.4 + 0.5 * ((math.sin(a) + 1) / 2);
                  final dy = -math.sin(a).abs() * 10;
                  return Positioned(
                    left: e.$1, top: e.$2 + dy,
                    child: Opacity(opacity: opacite, child: Icon(e.$3, color: e.$4, size: e.$5)),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GrillePoints extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final peinture = Paint()..color = _Lumina.primary.withOpacity(0.035);
    const pas = 24.0;
    for (double x = 0; x < size.width; x += pas) {
      for (double y = 0; y < size.height; y += pas) {
        canvas.drawCircle(Offset(x, y), 0.9, peinture);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
