import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/frais_status_badge.dart';
import '../../models/frais_scolarite.dart';
import '../../services/frais_service.dart';

class DetailFraisScreen extends StatefulWidget {
  final int eleveId;
  const DetailFraisScreen({super.key, required this.eleveId});

  @override
  State<DetailFraisScreen> createState() => _DetailFraisScreenState();
}

class _DetailFraisScreenState extends State<DetailFraisScreen> {
  final _service = FraisService();
  List<FraisScolarite> _frais = [];
  ResumeFrais? _resume;
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    try {
      final results = await Future.wait([
        _service.getFraisEleve(widget.eleveId),
        _service.getResume(widget.eleveId),
      ]);
      setState(() {
        _frais  = results[0] as List<FraisScolarite>;
        _resume = results[1] as ResumeFrais;
      });
    } catch (_) {
    } finally {
      setState(() => _charge = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');

    return Scaffold(
      appBar: AppBar(title: const Text('Détail des frais')),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _charge
            ? const Center(child: CircularProgressIndicator())
            : _frais.isEmpty
                ? const EmptyState(
                    message: 'Aucun frais enregistré',
                    sousTitre: 'Les frais de scolarité apparaîtront ici.',
                    icone: Icons.receipt_long_outlined,
                  )
                : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Résumé en haut
                      if (_resume != null)
                        SliverToBoxAdapter(child: _carteResume(_resume!, fmt)),
                      // Liste mois par mois
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _LigneMois(frais: _frais[i], fmt: fmt),
                            childCount: _frais.length,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _carteResume(ResumeFrais r, NumberFormat fmt) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statBlanche('Total dû',   '${fmt.format(r.totalDu)} FCFA'),
              _statBlanche('Payé',       '${fmt.format(r.totalPaye)} FCFA'),
              _statBlanche('Solde',      '${fmt.format(r.solde)} FCFA'),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: r.tauxPaiement.clamp(0.0, 1.0),
              backgroundColor: AppColors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(r.toutPaye ? AppColors.green : AppColors.amber),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(r.tauxPaiement * 100).toStringAsFixed(0)}% payé',
                  style: GoogleFonts.plusJakartaSans(color: AppColors.white.withOpacity(0.8), fontSize: 12)),
              Text('${r.nbPayes}/${r.nbMois} mois',
                  style: GoogleFonts.plusJakartaSans(color: AppColors.white.withOpacity(0.8), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBlanche(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(color: AppColors.white.withOpacity(0.6), fontSize: 11)),
        Text(val,   style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}

class _LigneMois extends StatelessWidget {
  final FraisScolarite frais;
  final NumberFormat fmt;

  const _LigneMois({required this.frais, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: frais.couleurStatut.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  frais.moisNom.substring(0, 3),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: frais.couleurStatut,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(frais.moisNom,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.navy)),
                  Text(
                    frais.statut == 'paye'
                        ? 'Payé le ${frais.datePaiement ?? '—'}'
                        : frais.statut == 'partiel'
                            ? '${fmt.format(frais.montantPaye)} / ${fmt.format(frais.montantDu)} FCFA'
                            : '${fmt.format(frais.montantDu)} FCFA dus',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            FraisStatusBadge(statut: frais.statut),
          ],
        ),
      ),
    );
  }
}
