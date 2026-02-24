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
  final String id;
  final DateTime date;
  final String? note;

  SpecialWorkDay({required this.id, required this.date, this.note});

  Map<String, dynamic> toJson() => {
    'date': Timestamp.fromDate(date),
    'note': note,
  };

  factory SpecialWorkDay.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpecialWorkDay(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] as String?,
    );
  }
}

class WeeklyOffDayPolicy {
  final String id;
  final List<String> days;
  final DateTime startDate;
  final DateTime? endDate;
  final String? note;
  final DateTime createdAt;

  WeeklyOffDayPolicy({
    required this.id,
    required this.days,
    required this.startDate,
    this.endDate,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'days': days,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'note': note,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory WeeklyOffDayPolicy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeeklyOffDayPolicy(
      id: doc.id,
      days: List<String>.from(data['days'] ?? []),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      note: data['note'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

// Keeping OfficeSettings for backward compatibility during migration
class OfficeSettings {
  final List<String> weeklyOffDays;
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
              ?.map(
                (d) => SpecialWorkDayLegacy.fromMap_Legacy(
                  d as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }
}

extension SpecialWorkDayLegacy on SpecialWorkDay {
  static SpecialWorkDay fromMap_Legacy(Map<String, dynamic> map) {
    return SpecialWorkDay(
      id: '', // Legacy items don't have individual IDs
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'] as String?,
    );
  }
}
