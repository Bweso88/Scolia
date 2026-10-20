/// Un créneau d'emploi du temps, tel que renvoyé par TimetableSlotResource.
class TimetableSlot {
  final int id;
  final int schoolClassId;
  final String? subject;
  final String? teacherName;
  final int dayOfWeek; // 1 (lundi) .. 7 (dimanche), ISO-8601
  final String startTime;
  final String endTime;
  final String? room;

  const TimetableSlot({
    required this.id,
    required this.schoolClassId,
    this.subject,
    this.teacherName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  factory TimetableSlot.fromJson(Map<String, dynamic> j) => TimetableSlot(
        id:            j['id'] as int,
        schoolClassId: j['school_class_id'] as int,
        subject:       j['subject'] as String?,
        teacherName:   j['teacher_name'] as String?,
        dayOfWeek:     j['day_of_week'] as int,
        startTime:     j['start_time'] as String,
        endTime:       j['end_time'] as String,
        room:          j['room'] as String?,
      );

  static const jours = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  String get jourLabel => (dayOfWeek >= 1 && dayOfWeek <= 7) ? jours[dayOfWeek] : '';
}
