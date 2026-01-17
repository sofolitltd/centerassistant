import 'package:cloud_firestore/cloud_firestore.dart';

class OfficeHoliday {
  final String id;
  final String title;
  final DateTime date;
  final bool isCenterWide;

  OfficeHoliday({
    required this.id,
    required this.title,
    required this.date,
    this.isCenterWide = true,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'date': Timestamp.fromDate(date),
    'isCenterWide': isCenterWide,
  };

  factory OfficeHoliday.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfficeHoliday(
      id: doc.id,
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      isCenterWide: data['isCenterWide'] ?? true,
    );
  }
}

class SpecialWorkDay {
  final DateTime date;
  final String? note;

  SpecialWorkDay({required this.date, this.note});

  Map<String, dynamic> toJson() => {
    'date': Timestamp.fromDate(date),
    'note': note,
  };

  factory SpecialWorkDay.fromMap(Map<String, dynamic> map) {
    return SpecialWorkDay(
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'] as String?,
    );
  }
}

class OfficeSettings {
  final List<String> weeklyOffDays; // ["Friday", "Saturday"]
  final List<SpecialWorkDay> specialWorkDays;

  OfficeSettings({required this.weeklyOffDays, required this.specialWorkDays});

  Map<String, dynamic> toJson() => {
    'weeklyOffDays': weeklyOffDays,
    'specialWorkDays': specialWorkDays.map((d) => d.toJson()).toList(),
  };

  factory OfficeSettings.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      return OfficeSettings(weeklyOffDays: [], specialWorkDays: []);
    }
    final data = doc.data() as Map<String, dynamic>;
    return OfficeSettings(
      weeklyOffDays: List<String>.from(data['weeklyOffDays'] ?? []),
      specialWorkDays:
          (data['specialWorkDays'] as List<dynamic>?)
              ?.map((d) => SpecialWorkDay.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
