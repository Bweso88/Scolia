import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/child_provider.dart';

/// Sélecteur d'enfant affiché en haut des écrans parent dès que le compte
/// a plus d'un enfant (docs/PRODUCT_ARCHITECTURE.md §12) ; invisible s'il
/// n'y en a qu'un, pour ne pas encombrer l'écran.
class ChildSelector extends StatelessWidget {
  const ChildSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ChildProvider>();
    if (prov.enfants.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: prov.enfants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final enfant = prov.enfants[i];
          final actif = prov.selectionne?.id == enfant.id;
          return ChoiceChip(
            label: Text(enfant.firstName, style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: actif ? AppColors.white : AppColors.navy,
            )),
            selected: actif,
            selectedColor: AppColors.navy,
            backgroundColor: AppColors.light,
            onSelected: (_) => context.read<ChildProvider>().selectionner(enfant),
          );
        },
      ),
    );
  }
}
