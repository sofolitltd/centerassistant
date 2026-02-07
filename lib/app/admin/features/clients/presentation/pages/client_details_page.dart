import 'package:center_assistant/app/admin/features/clients/presentation/pages/client_information_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/models/client.dart';
import '/core/providers/client_providers.dart';
import '../../../schedule/presentation/pages/home/schedule_specific_page.dart';
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
          final client =
              clients.where((c) => c.id == widget.clientId).firstOrNull;
          if (client == null) {
            return const Center(child: Text('Client not found.'));
          }

          return Column(
            children: [
              // Responsive Breadcrumbs
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    InkWell(
                      onTap: () => context.go('/admin/dashboard'),
                      child: const Text(
                        'Admin',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                    InkWell(
                      onTap: () => context.go('/admin/clients'),
                      child: const Text(
                        'Clients',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                    Text(
                      client.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Switcher Container
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: _buildTabSwitcher(),
              ),

              // Content Area
              Expanded(child: _buildTabContent(client)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      child: Row(
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
            label: 'Billing',
            isSelected: widget.initialTab == 'billing',
            onTap: () => _onTabChanged('billing'),
          ),
          const SizedBox(width: 8),
          _TabButton(
            label: 'Leaves',
            isSelected: widget.initialTab == 'leaves',
            onTap: () => _onTabChanged('leaves'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(Client client) {
    switch (widget.initialTab) {
      case 'details':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ClientInformationPage(client: client),
        );
      case 'schedule':
        return ScheduleSpecificPage(clientId: client.id);
      case 'billing':
        return ClientBillingPage(clientId: client.id);
      case 'leaves':
        return _buildPlaceholder(
          'Leaves',
          () => context.go(
            '/admin/clients/${client.id}/leaves?name=${Uri.encodeComponent(client.name)}',
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildPlaceholder(String title, VoidCallback onAction) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black54,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
