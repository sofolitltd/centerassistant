import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/data/repositories/leave_repository_impl.dart';
import '/core/domain/repositories/leave_repository.dart';
import '/core/models/leave.dart';
import '/core/providers/session_providers.dart';
import '/services/firebase_service.dart';
import 'auth_providers.dart';
import 'notification_providers.dart';

final leaveRepositoryProvider = Provider<ILeaveRepository>((ref) {
  return LeaveRepositoryImpl(ref.watch(firestoreProvider));
});

final allLeavesProvider = StreamProvider<List<Leave>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('leaves')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Leave.fromFirestore(doc)).toList(),
      );
});

final leavesByDateProvider = StreamProvider.family<List<Leave>, DateTime>((
  ref,
  date,
) {
  return ref.watch(leaveRepositoryProvider).getLeavesByDate(date);
});

final leavesByEntityProvider = StreamProvider.family<List<Leave>, String>((
  ref,
  employeeId,
) {
  return ref.watch(leaveRepositoryProvider).getLeavesByEntity(employeeId);
});

final leaveServiceProvider = Provider((ref) => LeaveActionService(ref));

class LeaveActionService {
  final Ref _ref;
  LeaveActionService(this._ref);

  Future<void> addLeave({
    required String employeeId,
    required DateTime date,
    String? reason,
    LeaveType leaveType = LeaveType.annual,
    LeaveDuration duration = LeaveDuration.full,
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final leave = Leave(
      id: firestore.collection('leaves').doc().id,
      employeeId: employeeId,
      date: DateTime(date.year, date.month, date.day),
      reason: reason,
      leaveType: leaveType,
      duration: duration,
    );
    await _ref.read(leaveRepositoryProvider).addLeave(leave);
    _ref.invalidate(scheduleViewProvider);

    // Notification to Admins
    _ref
        .read(notificationServiceProvider)
        .notifyAllAdmins(
          title: 'New Leave Request',
          body:
              'A new request for ${leaveType.name.toUpperCase()} has been submitted for ${date.day}/${date.month}.',
        );
  }

  Future<void> removeLeave(String leaveId) async {
    await _ref.read(leaveRepositoryProvider).removeLeave(leaveId);
    _ref.invalidate(scheduleViewProvider);
  }

  Future<void> updateStatus({
    required String leaveId,
    required LeaveStatus status,
  }) async {
    final adminId = _ref.read(authProvider).adminId;
    if (adminId == null) return;

    await _ref
        .read(leaveRepositoryProvider)
        .updateLeaveStatus(leaveId, status, adminId);
    _ref.invalidate(scheduleViewProvider);

    // Notification to Employee
    final allLeaves = _ref.read(allLeavesProvider).value;
    if (allLeaves != null) {
      try {
        final leave = allLeaves.firstWhere((l) => l.id == leaveId);
        _ref
            .read(notificationServiceProvider)
            .sendToUser(
              userId: leave.employeeId,
              collection: 'employees',
              title: 'Leave Status Updated',
              body:
                  'Your leave request for ${leave.date.day}/${leave.date.month} has been ${status.name}.',
            );
      } catch (_) {}
    }
  }

  Future<void> requestCancel(String leaveId) async {
    final repo = _ref.read(leaveRepositoryProvider);
    final employeeId = _ref.read(authProvider).employeeId;
    if (employeeId == null) return;

    // Update status to cancel_requested
    await repo.updateLeaveStatus(
      leaveId,
      LeaveStatus.cancelRequest,
      employeeId,
    );
    _ref.invalidate(scheduleViewProvider);

    // Notification to Admins
    _ref
        .read(notificationServiceProvider)
        .notifyAllAdmins(
          title: 'Leave Cancellation Request',
          body: 'An employee has requested to cancel an approved leave.',
        );
  }

  Future<void> cancelLeave(String leaveId) async {
    final repo = _ref.read(leaveRepositoryProvider);
    final employeeId = _ref.read(authProvider).employeeId;
    if (employeeId == null) return;

    // Update status to cancelled instead of deleting
    await repo.updateLeaveStatus(leaveId, LeaveStatus.cancelled, employeeId);
    _ref.invalidate(scheduleViewProvider);

    // Notification to Admins
    _ref
        .read(notificationServiceProvider)
        .notifyAllAdmins(
          title: 'Leave Request Cancelled',
          body: 'An approved leave request has been cancelled by an employee.',
        );
  }
}
