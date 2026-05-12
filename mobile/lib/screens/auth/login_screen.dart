import 'package:flutter/material.dart';
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
  final _formKey     = GlobalKey<FormState>();
  final _telCtrl     = TextEditingController(text: '+242');
  final _codeCtrl    = TextEditingController();
  bool  _codeVisible = false;
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
    _telCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    try {
      await auth.seConnecter(_telCtrl.text.trim(), _codeCtrl.text.trim());
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
                          'Plateforme scolaire',
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

                              // ── Téléphone ──────────────────────────
                              _ChampSaisie(
                                controller:  _telCtrl,
                                label:       'Numéro de téléphone',
                                icone:       Icons.phone_outlined,
                                clavier:     TextInputType.phone,
                                validateur:  (v) {
                                  if (v == null || v.trim().length < 8) return 'Numéro invalide';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // ── Code ───────────────────────────────
                              TextFormField(
                                controller:    _codeCtrl,
                                obscureText:   !_codeVisible,
                                textCapitalization: TextCapitalization.characters,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18, fontWeight: FontWeight.w700,
                                  color: AppColors.navy, letterSpacing: 3,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Code d\'accès',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _codeVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: AppColors.muted,
                                    ),
                                    onPressed: () => setState(() => _codeVisible = !_codeVisible),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.navy, width: 2),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().length < 4) return 'Code requis';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 13, color: AppColors.muted),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'Parents : code dossier reçu de l\'école.\nEnseignants : code communiqué par l\'administration.',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted),
                                    ),
                                  ),
                                ],
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

class _ChampSaisie extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icone;
  final TextInputType clavier;
  final String? Function(String?)? validateur;

  const _ChampSaisie({
    required this.controller,
    required this.label,
    required this.icone,
    required this.clavier,
    this.validateur,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:  controller,
      keyboardType: clavier,
      style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.navy),
      decoration: InputDecoration(
        labelText:   label,
        prefixIcon:  Icon(icone),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.navy, width: 2),
        ),
      ),
      validator: validateur,
    );
  }
}
