import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/empty_state.dart';
import '../../models/dossier.dart';
import '../../models/frais_scolarite.dart';
import '../../services/api_service.dart';
import '../../services/frais_service.dart';

class FraisScreen extends StatefulWidget {
  const FraisScreen({super.key});

  @override
  State<FraisScreen> createState() => _FraisScreenState();
}

class _FraisScreenState extends State<FraisScreen> {
  final _fraisService = FraisService();
  List<_DossierAvecResume> _items = [];
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    try {
      final data = await apiService.get('/dossiers');
      final dossiers = (data['dossiers'] as List)
          .map((e) => Dossier.fromJson(e as Map<String, dynamic>))
          .where((d) => d.actif)
          .toList();

      final items = await Future.wait(dossiers.map((d) async {
        try {
          final resume = await _fraisService.getResume(d.eleveId);
          return _DossierAvecResume(dossier: d, resume: resume);
        } catch (_) {
          return _DossierAvecResume(dossier: d, resume: null);
        }
      }));

      setState(() => _items = items);
    } catch (_) {
    } finally {
      setState(() => _charge = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frais de scolarité')),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _charge
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? const EmptyState(
                    message: 'Aucun dossier actif',
                    sousTitre: 'Activez votre dossier pour suivre les frais.',
                    icone: Icons.account_balance_wallet_outlined,
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _CarteFrais(item: _items[i]),
                  ),
      ),
      bottomNavigationBar: const BottomNav(indexActuel: 4),
    );
  }
}

class _DossierAvecResume {
  final Dossier dossier;
  final ResumeFrais? resume;
  const _DossierAvecResume({required this.dossier, required this.resume});
}

class _CarteFrais extends StatelessWidget {
  final _DossierAvecResume item;
  const _CarteFrais({required this.item});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    final resume = item.resume;

    Color couleurBadge;
    String labelBadge;
    if (resume == null) {
      couleurBadge = AppColors.muted; labelBadge = 'Chargement…';
    } else if (resume.toutPaye) {
      couleurBadge = AppColors.green; labelBadge = 'Tout payé';
    } else if (resume.nbImpayes > 0) {
      couleurBadge = AppColors.red; labelBadge = 'En retard';
    } else {
      couleurBadge = AppColors.orange; labelBadge = 'Partiel';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/frais/${item.dossier.eleveId}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.light,
                    child: Text(
                      item.dossier.prenom.isNotEmpty ? item.dossier.prenom[0].toUpperCase() : '?',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.dossier.nomComplet,
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.navy)),
                        Text(item.dossier.classeNom ?? '',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: couleurBadge.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: couleurBadge.withOpacity(0.3)),
                    ),
                    child: Text(labelBadge,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: couleurBadge)),
                  ),
                ],
              ),
              if (resume != null) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: resume.tauxPaiement.clamp(0.0, 1.0),
                    backgroundColor: AppColors.light,
                    valueColor: AlwaysStoppedAnimation(
                      resume.toutPaye ? AppColors.green : AppColors.amber,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat('Payé', '${fmt.format(resume.totalPaye)} FCFA', AppColors.green),
                    _stat('Solde', '${fmt.format(resume.solde)} FCFA',
                        resume.solde > 0 ? AppColors.red : AppColors.green),
                    _stat('Total', '${fmt.format(resume.totalDu)} FCFA', AppColors.body),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Voir le détail', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.navy, fontWeight: FontWeight.w600)),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.navy),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String valeur, Color couleur) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.muted)),
        Text(valeur, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: couleur)),
      ],
    );
  }
}
