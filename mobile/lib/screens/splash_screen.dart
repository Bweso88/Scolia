import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _naviguer();
  }

  Future<void> _naviguer() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    context.go(auth.estConnecte ? '/accueil' : '/auth/connexion');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Motif de fond (le même que la proposition commerciale), sur une
          // base claire plutôt que le bleu nuit plein d'origine.
          Container(
            decoration: const BoxDecoration(
              color: AppColors.light,
              image: DecorationImage(
                image: AssetImage('assets/images/chat_background.png'),
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          // Voile bleu nuit très atténué, comme si son intensité était
          // baissée, pour laisser transparaître le motif tout en gardant
          // l'identité de la marque.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x80091B47), Color(0x40091B47)],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.school, color: AppColors.white, size: 44),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Scolia',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Liaison scolaire simplifiée',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.navy.withOpacity(0.75),
                    ),
                  ),
                  const SizedBox(height: 48),
                  const CircularProgressIndicator(
                    color: AppColors.navy,
                    strokeWidth: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
