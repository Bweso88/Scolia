import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/attendance_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../services/attendance_service.dart';
import '../../services/children_service.dart';
import '../../widgets/child_selector.dart';
import '../../widgets/empty_state.dart';

/// Absences et retards (docs/PRODUCT_ARCHITECTURE.md §6) : historique côté
/// parent avec justification, saisie par le personnel.
class AbsencesScreen extends StatefulWidget {
  const AbsencesScreen({super.key});

  @override
  State<AbsencesScreen> createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends State<AbsencesScreen> {
  final _childrenService = ChildrenService();
  final _attendanceService = AttendanceService();

  List<AttendanceRecord> _absences = [];
  bool _charge = false;
  int? _dernierEnfantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    final user = context.read<AuthProvider>().user;
    setState(() => _charge = true);
    try {
      if (user?.estParent == true) {
        final enfant = context.read<ChildProvider>().selectionne;
        if (enfant == null) return;
        _absences = await _childrenService.getAbsences(enfant.id);
        _dernierEnfantId = enfant.id;
      } else {
        _absences = await _attendanceService.getAbsences();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _justifier(AttendanceRecord record) async {
    final controleur = TextEditingController();
    final explication = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Justifier l\'absence'),
        content: TextField(
          controller: controleur,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Motif de l\'absence…'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controleur.text.trim()),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (explication == null || explication.isEmpty) return;

    try {
      await _attendanceService.justifier(record.id, explication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Justificatif envoyé.'), backgroundColor: AppColors.green),
        );
      }
      _charger();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final estParent = auth.user?.estParent == true;
    final peutSaisir = auth.user?.faitPartieDuPersonnel == true;

    if (estParent) {
      final enfant = context.watch<ChildProvider>().selectionne;
      if (enfant != null && enfant.id != _dernierEnfantId && !_charge) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Absences & retards')),
      body: Column(
        children: [
          if (estParent) ...[
            const SizedBox(height: 12),
            const ChildSelector(),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: RefreshIndicator(
              onRefresh: _charger,
              child: _charge
                  ? const Center(child: CircularProgressIndicator())
                  : _absences.isEmpty
                      ? EmptyState(
                          message: 'Aucune absence',
                          sousTitre: 'L\'historique des absences et retards apparaîtra ici.',
                          icone: Icons.event_available_outlined,
                          onAction: _charger,
                          libelleAction: 'Actualiser',
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _absences.length,
                          itemBuilder: (_, i) => _CarteAbsence(
                            record: _absences[i],
                            peutJustifier: estParent,
                            onJustifier: () => _justifier(_absences[i]),
                          ),
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: peutSaisir
          ? FloatingActionButton.extended(
              onPressed: () async {
                final saisi = await context.push<bool>('/absences/saisir');
                if (saisi == true) _charger();
              },
              backgroundColor: AppColors.navy,
              icon: const Icon(Icons.add, color: AppColors.white),
              label: Text('Signaler', style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

class _CarteAbsence extends StatelessWidget {
  final AttendanceRecord record;
  final bool peutJustifier;
  final VoidCallback onJustifier;

  const _CarteAbsence({required this.record, required this.peutJustifier, required this.onJustifier});

  @override
  Widget build(BuildContext context) {
    DateTime? date;
    try { if (record.date != null) date = DateTime.parse(record.date!); } catch (_) {}

    final couleur = record.estAbsence ? AppColors.red : AppColors.orange;
    final statutJustif = record.justification?.status;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(record.estAbsence ? Icons.person_off_outlined : Icons.schedule_outlined, color: couleur, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.estAbsence ? 'Absence' : 'Retard',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy)),
                  if (date != null)
                    Text(DateFormat('d MMMM yyyy', 'fr_FR').format(date), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted)),
                  if (record.reason != null && record.reason!.isNotEmpty)
                    Text(record.reason!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.body)),
                  const SizedBox(height: 6),
                  if (statutJustif != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _couleurStatut(statutJustif).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_libelleStatut(statutJustif),
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: _couleurStatut(statutJustif))),
                    )
                  else if (peutJustifier)
                    OutlinedButton(
                      onPressed: onJustifier,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        side: const BorderSide(color: AppColors.navy),
                      ),
                      child: Text('Justifier', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.navy)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _couleurStatut(String statut) => switch (statut) {
        'approved' => AppColors.green,
        'rejected' => AppColors.red,
        _ => AppColors.amber,
      };

  String _libelleStatut(String statut) => switch (statut) {
        'approved' => 'Justificatif approuvé',
        'rejected' => 'Justificatif refusé',
        _ => 'Justificatif en attente',
      };
}
