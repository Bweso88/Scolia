import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import '../../config/theme.dart';
import '../../widgets/bulletin_widget.dart';
import '../../widgets/empty_state.dart';
import '../../models/periode.dart';

class BulletinScreen extends StatefulWidget {
  final int eleveId;
  final int periodeId;

  const BulletinScreen({super.key, required this.eleveId, required this.periodeId});

  @override
  State<BulletinScreen> createState() => _BulletinScreenState();
}

class _BulletinScreenState extends State<BulletinScreen> {
  int _periodeSelectionnee = 0;
  List<Periode> _periodes = [];

  @override
  void initState() {
    super.initState();
    _periodeSelectionnee = widget.periodeId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<NotesProvider>();
      await prov.chargerPeriodes();
      setState(() => _periodes = prov.periodes);
      prov.chargerBulletin(widget.eleveId, _periodeSelectionnee);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Bulletin')),
      body: Column(
        children: [
          // Sélecteur de période
          if (_periodes.isNotEmpty)
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text('Période :', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.muted)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _periodeSelectionnee,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      items: _periodes.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.nom, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                      )).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _periodeSelectionnee = v);
                        prov.chargerBulletin(widget.eleveId, v);
                      },
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          // Contenu
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => prov.chargerBulletin(widget.eleveId, _periodeSelectionnee),
              child: prov.charge
                  ? const Center(child: CircularProgressIndicator())
                  : prov.notesMatieres.isEmpty
                      ? const EmptyState(
                          message: 'Aucune note disponible',
                          sousTitre: 'Les notes apparaîtront ici une fois saisies par l\'enseignant.',
                          icone: Icons.bar_chart_outlined,
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              // Résumé moyenne
                              if (prov.moyenneGenerale != null)
                                Container(
                                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.navy,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Moyenne générale', style: GoogleFonts.plusJakartaSans(color: AppColors.white.withOpacity(0.7), fontSize: 12)),
                                          Text(
                                            '${prov.moyenneGenerale!.toStringAsFixed(2)} / 20',
                                            style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                      _indicateurMoyenne(prov.moyenneGenerale!),
                                    ],
                                  ),
                                ),
                              BulletinWidget(
                                notesMatieres: prov.notesMatieres,
                                moyenneGenerale: prov.moyenneGenerale,
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicateurMoyenne(double moy) {
    final Color c;
    final String label;
    if (moy >= 14) { c = AppColors.green;  label = 'Bien'; }
    else if (moy >= 10) { c = AppColors.amber; label = 'Passable'; }
    else { c = AppColors.red; label = 'Insuffisant'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: c.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.4))),
      child: Text(label, style: GoogleFonts.plusJakartaSans(color: c, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}
