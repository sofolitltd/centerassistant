import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/data/repositories/leave_repository_impl.dart';
import '/core/domain/repositories/leave_repository.dart';
import '/core/models/leave.dart';
import '/core/providers/session_providers.dart';
import '/services/firebase_service.dart';

final leaveRepositoryProvider = Provider<ILeaveRepository>((ref) {
  return LeaveRepositoryImpl(ref.watch(firestoreProvider));
});

final leavesByDateProvider = StreamProvider.family<List<Leave>, DateTime>((
  ref,
  date,
) {
  return ref.watch(leaveRepositoryProvider).getLeavesByDate(date);
});

final leavesByEntityProvider = StreamProvider.family<List<Leave>, String>((
  ref,
  entityId,
) {
  return ref.watch(leaveRepositoryProvider).getLeavesByEntity(entityId);
});

final leaveServiceProvider = Provider((ref) => LeaveActionService(ref));

class LeaveActionService {
  final Ref _ref;
  LeaveActionService(this._ref);

  Future<void> addLeave({
    required String entityId,
    required LeaveEntityType entityType,
    required DateTime date,
    String? reason,
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final leave = Leave(
      id: firestore.collection('leaves').doc().id,
      entityId: entityId,
      entityType: entityType,
      date: DateTime(date.year, date.month, date.day),
      reason: reason,
    );
    await _ref.read(leaveRepositoryProvider).addLeave(leave);
    _ref.invalidate(scheduleViewProvider);
  }

  Future<void> removeLeave(String leaveId) async {
    await _ref.read(leaveRepositoryProvider).removeLeave(leaveId);
    _ref.invalidate(scheduleViewProvider);
  }
}
