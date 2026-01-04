import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/core/models/session.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/leave_providers.dart';
import '/core/providers/schedule_template_providers.dart';
import '/core/providers/time_slot_providers.dart';
import '/services/firebase_service.dart';
import '../data/repositories/session_repository_impl.dart';
import '../domain/repositories/session_repository.dart';

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setDate(DateTime newDate) {
    state = DateTime(newDate.year, newDate.month, newDate.day);
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  () {
    return SelectedDateNotifier();
  },
);

final sessionRepositoryProvider = Provider<ISessionRepository>((ref) {
  return SessionRepositoryImpl(ref.watch(firestoreProvider));
});

class ScheduleView {
  final List<dynamic>
  timeSlots; // Using dynamic for now to avoid circular or too complex imports if needed, but preferably TimeSlot
  final Map<String, List<SessionCardData>> sessionsByTimeSlot;

  ScheduleView({required this.timeSlots, required this.sessionsByTimeSlot});
}

class SessionCardData {
  final String clientId;
  final String clientName;
  final String employeeId;
  final String employeeName;
  final SessionType sessionType;
  final String? notes;
  final String? templateEmployeeId; // Added to track the original employee

  SessionCardData({
    required this.clientId,
    required this.clientName,
    required this.employeeId,
    required this.employeeName,
    required this.sessionType,
    this.notes,
    this.templateEmployeeId,
  });
}

final scheduleViewProvider = FutureProvider.autoDispose<ScheduleView>((
  ref,
) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final timeSlots = await ref.watch(timeSlotsProvider.future);
  final clients = await ref.watch(clientsProvider.future);
  final employees = await ref.watch(employeesProvider.future);
  final templates = await ref.watch(allScheduleTemplatesProvider.future);
  final sessions = await ref
      .watch(sessionRepositoryProvider)
      .getSessionsByDate(selectedDate);
  final leaves = await ref.watch(leavesByDateProvider(selectedDate).future);

  final clientMap = {for (var c in clients) c.id: c};
  final employeeMap = {for (var t in employees) t.id: t};

  final dayLeaves = {for (var l in leaves) l.employeeId: l};

  final dayOfWeek = DateFormat('EEEE').format(selectedDate);
  final sessionsByTimeSlot = <String, List<SessionCardData>>{};

  // Helper to map template employee IDs
  final templateEmployeeMap =
      <String, Map<String, String>>{}; // {timeSlotId: {clientId: employeeId}}

  for (final template in templates) {
    for (final rule in template.rules) {
      if (rule.dayOfWeek == dayOfWeek) {
        final client = clientMap[template.clientId];
        final employee = employeeMap[rule.employeeId];

        if (client != null && employee != null) {
          templateEmployeeMap.putIfAbsent(
            rule.timeSlotId,
            () => {},
          )[client.id] = employee.id;

          // Check if employee or client is on leave
          final bool isEmployeeOnLeave = dayLeaves.containsKey(employee.id);
          final bool isClientOnLeave = dayLeaves.containsKey(client.id);

          sessionsByTimeSlot
              .putIfAbsent(rule.timeSlotId, () => [])
              .add(
                SessionCardData(
                  clientId: client.id,
                  clientName: client.name,
                  employeeId: employee.id,
                  employeeName: employee.name,
                  sessionType: (isEmployeeOnLeave || isClientOnLeave)
                      ? SessionType.cancelled
                      : SessionType.regular,
                  templateEmployeeId: employee.id,
                  notes: isEmployeeOnLeave
                      ? 'Employee on leave'
                      : (isClientOnLeave ? 'Client on leave' : null),
                ),
              );
        }
      }
    }
  }

  for (final exception in sessions) {
    final client = clientMap[exception.clientId];
    final employee = employeeMap[exception.employeeId];
    if (client != null && employee != null) {
      final tId = templateEmployeeMap[exception.timeSlotId]?[client.id];

      final card = SessionCardData(
        clientId: client.id,
        clientName: client.name,
        employeeId: employee.id,
        employeeName: employee.name,
        sessionType: exception.sessionType,
        notes: exception.notes,
        templateEmployeeId: tId,
      );
      if (sessionsByTimeSlot.containsKey(exception.timeSlotId)) {
        final index = sessionsByTimeSlot[exception.timeSlotId]!.indexWhere(
          (s) => s.clientId == exception.clientId,
        );
        if (index != -1) {
          sessionsByTimeSlot[exception.timeSlotId]![index] = card;
        } else {
          sessionsByTimeSlot
              .putIfAbsent(exception.timeSlotId, () => [])
              .add(card);
        }
      } else {
        sessionsByTimeSlot
            .putIfAbsent(exception.timeSlotId, () => [])
            .add(card);
      }
    }
  }
  return ScheduleView(
    timeSlots: timeSlots,
    sessionsByTimeSlot: sessionsByTimeSlot,
  );
});

