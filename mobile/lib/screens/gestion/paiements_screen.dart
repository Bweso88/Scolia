import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/school_class_admin.dart';
import '../../models/student.dart';
import '../../services/gestion_service.dart';
import '../../services/student_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/success_toast.dart';

/// Suivi des paiements de scolarité (docs/PRODUCT_ARCHITECTURE.md §18) :
/// un bascule très simple par élève — payé / non payé — à la disposition
/// de la direction. Réutilise le même mécanisme d'activation que l'écran
/// Élèves, mais présenté ici clairement comme un statut de paiement (la
/// vraie facturation reste hors MVP).
class PaiementsScreen extends StatefulWidget {
  const PaiementsScreen({super.key});

  @override
  State<PaiementsScreen> createState() => _PaiementsScreenState();
}

class _PaiementsScreenState extends State<PaiementsScreen> {
  final _service = StudentService();
  final _gestionService = GestionService();
  List<Student> _eleves = [];
  List<SchoolClassAdmin> _classes = [];
  int? _classeFiltre;
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    _chargerClasses();
    _charger();
  }

  Future<void> _chargerClasses() async {
    try {
      _classes = await _gestionService.getClasses();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    try {
      _eleves = await _service.getEleves(schoolClassId: _classeFiltre);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  void _filtrerParClasse(int? classeId) {
    setState(() => _classeFiltre = classeId);
    _charger();
  }

  Future<void> _basculerPaiement(int index, bool paye) async {
    final avant = _eleves[index];
    setState(() {
      _eleves[index] = Student(
        id: avant.id,
        firstName: avant.firstName,
        lastName: avant.lastName,
        enrollmentNumber: avant.enrollmentNumber,
        status: avant.status,
        isActivated: paye,
        activatedAt: paye ? DateTime.now().toIso8601String() : null,
        schoolClass: avant.schoolClass,
      );
    });
    try {
      await _service.activerEleve(avant.id, paye);
      if (mounted) showSuccessToast(context, paye ? 'Marqué comme payé' : 'Marqué comme non payé');
    } catch (e) {
      if (mounted) {
        setState(() => _eleves[index] = avant);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nonPayes = _eleves.where((e) => !e.isActivated).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Paiements')),
      body: Column(
        children: [
          if (!_charge && _eleves.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: nonPayes > 0 ? AppColors.orange.withOpacity(0.12) : AppColors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                nonPayes > 0
                    ? '$nonPayes élève${nonPayes > 1 ? 's' : ''} en attente de paiement sur ${_eleves.length}.'
                    : 'Tous les élèves affichés sont à jour.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: nonPayes > 0 ? AppColors.orange : AppColors.green,
                ),
              ),
            ),
          if (_classes.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _classes.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return ChoiceChip(
                      label: const Text('Toutes les classes'),
                      selected: _classeFiltre == null,
                      onSelected: (_) => _filtrerParClasse(null),
                    );
                  }
                  final c = _classes[i - 1];
                  return ChoiceChip(
                    label: Text(c.name),
                    selected: _classeFiltre == c.id,
                    onSelected: (_) => _filtrerParClasse(c.id),
                  );
                },
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _charger,
              child: _charge
                  ? const Center(child: CircularProgressIndicator())
                  : _eleves.isEmpty
                      ? EmptyState(
                          message: 'Aucun élève',
                          sousTitre: _classeFiltre != null ? 'Aucun élève dans cette classe.' : 'Inscrivez un élève pour suivre ses paiements.',
                          icone: Icons.payments_outlined,
                          onAction: _charger,
                          libelleAction: 'Actualiser',
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _eleves.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final e = _eleves[i];
                            DateTime? depuis;
                            try { if (e.activatedAt != null) depuis = DateTime.parse(e.activatedAt!); } catch (_) {}

                            return ListTile(
                              title: Text(e.nomComplet, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                e.isActivated
                                    ? (depuis != null ? 'Payé depuis le ${DateFormat('d MMM yyyy', 'fr_FR').format(depuis)}' : 'Payé')
                                    : (e.schoolClass?.name ?? '—'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: e.isActivated ? AppColors.green : AppColors.muted,
                                  fontWeight: e.isActivated ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (e.isActivated ? AppColors.green : AppColors.orange).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      e.isActivated ? 'PAYÉ' : 'NON PAYÉ',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10, fontWeight: FontWeight.w800,
                                        color: e.isActivated ? AppColors.green : AppColors.orange,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: e.isActivated,
                                    activeThumbColor: AppColors.green,
                                    onChanged: (valeur) => _basculerPaiement(i, valeur),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
