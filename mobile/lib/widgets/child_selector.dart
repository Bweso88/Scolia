import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/child_provider.dart';

/// Sélecteur d'enfant affiché en haut des écrans parent dès que le compte
/// a plus d'un enfant (docs/PRODUCT_ARCHITECTURE.md §12) ; invisible s'il
/// n'y en a qu'un, pour ne pas encombrer l'écran.
///
/// Repris du mockup "Scholarly" fourni par l'utilisateur : un "interrupteur"
/// pleine largeur, un segment par enfant — actif en dégradé bleu avec
/// pastille verte, inactif en gris clair avec pastille neutre.
class ChildSelector extends StatelessWidget {
  const ChildSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ChildProvider>();
    if (prov.enfants.length <= 1) return const SizedBox.shrink();

    return Row(
      children: prov.enfants.asMap().entries.map((entry) {
        final i = entry.key;
        final enfant = entry.value;
        final actif = prov.selectionne?.id == enfant.id;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == prov.enfants.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () => context.read<ChildProvider>().selectionner(enfant),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: actif ? const LinearGradient(colors: [AppColors.blue, Color(0xFF4F46E5)]) : null,
                  color: actif ? null : AppColors.light,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: actif ? AppColors.green : AppColors.muted, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        enfant.firstName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: actif ? AppColors.white : AppColors.navy),
                      ),
                    ),
                    if (enfant.schoolClass != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: actif ? AppColors.white.withOpacity(0.2) : AppColors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(enfant.schoolClass!.name,
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: actif ? AppColors.white : AppColors.muted)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
