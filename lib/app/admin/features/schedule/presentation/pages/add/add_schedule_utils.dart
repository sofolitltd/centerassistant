import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddScheduleUtils {
  static List<String> generateTimeOptions(
    String start,
    String end, {
    bool includeStart = true,
  }) {
    List<String> options = [];
    double current = timeToDouble(start);
    double limit = timeToDouble(end);

    if (!includeStart) current += 0.5; // Start 30 mins after

    while (current <= limit) {
      int hour = current.floor();
      int minute = ((current - hour) * 60).round();
      options.add(
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      );
      current += 0.5; // 30 min increments
    }
    return options;
  }

  static String formatTimeToAmPm(String time) {
    if (time.isEmpty) return '';
    try {
      final cleanTime = time.split(' ').first;
      final parts = cleanTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final dt = DateTime(2024, 1, 1, hour, minute);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return time;
    }
  }

  static String normalizeTime(String time) {
    if (time.isEmpty) return '00:00';
    try {
      final cleanTime = time.split(' ').first;
      final parts = cleanTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '00:00';
    }
  }

  static String calculateDurationLabel(String start, String end) {
    final diff = timeToDouble(end) - timeToDouble(start);
    if (diff == 0.5) return '30 mins';
    if (diff == 1.0) return '1 hr';
    return '${diff.toStringAsFixed(1).replaceAll('.0', '')} hrs';
  }

  static double timeToDouble(String time) {
    try {
      final cleanTime = time.split(' ').first;
      final parts = cleanTime.split(':');
      return int.parse(parts[0]) + (int.parse(parts[1]) / 60.0);
    } catch (_) {
      return 0.0;
    }
  }

  static InputDecoration inputDecoration({String? label, String? suffix}) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}
