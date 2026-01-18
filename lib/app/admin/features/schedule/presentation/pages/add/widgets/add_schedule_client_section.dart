import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/client.dart';
import '/core/providers/session_providers.dart';

class AddScheduleClientSection extends StatelessWidget {
  final AsyncValue<List<Client>> clientsAsync;
  final Client? selectedClient;
  final ValueChanged<Client?> onClientChanged;
  final String? selectedTimeSlotId;
  final AsyncValue<ScheduleView> scheduleAsync;

  const AddScheduleClientSection({
    super.key,
    required this.clientsAsync,
    required this.selectedClient,
    required this.onClientChanged,
    this.selectedTimeSlotId,
    required this.scheduleAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Client name',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        clientsAsync.when(
          data: (clients) {
            // Filter out busy clients if a slot is selected
            final busyClientIds = selectedTimeSlotId != null
                ? scheduleAsync.value?.sessionsByTimeSlot[selectedTimeSlotId]
                          ?.map((s) => s.clientDocId)
                          .toSet() ??
                      {}
                : <String>{};

            final availableClients = clients.where((c) {
              return !busyClientIds.contains(c.id);
            }).toList();

            return DropdownButtonFormField<Client>(
              isExpanded: true,
              hint: const Text('Select Client'),
              initialValue: availableClients.contains(selectedClient)
                  ? selectedClient
                  : null,
              onChanged: onClientChanged,
              items: availableClients
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              decoration: _inputDecoration(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Error loading clients'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? label, String? suffix}) {
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
