import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/teacher_admin.dart';
import '../../services/gestion_service.dart';
import '../../widgets/empty_state.dart';

class ProfesseursScreen extends StatefulWidget {
  const ProfesseursScreen({super.key});

  @override
  State<ProfesseursScreen> createState() => _ProfesseursScreenState();
}

class _ProfesseursScreenState extends State<ProfesseursScreen> {
  final _service = GestionService();
  List<TeacherAdmin> _profs = [];
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    try {
      _profs = await _service.getProfesseurs();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Professeurs')),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _charge
            ? const Center(child: CircularProgressIndicator())
            : _profs.isEmpty
                ? EmptyState(
                    message: 'Aucun professeur',
                    sousTitre: 'Ajoutez le premier professeur de l\'école.',
                    icone: Icons.school_outlined,
                    onAction: _charger,
                    libelleAction: 'Actualiser',
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _profs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = _profs[i];
                      final classes = p.assignments.map((a) => a.schoolClassName).whereType<String>().toSet().join(', ');
                      return ListTile(
                        title: Text(p.name ?? '—', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          classes.isEmpty ? (p.email ?? '') : classes,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                        onTap: () async {
                          final modifie = await context.push<bool>('/gestion/professeurs/creer', extra: p);
                          if (modifie == true) _charger();
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final cree = await context.push<bool>('/gestion/professeurs/creer');
          if (cree == true) _charger();
        },
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: Text('Nouveau professeur', style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
