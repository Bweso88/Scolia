import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey       = GlobalKey<FormState>();
  final _emailCtrl     = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  bool  _motDePasseVisible = false;
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B3E), Color(0xFF1A3060)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ────────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.amber,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.amber.withOpacity(0.45),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'SCOLIA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 30, fontWeight: FontWeight.w900,
                            color: Colors.white, letterSpacing: 5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Le cahier de liaison numérique',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: Colors.white.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Card connexion ───────────────────────────────────
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connexion',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Identifiants fournis par votre école',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13, color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 26),

                              // ── Email ──────────────────────────────
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.username],
                                style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.navy),
                                decoration: const InputDecoration(
                                  labelText: 'Adresse e-mail',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: (v) {
                                  if (v == null || !v.contains('@')) return 'E-mail invalide';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // ── Mot de passe ───────────────────────
                              TextFormField(
                                controller: _motDePasseCtrl,
                                obscureText: !_motDePasseVisible,
                                autofillHints: const [AutofillHints.password],
                                style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.navy),
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe',
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

                              const SizedBox(height: 28),

                              // ── Bouton ─────────────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: auth.charge ? null : _seConnecter,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.navy,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: AppColors.navy.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: auth.charge
                                      ? const SizedBox(
                                          height: 22, width: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : Text(
                                          'Se connecter',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16, fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Version 1.0 · Scolia',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white.withOpacity(0.3)),
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
