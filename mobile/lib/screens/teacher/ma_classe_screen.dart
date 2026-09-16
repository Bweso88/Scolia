import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/student.dart';
import '../../providers/auth_provider.dart';
import '../../services/student_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/empty_state.dart';

class MaClasseScreen extends StatefulWidget {
  const MaClasseScreen({super.key});

  @override
  State<MaClasseScreen> createState() => _MaClasseScreenState();
}

class _MaClasseScreenState extends State<MaClasseScreen> {
  final _studentService = StudentService();
  List<Student> _eleves = [];
  bool _charge = false;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    try {
      final classes = context.read<AuthProvider>().user?.classes ?? [];
      _eleves = classes.isEmpty
          ? await _studentService.getEleves()
          : await _studentService.getEleves(schoolClassId: classes.first.id);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  List<Student> get _elevesFiltres {
    if (_recherche.isEmpty) return _eleves;
    final q = _recherche.toLowerCase();
    return _eleves.where((e) => e.nomComplet.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<AuthProvider>().user?.classes ?? [];
    final nomClasse = classes.isNotEmpty ? classes.first.name : 'Ma classe';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nomClasse,
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
            Text('${_eleves.length} élève${_eleves.length > 1 ? 's' : ''}',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.white.withOpacity(0.75))),
          ],
        ),
      ),
      body: _charge
          ? const Center(child: CircularProgressIndicator())
          : _eleves.isEmpty
              ? const EmptyState(
                  message: 'Aucun élève',
                  sousTitre: 'Vous n\'avez pas encore de classe assignée.',
                  icone: Icons.groups_outlined,
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher un élève…',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (v) => setState(() => _recherche = v),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _charger,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: _elevesFiltres.length,
                          itemBuilder: (_, i) => _CarteEleve(eleve: _elevesFiltres[i]),
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/notes/saisir'),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: Text('Saisir une note',
            style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w600)),
      ),
      bottomNavigationBar: const BottomNav(indexActuel: 4),
    );
  }
}

class _CarteEleve extends StatelessWidget {
  final Student eleve;
  const _CarteEleve({required this.eleve});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.navy.withOpacity(0.1),
              child: Text(
                eleve.firstName.isNotEmpty ? eleve.firstName[0].toUpperCase() : '?',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eleve.nomComplet,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.navy)),
                  if (eleve.enrollmentNumber != null)
                    Text(eleve.enrollmentNumber!,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Saisir une note',
              icon: const Icon(Icons.bar_chart_outlined, color: AppColors.green),
              onPressed: () => context.push('/notes/saisir', extra: eleve.id),
            ),
            IconButton(
              tooltip: 'Ajouter une observation',
              icon: const Icon(Icons.comment_outlined, color: AppColors.purple),
              onPressed: () => context.push('/remarques/nouvelle', extra: eleve.id),
            ),
            IconButton(
              tooltip: 'Signaler une absence',
              icon: const Icon(Icons.event_busy_outlined, color: AppColors.orange),
              onPressed: () => context.push('/absences/saisir', extra: eleve.id),
            ),
          ],
        ),
      ),
    );
  }
}
