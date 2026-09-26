import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/student.dart';
import '../../services/attendance_service.dart';
import '../../services/student_service.dart';
import '../../widgets/success_toast.dart';

/// Saisie d'une absence/retard par le personnel — déclenche immédiatement
/// une notification au parent (docs/PRODUCT_ARCHITECTURE.md §6).
class SaisirAbsenceScreen extends StatefulWidget {
  final int? eleveId;
  const SaisirAbsenceScreen({super.key, this.eleveId});

  @override
  State<SaisirAbsenceScreen> createState() => _SaisirAbsenceScreenState();
}

class _SaisirAbsenceScreenState extends State<SaisirAbsenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motifCtrl = TextEditingController();
  final _studentService = StudentService();
  final _attendanceService = AttendanceService();

  List<Student> _eleves = [];
  int? _eleveSelectionne;
  String _type = 'absence';
  DateTime _date = DateTime.now();
  bool _charge = false;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _eleveSelectionne = widget.eleveId;
    _chargerEleves();
  }

  @override
  void dispose() {
    _motifCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerEleves() async {
    setState(() => _charge = true);
    try {
      _eleves = await _studentService.getEleves();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eleveSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un élève'), backgroundColor: AppColors.orange),
      );
      return;
    }
    setState(() => _envoi = true);
    try {
      await _attendanceService.saisirAbsence({
        'student_id': _eleveSelectionne,
        'type': _type,
        'date': DateFormat('yyyy-MM-dd').format(_date),
        'reason': _motifCtrl.text.trim().isEmpty ? null : _motifCtrl.text.trim(),
      });
      if (mounted) {
        showSuccessToast(context, 'Absence enregistrée.');
        context.pop(true);
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signaler une absence')),
      body: _charge
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<int>(
                      value: _eleveSelectionne,
                      decoration: const InputDecoration(labelText: 'Élève *'),
                      items: _eleves.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nomComplet))).toList(),
                      onChanged: (v) => setState(() => _eleveSelectionne = v),
                      validator: (v) => v == null ? 'Sélectionnez un élève' : null,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'absence', label: Text('Absence')),
                        ButtonSegment(value: 'retard', label: Text('Retard')),
                      ],
                      selected: {_type},
                      onSelectionChanged: (v) => setState(() => _type = v.first),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Date', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.muted)),
                      subtitle: Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_date),
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.navy)),
                      trailing: const Icon(Icons.calendar_today_outlined, color: AppColors.navy),
                      onTap: _choisirDate,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _motifCtrl,
                      decoration: const InputDecoration(labelText: 'Motif (facultatif)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _envoi ? null : _enregistrer,
                      child: _envoi
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                          : const Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
