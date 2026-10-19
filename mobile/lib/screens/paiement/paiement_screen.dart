import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/student.dart';
import '../../providers/child_provider.dart';
import '../../widgets/empty_state.dart';

/// Statut de paiement de la scolarité, pour chacun des enfants du parent
/// connecté (docs/PRODUCT_ARCHITECTURE.md §18) — une carte par enfant,
/// à jour ou en attente, sans détail de facturation (hors MVP).
class PaiementScreen extends StatelessWidget {
  const PaiementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final enfants = context.watch<ChildProvider>().enfants;
    final charge = context.watch<ChildProvider>().charge;

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: RefreshIndicator(
        onRefresh: () => context.read<ChildProvider>().charger(),
        child: charge
            ? const Center(child: CircularProgressIndicator())
            : enfants.isEmpty
                ? const EmptyState(
                    message: 'Aucun enfant lié',
                    sousTitre: 'Contactez l\'école pour activer votre compte parent.',
                    icone: Icons.payments_outlined,
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: enfants.map((e) => _carte(e)).toList(),
                  ),
      ),
    );
  }

  Widget _carte(Student e) {
    DateTime? depuis;
    try { if (e.activatedAt != null) depuis = DateTime.parse(e.activatedAt!); } catch (_) {}
    final couleur = e.isActivated ? AppColors.green : AppColors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: couleur.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(e.isActivated ? Icons.check_circle_outline : Icons.error_outline, color: couleur, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.nomComplet, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.navy)),
                if (e.schoolClass != null)
                  Text(e.schoolClass!.name, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 6),
                Text(
                  e.isActivated
                      ? (depuis != null ? 'À jour depuis le ${DateFormat('d MMMM yyyy', 'fr_FR').format(depuis)}' : 'À jour')
                      : 'Paiement en attente — contactez l\'administration',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: couleur),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
