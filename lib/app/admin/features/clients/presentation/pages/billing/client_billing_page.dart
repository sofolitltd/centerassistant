import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/providers/billing_providers.dart';
import '/core/providers/client_providers.dart';
import 'widgets/billing_discount_tab.dart';
import 'widgets/billing_history_tab.dart';
import 'widgets/billing_sessions_tab.dart';

class ClientBillingPage extends ConsumerStatefulWidget {
  final String clientId;

  const ClientBillingPage({super.key, required this.clientId});

  @override
  ConsumerState<ClientBillingPage> createState() => _ClientBillingPageState();
}

class _ClientBillingPageState extends ConsumerState<ClientBillingPage> {
  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(clientByIdProvider(widget.clientId));
    final transactionsAsync = ref.watch(
      clientTransactionsProvider(widget.clientId),
    );
    final sessionsAsync = ref.watch(
      clientMonthlySessionsProvider(widget.clientId),
    );

    return clientAsync.when(
      data: (client) {
        if (client == null) {
          return const Scaffold(body: Center(child: Text('Client not found')));
        }

        return DefaultTabController(
          length: 3, // Reduced from 4
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const TabBar(
                    tabAlignment: TabAlignment.start,
                    isScrollable: true,
                    padding: EdgeInsets.zero,
                    tabs: [
                      Tab(text: 'Monthly Sessions', height: 40),
                      Tab(text: 'Transactions', height: 40),
                      Tab(text: 'Discounts', height: 40),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        BillingSessionsTab(
                          client: client,
                          sessionsAsync: sessionsAsync,
                        ),
                        BillingHistoryTab(
                          client: client, // Pass client here
                          transactionsAsync: transactionsAsync,
                        ),
                        BillingDiscountTab(client: client),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}
