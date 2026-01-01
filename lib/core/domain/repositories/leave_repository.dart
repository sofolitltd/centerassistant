import 'package:center_assistant/core/models/leave.dart';

abstract class ILeaveRepository {
  Future<void> addLeave(Leave leave);
  Future<void> removeLeave(String leaveId);
  Future<void> updateLeaveStatus(
    String leaveId,
    LeaveStatus status,
    String adminId,
  );
  Stream<List<Leave>> getLeavesByDate(DateTime date);
  Stream<List<Leave>> getLeavesByEntity(String entityId);
}
