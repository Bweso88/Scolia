import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Enveloppe un élément de liste pour permettre de l'archiver (glisser vers
/// la droite) ou de le supprimer (glisser vers la gauche, avec
/// confirmation) — pour que l'espace, même en scrollant jusqu'en bas, ne
/// reste jamais trop encombré (annonces, comportement, messagerie).
class ArchivableTile extends StatelessWidget {
  final Object cle;
  final Widget child;
  final VoidCallback onArchiver;
  final VoidCallback onSupprimer;

  const ArchivableTile({
    super.key,
    required this.cle,
    required this.child,
    required this.onArchiver,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(cle),
      background: _fond(couleur: AppColors.muted, icone: Icons.archive_outlined, texte: 'Archiver', alignement: Alignment.centerLeft),
      secondaryBackground: _fond(couleur: AppColors.red, icone: Icons.delete_outline, texte: 'Supprimer', alignement: Alignment.centerRight),
      confirmDismiss: (direction) async {
        if (direction != DismissDirection.endToStart) return true;
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Supprimer définitivement ?'),
                content: const Text('Cette action est irréversible.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Supprimer', style: TextStyle(color: AppColors.red)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onArchiver();
        } else {
          onSupprimer();
        }
      },
      child: child,
    );
  }

  Widget _fond({required Color couleur, required IconData icone, required String texte, required Alignment alignement}) {
    final estGauche = alignement == Alignment.centerLeft;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(16)),
      alignment: alignement,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: estGauche
            ? [Icon(icone, color: AppColors.white), const SizedBox(width: 8), Text(texte, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold))]
            : [Text(texte, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)), const SizedBox(width: 8), Icon(icone, color: AppColors.white)],
      ),
    );
  }
}
