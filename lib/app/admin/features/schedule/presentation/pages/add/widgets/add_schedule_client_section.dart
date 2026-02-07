import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/client.dart';
import '/core/providers/session_providers.dart';

class AddScheduleClientSection extends StatelessWidget {
  final AsyncValue<List<Client>> clientsAsync;
  final Client? selectedClient;
  final ValueChanged<Client?>? onClientChanged;
  final String? selectedTimeSlotId;
  final AsyncValue<ScheduleView> scheduleAsync;

  const AddScheduleClientSection({
    super.key,
    required this.clientsAsync,
    required this.selectedClient,
    this.onClientChanged,
    this.selectedTimeSlotId,
    required this.scheduleAsync,
  });

  @override
  Widget build(BuildContext context) {
    final bool isReadOnly = onClientChanged == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Client name',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (isReadOnly)
          _buildReadOnlyView(context)
        else
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

              // Sort A-Z by name
              availableClients.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );

              return DropdownSearch<Client>(
                items: (filter, loadProps) => availableClients,
                itemAsString: (Client c) => c.name,
                selectedItem: availableClients.contains(selectedClient)
                    ? selectedClient
                    : null,
                compareFn: (a, b) => a.id == b.id,
                onChanged: onClientChanged,
                decoratorProps: DropDownDecoratorProps(
                  decoration: _inputDecoration(hint: 'Select Client'),
                ),
                popupProps: const PopupProps.menu(
                  showSearchBox: true,
                  fit: FlexFit.loose,
                  constraints: BoxConstraints(maxHeight: 400),
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Search client...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Error loading clients'),
          ),
      ],
    );
  }

  Widget _buildReadOnlyView(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        selectedClient?.name ?? 'No client selected',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black54,
            ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}
