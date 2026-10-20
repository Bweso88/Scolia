import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/school_class_admin.dart';
import '../../services/gestion_service.dart';
import '../../widgets/empty_state.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _service = GestionService();
  List<SchoolClassAdmin> _classes = [];
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    try {
      _classes = await _service.getClasses();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _charge
            ? const Center(child: CircularProgressIndicator())
            : _classes.isEmpty
                ? EmptyState(
                    message: 'Aucune classe',
                    sousTitre: 'Créez la première classe de l\'école.',
                    icone: Icons.class_outlined,
                    onAction: _charger,
                    libelleAction: 'Actualiser',
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _classes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final c = _classes[i];
                      return ListTile(
                        title: Text(c.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          [
                            if (c.level != null) c.level!,
                            if (c.homeroomTeacherName != null) 'Prof. principal : ${c.homeroomTeacherName}',
                            '${c.studentsCount ?? 0} élève(s)',
                          ].join(' · '),
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                        onTap: () async {
                          final modifie = await context.push<bool>('/gestion/classes/creer', extra: c);
                          if (modifie == true) _charger();
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final cree = await context.push<bool>('/gestion/classes/creer');
          if (cree == true) _charger();
        },
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: Text('Nouvelle classe', style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
