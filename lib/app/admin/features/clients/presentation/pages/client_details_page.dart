import 'package:center_assistant/app/admin/features/clients/presentation/pages/client_information_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/models/client.dart';
import '/core/providers/client_providers.dart';
import 'billing/client_billing_page.dart';

class ClientDetailsPage extends ConsumerStatefulWidget {
  final String clientId;
  final String initialTab;

  const ClientDetailsPage({
    super.key,
    required this.clientId,
    this.initialTab = 'details',
  });

  @override
  ConsumerState<ClientDetailsPage> createState() => _ClientDetailsPageState();
}

class _ClientDetailsPageState extends ConsumerState<ClientDetailsPage> {
  void _onTabChanged(String tab) {
    context.go('/admin/clients/${widget.clientId}/$tab');
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      body: clientsAsync.when(
        data: (clients) {
          final client = clients
              .where((c) => c.id == widget.clientId)
              .firstOrNull;
          if (client == null) {
            return const Center(child: Text('Client not found.'));
          }

          return Column(
            children: [
              //
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.go('/admin/dashboard'),
                      child: const Text(
                        'Admin',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey,
                    ),
                    InkWell(
                      onTap: () => context.go('/admin/clients'),
                      child: const Text(
                        'Clients',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey,
                    ),
                    Text(client.name, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),

              //
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: .circular(8),
                      ),

                      padding: .fromLTRB(8, 8, 8, 8),
                      margin: .symmetric(horizontal: 16),
                      child: _buildTabSwitcher(),
                    ),

                    SizedBox(height: 16),
                    //
                    Expanded(child: _buildTabContent(client)),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Row(
      children: [
        _TabButton(
          label: 'Details',
          isSelected: widget.initialTab == 'details',
          onTap: () => _onTabChanged('details'),
        ),
        const SizedBox(width: 8),
        _TabButton(
          label: 'Schedule',
          isSelected: widget.initialTab == 'schedule',
          onTap: () => _onTabChanged('schedule'),
        ),
        const SizedBox(width: 8),
        _TabButton(
          label: 'Availability',
          isSelected: widget.initialTab == 'availability',
          onTap: () => _onTabChanged('availability'),
        ),
        const SizedBox(width: 8),
        _TabButton(
          label: 'Billing',
          isSelected: widget.initialTab == 'billing',
          onTap: () => _onTabChanged('billing'),
        ),
      ],
    );
  }

  Widget _buildTabContent(Client client) {
    switch (widget.initialTab) {
      case 'details':
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClientInformationPage(client: client),
        );
      case 'schedule':
        return _buildPlaceholder(
          'Schedule',
          () => context.go('/admin/schedule?clientId=${client.id}'),
        );
      case 'availability':
        return _buildPlaceholder(
          'Availability',
          () => context.go(
            '/admin/clients/${client.id}/availability?name=${Uri.encodeComponent(client.name)}',
          ),
        );
      case 'billing':
        return ClientBillingPage(clientId: client.id);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPlaceholder(String title, VoidCallback onAction) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            'View client $title in the dedicated module.',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onAction, child: Text('Go to $title')),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black54,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
