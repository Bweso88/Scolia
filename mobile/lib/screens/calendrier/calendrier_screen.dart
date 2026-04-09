import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/evenements_provider.dart';
import '../../models/evenement.dart';
import '../../config/theme.dart';
import '../../widgets/empty_state.dart';

class CalendrierScreen extends StatefulWidget {
  const CalendrierScreen({super.key});

  @override
  State<CalendrierScreen> createState() => _CalendrierScreenState();
}

class _CalendrierScreenState extends State<CalendrierScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvenementsProvider>().charger();
    });
  }

  static const _icones = {
    'reunion':  Icons.group_outlined,
    'sortie':   Icons.directions_walk_outlined,
    'vacances': Icons.beach_access_outlined,
    'fete':     Icons.celebration_outlined,
    'examen':   Icons.edit_note_outlined,
    'autre':    Icons.event_outlined,
  };

  static const _couleurs = {
    'reunion':  AppColors.blue,
    'sortie':   AppColors.green,
    'vacances': AppColors.amber,
    'fete':     AppColors.purple,
    'examen':   AppColors.red,
    'autre':    AppColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<EvenementsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Calendrier')),
      body: RefreshIndicator(
        onRefresh: () => prov.charger(),
        child: prov.charge
            ? const Center(child: CircularProgressIndicator())
            : prov.evenements.isEmpty
                ? EmptyState(
                    message: 'Aucun événement',
                    sousTitre: 'Les événements scolaires apparaîtront ici.',
                    icone: Icons.calendar_today_outlined,
                    onAction: () => prov.charger(),
                    libelleAction: 'Actualiser',
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: prov.evenements.length,
                    itemBuilder: (_, i) => _CarteEvenement(
                      evenement: prov.evenements[i],
                      icone: _icones[prov.evenements[i].type] ?? Icons.event_outlined,
                      couleur: _couleurs[prov.evenements[i].type] ?? AppColors.muted,
                    ),
                  ),
      ),
    );
  }
}

class _CarteEvenement extends StatelessWidget {
  final Evenement evenement;
  final IconData icone;
  final Color couleur;

  const _CarteEvenement({required this.evenement, required this.icone, required this.couleur});

  @override
  Widget build(BuildContext context) {
    DateTime? date;
    try { date = DateTime.parse(evenement.dateDebut); } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (date != null) ...[
                    Text(DateFormat('d', 'fr_FR').format(date),
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: couleur)),
                    Text(DateFormat('MMM', 'fr_FR').format(date),
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: couleur)),
                  ] else
                    Icon(icone, color: couleur, size: 24),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(evenement.titre, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.navy)),
                  if (evenement.lieu != null) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.muted),
                      const SizedBox(width: 2),
                      Text(evenement.lieu!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted)),
                    ]),
                  ],
                  if (evenement.description != null && evenement.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(evenement.description!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.body), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
