class SchoolYearRef {
  final int id;
  final String label;
  final bool isCurrent;

  const SchoolYearRef({required this.id, required this.label, this.isCurrent = false});

  factory SchoolYearRef.fromJson(Map<String, dynamic> j) => SchoolYearRef(
        id: j['id'] as int,
        label: j['label'] as String,
        isCurrent: j['is_current'] as bool? ?? false,
      );
}