final sessionServiceProvider = Provider((ref) => SessionActionService(ref));

class SessionActionService {
  final Ref _ref;
  SessionActionService(this._ref);

  String _getDeterministicId(
    DateTime date,
    String clientId,
    String timeSlotId,
  ) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return '${dateStr}_${clientId}_$timeSlotId';
  }

  Future<void> _createSessionException({
    required String clientId,
    required String employeeId,
    required String timeSlotId,
    required SessionType sessionType,
    String? originalEmployeeId,
  }) async {
    final selectedDate = _ref.read(selectedDateProvider);
    final deterministicId = _getDeterministicId(
      selectedDate,
      clientId,
      timeSlotId,
    );

    final session = Session(
      id: deterministicId,
      clientId: clientId,
      employeeId: employeeId,
      timeSlotId: timeSlotId,
      date: Timestamp.fromDate(selectedDate),
      sessionType: sessionType,
      originalEmployeeId: originalEmployeeId,
      createdAt: Timestamp.now(),
    );
    await _ref.read(sessionRepositoryProvider).createSessionException(session);
    _ref.invalidate(scheduleViewProvider);
  }

  Future<void> assignCover(
    String clientId,
    String timeSlotId,
    String newEmployeeId,
    String? templateEmployeeId,
  ) async {
    // If reassigned to original employee, delete the exception
    if (newEmployeeId == templateEmployeeId) {
      final selectedDate = _ref.read(selectedDateProvider);
      final deterministicId = _getDeterministicId(
        selectedDate,
        clientId,
        timeSlotId,
      );
      await _ref
          .read(sessionRepositoryProvider)
          .deleteSessionException(deterministicId);
      _ref.invalidate(scheduleViewProvider);
      return;
    }

    return _createSessionException(
      clientId: clientId,
      employeeId: newEmployeeId,
      timeSlotId: timeSlotId,
      sessionType: SessionType.cover,
      originalEmployeeId: templateEmployeeId,
    );
  }

  Future<void> bookMakeup(
    String clientId,
    String timeSlotId,
    String employeeId,
  ) => _createSessionException(
    clientId: clientId,
    employeeId: employeeId,
    timeSlotId: timeSlotId,
    sessionType: SessionType.makeup,
  );

  Future<void> cancelSession(
    String clientId,
    String timeSlotId,
    String employeeId,
  ) => _createSessionException(
    clientId: clientId,
    employeeId: employeeId,
    timeSlotId: timeSlotId,
    sessionType: SessionType.cancelled,
  );

  Future<void> completeSession(
    String clientId,
    String timeSlotId,
    String employeeId,
  ) => _createSessionException(
    clientId: clientId,
    employeeId: employeeId,
    timeSlotId: timeSlotId,
    sessionType: SessionType.completed,
  );

  Future<void> bookExtraSession(
    String clientId,
    String timeSlotId,
    String employeeId,
  ) => _createSessionException(
    clientId: clientId,
    employeeId: employeeId,
    timeSlotId: timeSlotId,
    sessionType: SessionType.extra,
  );
}
