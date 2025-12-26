import '/core/models/leave.dart';

abstract class ILeaveRepository {
  Future<void> addLeave(Leave leave);
  Future<void> removeLeave(String leaveId);
  Stream<List<Leave>> getLeavesByDate(DateTime date);
  Stream<List<Leave>> getLeavesByEntity(String entityId);
}
