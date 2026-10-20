import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/timetable_slot.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../services/children_service.dart';
import '../../services/timetable_service.dart';
import '../../widgets/empty_state.dart';

/// Emploi du temps hebdomadaire (docs/PRODUCT_ARCHITECTURE.md §7) : un
/// parent consulte celui de l'enfant sélectionné, le personnel celui de sa
/// classe.
class CalendrierScreen extends StatefulWidget {
  const CalendrierScreen({super.key});

  @override
  State<CalendrierScreen> createState() => _CalendrierScreenState();
}

class _CalendrierScreenState extends State<CalendrierScreen> {
  final _childrenService = ChildrenService();
  final _timetableService = TimetableService();

  List<TimetableSlot> _creneaux = [];
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
        _creneaux = await _childrenService.getEmploiDuTemps(enfant.id);
        _dernierEnfantId = enfant.id;
      } else {
        final classes = user?.classes ?? [];
        _creneaux = await _timetableService.getEmploiDuTemps(
          schoolClassId: classes.isEmpty ? null : classes.first.id,
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Map<int, List<TimetableSlot>> get _creneauxParJour {
    final groupes = <int, List<TimetableSlot>>{};
    for (final c in _creneaux) {
      groupes.putIfAbsent(c.dayOfWeek, () => []).add(c);
    }
    for (final liste in groupes.values) {
      liste.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return groupes;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final estParent = user?.estParent == true;

    if (estParent) {
      final enfant = context.watch<ChildProvider>().selectionne;
      if (enfant != null && enfant.id != _dernierEnfantId && !_charge) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
      }
    }

    final parJour = _creneauxParJour;
    final jours = parJour.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Emploi du temps')),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _charge
            ? const Center(child: CircularProgressIndicator())
            : _creneaux.isEmpty
                ? EmptyState(
                    message: 'Aucun créneau',
                    sousTitre: 'L\'emploi du temps n\'a pas encore été renseigné.',
                    icone: Icons.schedule_outlined,
                    onAction: _charger,
                    libelleAction: 'Actualiser',
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: jours.length,
                    itemBuilder: (_, i) => _CarteJour(jour: jours[i], creneaux: parJour[jours[i]]!),
                  ),
      ),
    );
  }
}

class _CarteJour extends StatelessWidget {
  final int jour;
  final List<TimetableSlot> creneaux;
  const _CarteJour({required this.jour, required this.creneaux});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(TimetableSlot.jours[jour],
                style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          ...creneaux.map((c) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text('${c.startTime}\n${c.endTime}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.subject ?? '—',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.navy)),
                          if (c.teacherName != null)
                            Text(c.teacherName!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    if (c.room != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.light, borderRadius: BorderRadius.circular(6)),
                        child: Text(c.room!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                      ),
                  ],
                ),
              )),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
