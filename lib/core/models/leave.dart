import 'package:cloud_firestore/cloud_firestore.dart';

enum LeaveType { annual, sick, causal, unpaid }

enum LeaveDuration { full, half }

enum LeaveStatus { pending, approved, rejected, cancelled, cancelRequest }

class Leave {
  final String id;
  final String employeeId;
  final DateTime date;
  final String? reason;
  final LeaveType leaveType;
  final LeaveDuration duration;
  final LeaveStatus status;
  final String? approvedBy; // adminId

  Leave({
    required this.id,
    required this.employeeId,
    required this.date,
    this.reason,
    this.leaveType = LeaveType.annual,
    this.duration = LeaveDuration.full,
    this.status = LeaveStatus.pending,
    this.approvedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'date': Timestamp.fromDate(date),
      'reason': reason,
      'leaveType': leaveType.name,
      'duration': duration.name,
      'status': status.name,
      'approvedBy': approvedBy,
    };
  }

  factory Leave.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return Leave(
      id: snapshot.id,
      employeeId: data['employeeId'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: data['reason'] as String?,
      leaveType: LeaveType.values.byName(
        data['leaveType'] as String? ?? 'annual',
      ),
      duration: LeaveDuration.values.byName(
        data['duration'] as String? ?? 'full',
      ),
      status: LeaveStatus.values.byName(data['status'] as String? ?? 'pending'),
      approvedBy: data['approvedBy'] as String?,
    );
  }

  Leave copyWith({LeaveStatus? status, String? approvedBy}) {
    return Leave(
      id: id,
      employeeId: employeeId,
      date: date,
      reason: reason,
      leaveType: leaveType,
      duration: duration,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
    );
  }
}
