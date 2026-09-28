class Justification {
  final int id;
  final String explanation;
  final String status;

  const Justification({required this.id, required this.explanation, required this.status});

  factory Justification.fromJson(Map<String, dynamic> j) => Justification(
        id:          j['id'] as int,
        explanation: j['explanation'] as String,
        status:      j['status'] as String,
      );
}

/// Une absence/retard, tel que renvoyé par AttendanceRecordResource
/// (docs/PRODUCT_ARCHITECTURE.md §6, module Absences).
class AttendanceRecord {
  final int id;
  final int studentId;
  final String type; // 'absence' | 'retard'
  final String? date;
  final String? startTime;
  final String? endTime;
  final String? reason;
  final Justification? justification;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.type,
    this.date,
    this.startTime,
    this.endTime,
    this.reason,
    this.justification,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id:        j['id'] as int,
        studentId: j['student_id'] as int,
        type:      j['type'] as String,
        date:      j['date'] as String?,
        startTime: j['start_time'] as String?,
        endTime:   j['end_time'] as String?,
        reason:    j['reason'] as String?,
        justification: j['justification'] is Map
            ? Justification.fromJson(j['justification'] as Map<String, dynamic>)
            : null,
      );

  bool get estAbsence => type == 'absence';
  bool get justifiable => justification == null;
}
