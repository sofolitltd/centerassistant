import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/services/firebase_service.dart';
import '../models/office_settings.dart';

// LEGACY: Keep for migration
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

// NEW: Providers for the restructured collections
final specialWorkDaysProvider = StreamProvider<List<SpecialWorkDay>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('special_working_days')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => SpecialWorkDay.fromFirestore(doc))
            .toList(),
      );
});

final weeklyOffDayPoliciesProvider = StreamProvider<List<WeeklyOffDayPolicy>>((
  ref,
) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('weekly_off_day_configs')
      .orderBy('startDate', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => WeeklyOffDayPolicy.fromFirestore(doc))
            .toList(),
      );
});

final activeWeeklyPolicyProvider = Provider<WeeklyOffDayPolicy?>((ref) {
  final policies = ref.watch(weeklyOffDayPoliciesProvider).value ?? [];
  final now = DateTime.now();

  // Find policy that is currently active (startDate <= now and (endDate == null or endDate >= now))
  try {
    return policies.firstWhere((p) {
      final isStarted =
          p.startDate.isBefore(now) ||
          (p.startDate.year == now.year &&
              p.startDate.month == now.month &&
              p.startDate.day == now.day);
      final isNotEnded =
          p.endDate == null ||
          p.endDate!.isAfter(now) ||
          (p.endDate!.year == now.year &&
              p.endDate!.month == now.month &&
              p.endDate!.day == now.day);
      return isStarted && isNotEnded;
    });
  } catch (_) {
    return policies.firstOrNull; // Fallback to latest
  }
});

final isOfficeClosedProvider = FutureProvider.family<String?, DateTime>((
  ref,
  date,
) async {
  // Use the new providers for checking office status
  final specialWorkDays = await ref.watch(specialWorkDaysProvider.future);
  final holidays = await ref.watch(officeHolidaysProvider.future);
  final policies = await ref.watch(weeklyOffDayPoliciesProvider.future);

  // Check if this date is explicitly marked as a "Work Day" (Override)
  final isOverrideOpen = specialWorkDays.any(
    (swd) =>
        swd.date.year == date.year &&
        swd.date.month == date.month &&
        swd.date.day == date.day,
  );
  if (isOverrideOpen) return null;

  // Check Weekly Off-Days based on the policy active at THAT point in time
  final dayName = DateFormat('EEEE').format(date);
  final policyAtDate = policies.where((p) {
    final isStarted =
        p.startDate.isBefore(date) ||
        (p.startDate.year == date.year &&
            p.startDate.month == date.month &&
            p.startDate.day == date.day);
    final isNotEnded =
        p.endDate == null ||
        p.endDate!.isAfter(date) ||
        (p.endDate!.year == date.year &&
            p.endDate!.month == date.month &&
            p.endDate!.day == date.day);
    return isStarted && isNotEnded;
  }).firstOrNull;

  if (policyAtDate != null && policyAtDate.days.contains(dayName)) {
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
