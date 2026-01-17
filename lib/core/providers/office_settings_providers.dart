import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/services/firebase_service.dart';
import '../models/office_settings.dart';

final officeSettingsProvider = StreamProvider<OfficeSettings>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('settings')
      .doc('office')
      .snapshots()
      .map((doc) => OfficeSettings.fromFirestore(doc));
});

final officeHolidaysProvider = StreamProvider<List<OfficeHoliday>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('holidays')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => OfficeHoliday.fromFirestore(doc))
            .toList(),
      );
});

final isOfficeClosedProvider = FutureProvider.family<String?, DateTime>((
  ref,
  date,
) async {
  final settings = await ref.watch(officeSettingsProvider.future);
  final holidays = await ref.watch(officeHolidaysProvider.future);

  // Check if this date is explicitly marked as a "Work Day" (Override)
  final isOverrideOpen = settings.specialWorkDays.any(
    (swd) =>
        swd.date.year == date.year &&
        swd.date.month == date.month &&
        swd.date.day == date.day,
  );
  if (isOverrideOpen) return null;

  // Check Weekly Off-Days
  final dayName = DateFormat('EEEE').format(date);
  if (settings.weeklyOffDays.contains(dayName)) {
    return 'Weekend';
  }

  // Check Public Holidays
  final holiday = holidays.where((h) {
    return h.date.year == date.year &&
        h.date.month == date.month &&
        h.date.day == date.day;
  }).firstOrNull;

  return holiday?.title;
});
