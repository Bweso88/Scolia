import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/empty_state.dart';
import '../../models/dossier.dart';
import '../../models/periode.dart';
import '../../services/api_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Dossier> _dossiers = [];
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _charger();
      context.read<NotesProvider>().chargerPeriodes();
    });
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    try {
      final data = await apiService.get('/dossiers');
      setState(() {
        _dossiers = (data['dossiers'] as List)
            .map((e) => Dossier.fromJson(e as Map<String, dynamic>))
            .where((d) => d.actif)
            .toList();
      });
    } catch (_) {
    } finally {
      setState(() => _charge = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final notes  = context.watch<NotesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _charge
            ? const Center(child: CircularProgressIndicator())
            : auth.user?.estParent == true
                ? _vueParent(notes.periodes)
                : _vueEnseignant(),
      ),
      bottomNavigationBar: const BottomNav(indexActuel: 3),
    );
  }

  Widget _vueParent(List<Periode> periodes) {
    if (_dossiers.isEmpty) {
      return const EmptyState(
        message: 'Aucun dossier actif',
        sousTitre: 'Activez votre dossier pour voir les notes.',
        icone: Icons.bar_chart_outlined,
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: _dossiers.map((d) => _CarteEnfantNotes(
        dossier: d,
        periodes: periodes,
      )).toList(),
    );
  }

  Widget _vueEnseignant() {
    return Stack(
      children: [
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.groups_outlined, color: AppColors.navy),
                title: Text('Voir ma classe',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.navy)),
                subtitle: Text('Liste des élèves',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                onTap: () => context.go('/teacher/ma-classe'),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 16, right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => context.push('/notes/saisir'),
            backgroundColor: AppColors.navy,
            icon: const Icon(Icons.add, color: AppColors.white),
            label: Text('Saisir une note',
                style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _CarteEnfantNotes extends StatelessWidget {
  final Dossier dossier;
  final List<Periode> periodes;

  const _CarteEnfantNotes({required this.dossier, required this.periodes});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.light,
                  child: Text(dossier.prenom[0].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.navy)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dossier.nomComplet, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.navy)),
                      Text(dossier.classeNom ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
            if (periodes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Voir le bulletin :', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: periodes.map((p) => ActionChip(
                  label: Text(p.nom, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                  backgroundColor: AppColors.light,
                  onPressed: () => context.push('/notes/bulletin/${dossier.eleveId}/${p.id}'),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
