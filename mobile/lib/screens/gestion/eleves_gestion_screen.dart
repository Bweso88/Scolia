import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/student.dart';
import '../../services/student_service.dart';
import '../../widgets/empty_state.dart';

class ElevesGestionScreen extends StatefulWidget {
  const ElevesGestionScreen({super.key});

  @override
  State<ElevesGestionScreen> createState() => _ElevesGestionScreenState();
}

class _ElevesGestionScreenState extends State<ElevesGestionScreen> {
  final _service = StudentService();
  List<Student> _eleves = [];
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    try {
      _eleves = await _service.getEleves();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Élèves')),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _charge
            ? const Center(child: CircularProgressIndicator())
            : _eleves.isEmpty
                ? EmptyState(
                    message: 'Aucun élève',
                    sousTitre: 'Inscrivez le premier élève de l\'école.',
                    icone: Icons.people_outline,
                    onAction: _charger,
                    libelleAction: 'Actualiser',
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _eleves.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final e = _eleves[i];
                      return ListTile(
                        title: Text(e.nomComplet, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          e.schoolClass?.name ?? '—',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted),
                        ),
                        trailing: Icon(
                          e.isActivated ? Icons.check_circle : Icons.pause_circle_outline,
                          color: e.isActivated ? AppColors.green : AppColors.orange,
                        ),
                        onTap: () async {
                          final modifie = await context.push<bool>('/gestion/eleves/creer', extra: e);
                          if (modifie == true) _charger();
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final cree = await context.push<bool>('/gestion/eleves/creer');
          if (cree == true) _charger();
        },
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: Text('Nouvel élève', style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
