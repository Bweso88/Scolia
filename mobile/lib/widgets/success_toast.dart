import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

/// Retour visuel animé après une action réussie (enregistrement d'un
/// devoir, d'une observation, envoi d'un message...) — une coche qui
/// apparaît en rebondissant, plutôt qu'un SnackBar plat et silencieux.
/// Disparaît seule après 2 secondes.
void showSuccessToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late OverlayEntry entree;

  entree = OverlayEntry(
    builder: (context) => _SuccessToastWidget(
      message: message,
      onTermine: () => entree.remove(),
    ),
  );

  overlay.insert(entree);
}

class _SuccessToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onTermine;

  const _SuccessToastWidget({required this.message, required this.onTermine});

  @override
  State<_SuccessToastWidget> createState() => _SuccessToastWidgetState();
}

class _SuccessToastWidgetState extends State<_SuccessToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controleur;

  @override
  void initState() {
    super.initState();
    _controleur = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _controleur.forward();
    Future.delayed(const Duration(milliseconds: 1900), () async {
      if (!mounted) return;
      await _controleur.reverse();
      widget.onTermine();
    });
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rebond = CurvedAnimation(parent: _controleur, curve: Curves.elasticOut, reverseCurve: Curves.easeIn);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: rebond,
          child: FadeTransition(
            opacity: _controleur,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: AppColors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
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
