import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/client.dart';
import '/core/providers/billing_providers.dart';
import '/core/providers/client_providers.dart';
import 'widgets/billing_deposit_tab.dart';
import 'widgets/billing_history_tab.dart';
import 'widgets/billing_sessions_tab.dart';

class ClientBillingPage extends ConsumerStatefulWidget {
  final String clientId;

  const ClientBillingPage({super.key, required this.clientId});

  @override
  ConsumerState<ClientBillingPage> createState() => _ClientBillingPageState();
}

class _ClientBillingPageState extends ConsumerState<ClientBillingPage> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

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
          length: 3,
          child: Scaffold(
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
                      Tab(text: 'Transaction History', height: 40),
                      Tab(text: 'Deposit & Payment', height: 40),
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
                        BillingHistoryTab(transactionsAsync: transactionsAsync),
                        BillingDepositTab(
                          client: client,
                          amountController: _amountController,
                          onDeposit: _handleDeposit,
                          onPayment: _handlePayment,
                        ),
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

  Future<void> _handleDeposit(Client client, double amount, String note) async {
    await ref
        .read(billingServiceProvider)
        .addSecurityDeposit(client: client, amount: amount, description: note);
    _amountController.clear();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Security deposit added')));
    }
  }

  Future<void> _handlePayment(Client client, double amount, String note) async {
    await ref
        .read(billingServiceProvider)
        .addPayment(client: client, amount: amount, description: note);
    _amountController.clear();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment added to wallet')));
    }
  }
}
