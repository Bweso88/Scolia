import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/homework.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../services/children_service.dart';
import '../../services/homework_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/child_selector.dart';
import '../../widgets/empty_state.dart';

/// Cahier de texte / devoirs (docs/PRODUCT_ARCHITECTURE.md §4) : un parent
/// filtre par échéance, le personnel voit et publie les devoirs de ses
/// classes.
class DevoirsScreen extends StatefulWidget {
  const DevoirsScreen({super.key});

  @override
  State<DevoirsScreen> createState() => _DevoirsScreenState();
}

class _DevoirsScreenState extends State<DevoirsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  final _childrenService = ChildrenService();
  final _homeworkService = HomeworkService();

  static const _ranges = ['today', 'tomorrow', 'week', 'late'];

  List<Homework> _devoirsParent = [];
  List<Homework> _devoirsPersonnel = [];
  bool _charge = false;
  int? _dernierEnfantId;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _chargerParent();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final user = context.read<AuthProvider>().user;
    if (user?.estParent == true) {
      await _chargerParent();
    } else {
      await _chargerPersonnel();
    }
  }

  Future<void> _chargerParent() async {
    final enfant = context.read<ChildProvider>().selectionne;
    if (enfant == null) return;
    setState(() => _charge = true);
    try {
      final devoirs = await _childrenService.getDevoirs(enfant.id, range: _ranges[_tabs.index]);
      setState(() {
        _devoirsParent = devoirs;
        _dernierEnfantId = enfant.id;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _chargerPersonnel() async {
    setState(() => _charge = true);
    try {
      final classes = context.read<AuthProvider>().user?.classes ?? [];
      final devoirs = classes.isEmpty
          ? await _homeworkService.getDevoirs()
          : await _homeworkService.getDevoirs(schoolClassId: classes.first.id);
      setState(() => _devoirsPersonnel = devoirs);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final estParent = user?.estParent == true;

    final enfantCourant = context.watch<ChildProvider>().selectionne;
    if (estParent && enfantCourant != null && enfantCourant.id != _dernierEnfantId && !_charge) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _chargerParent());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devoirs'),
        bottom: estParent
            ? TabBar(
                controller: _tabs,
                indicatorColor: AppColors.amber,
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.white.withOpacity(0.6),
                labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Aujourd\'hui'),
                  Tab(text: 'Demain'),
                  Tab(text: 'Semaine'),
                  Tab(text: 'En retard'),
                ],
              )
            : null,
      ),
      body: estParent ? _corpsParent() : _corpsPersonnel(),
      floatingActionButton: user?.estEnseignant == true
          ? FloatingActionButton.extended(
              onPressed: () async {
                final publie = await context.push<bool>('/devoirs/publier');
                if (publie == true) _chargerPersonnel();
              },
              backgroundColor: AppColors.navy,
              icon: const Icon(Icons.add, color: AppColors.white),
              label: Text('Publier', style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w600)),
            )
          : null,
      bottomNavigationBar: const BottomNav(indexActuel: 1),
    );
  }

  Widget _corpsParent() {
    if (context.watch<ChildProvider>().enfants.isEmpty) {
      return const EmptyState(
        message: 'Aucun enfant lié',
        sousTitre: 'Contactez l\'école pour activer votre compte parent.',
        icone: Icons.child_care_outlined,
      );
    }
    return Column(
      children: [
        const SizedBox(height: 12),
        const ChildSelector(),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _chargerParent,
            child: _charge
                ? const Center(child: CircularProgressIndicator())
                : _devoirsParent.isEmpty
                    ? EmptyState(
                        message: 'Aucun devoir',
                        sousTitre: 'Rien à faire pour cette période.',
                        icone: Icons.assignment_turned_in_outlined,
                        onAction: _chargerParent,
                        libelleAction: 'Actualiser',
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _devoirsParent.length,
                        itemBuilder: (_, i) => _CarteDevoir(devoir: _devoirsParent[i]),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _corpsPersonnel() {
    return RefreshIndicator(
      onRefresh: _chargerPersonnel,
      child: _charge
          ? const Center(child: CircularProgressIndicator())
          : _devoirsPersonnel.isEmpty
              ? EmptyState(
                  message: 'Aucun devoir publié',
                  sousTitre: 'Publiez le premier devoir de votre classe.',
                  icone: Icons.assignment_outlined,
                  onAction: _chargerPersonnel,
                  libelleAction: 'Actualiser',
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _devoirsPersonnel.length,
                  itemBuilder: (_, i) => _CarteDevoir(devoir: _devoirsPersonnel[i]),
                ),
    );
  }
}

class _CarteDevoir extends StatelessWidget {
  final Homework devoir;
  const _CarteDevoir({required this.devoir});

  @override
  Widget build(BuildContext context) {
    DateTime? echeance;
    try { if (devoir.dueDate != null) echeance = DateTime.parse(devoir.dueDate!); } catch (_) {}

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.assignment_outlined, color: AppColors.purple, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (devoir.subjectName != null)
                    Text(devoir.subjectName!, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy)),
                  const SizedBox(height: 2),
                  Text(devoir.title, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.body)),
                  if (devoir.instructions != null && devoir.instructions!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(devoir.instructions!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (echeance != null)
                        Text('À rendre le ${DateFormat('d MMM', 'fr_FR').format(echeance)}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                      if (devoir.schoolClassName != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.light, borderRadius: BorderRadius.circular(4)),
                          child: Text(devoir.schoolClassName!, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.muted)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
