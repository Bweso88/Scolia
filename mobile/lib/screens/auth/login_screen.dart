import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../widgets/pill_badge.dart';

enum _Profil { parent, enseignant, direction }

class _ProfilInfo {
  final String libelle;
  final IconData icone;
  final String badge;
  final String indice;

  const _ProfilInfo({required this.libelle, required this.icone, required this.badge, required this.indice});
}

const _profils = {
  _Profil.parent: _ProfilInfo(
    libelle: 'Parent',
    icone: Icons.family_restroom_rounded,
    badge: 'Compte responsable',
    indice: 'marie.dupont@email.fr',
  ),
  _Profil.enseignant: _ProfilInfo(
    libelle: 'Enseignant',
    icone: Icons.menu_book_rounded,
    badge: 'Compte enseignant',
    indice: 'prof.diallo@ecole.tld',
  ),
  _Profil.direction: _ProfilInfo(
    libelle: 'Direction',
    icone: Icons.corporate_fare_rounded,
    badge: 'Compte direction',
    indice: 'direction@ecole.tld',
  ),
};

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey        = GlobalKey<FormState>();
  final _emailCtrl      = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  bool  _motDePasseVisible = false;
  _Profil _profil = _Profil.parent;
  late  AnimationController _animCtrl;
  late  Animation<Offset>   _slideAnim;
  late  Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
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
      if (auth.aPlusieursEcoles) {
        context.go('/auth/ecole');
      } else {
        context.go('/accueil');
      }
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final info = _profils[_profil]!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.light, AppColors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ────────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Container(
                          width: 84, height: 84,
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.navy.withOpacity(0.30),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.school_rounded, color: AppColors.white, size: 42),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'SCOLIA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26, fontWeight: FontWeight.w900,
                            color: AppColors.navy, letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const PillBadge(
                          label: 'Espace École & Familles',
                          couleur: AppColors.navy,
                          icone: Icons.school_outlined,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Text(
                          'Bienvenue sur votre espace',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "L'école et les familles, réunies en toute confiance.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Sélecteur de profil ──────────────────────────────
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: _SelecteurProfil(
                        profil: _profil,
                        onChange: (p) => setState(() => _profil = p),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Card connexion ───────────────────────────────────
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navy.withOpacity(0.10),
                              blurRadius: 32,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'IDENTIFIANT',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11, fontWeight: FontWeight.w700,
                                      color: AppColors.muted, letterSpacing: 0.6,
                                    ),
                                  ),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child: PillBadge(
                                      key: ValueKey(info.badge),
                                      label: info.badge,
                                      couleur: AppColors.amber,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // ── Email ──────────────────────────────
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.username],
                                style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.navy),
                                decoration: InputDecoration(
                                  hintText: info.indice,
                                  prefixIcon: const Icon(Icons.mail_outline),
                                ),
                                validator: (v) {
                                  if (v == null || !v.contains('@')) return 'E-mail invalide';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              Text(
                                'MOT DE PASSE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: AppColors.muted, letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // ── Mot de passe ───────────────────────
                              TextFormField(
                                controller: _motDePasseCtrl,
                                obscureText: !_motDePasseVisible,
                                autofillHints: const [AutofillHints.password],
                                style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.navy),
                                decoration: InputDecoration(
                                  hintText: '••••••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _motDePasseVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: AppColors.muted,
                                    ),
                                    onPressed: () => setState(() => _motDePasseVisible = !_motDePasseVisible),
                                  ),
                                ),
                                onFieldSubmitted: (_) => _seConnecter(),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Mot de passe requis';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              // ── Bouton ─────────────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: auth.charge ? null : _seConnecter,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.navy,
                                    foregroundColor: AppColors.white,
                                    elevation: 6,
                                    shadowColor: AppColors.navy.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: auth.charge
                                      ? const SizedBox(
                                          height: 22, width: 22,
                                          child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Se connecter',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 16, fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.arrow_forward_rounded, size: 20),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 14, color: AppColors.muted),
                        const SizedBox(width: 6),
                        Text(
                          'Connexion sécurisée',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0 · Scolia',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sélecteur de profil (Parent / Enseignant / Direction) — purement
/// visuel : il adapte le libellé/l'indice affichés au-dessus des champs,
/// mais l'identification réelle reste déterminée par les identifiants
/// saisis (le rôle vient du compte, pas de cet onglet).
class _SelecteurProfil extends StatelessWidget {
  final _Profil profil;
  final ValueChanged<_Profil> onChange;

  const _SelecteurProfil({required this.profil, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: _Profil.values.map((p) {
          final selectionne = p == profil;
          final info = _profils[p]!;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChange(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selectionne ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: selectionne
                      ? [BoxShadow(color: AppColors.navy.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(info.icone, size: 18, color: selectionne ? AppColors.navy : AppColors.muted),
                    const SizedBox(height: 4),
                    Text(
                      info.libelle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: selectionne ? FontWeight.w700 : FontWeight.w500,
                        color: selectionne ? AppColors.navy : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
