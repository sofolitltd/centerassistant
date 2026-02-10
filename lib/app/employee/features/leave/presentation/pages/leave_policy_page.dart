import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LeavePolicyPage extends StatelessWidget {
  const LeavePolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                InkWell(
                  onTap: () => context.go('/employee/dashboard'),
                  child: Text(
                    'Overview',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                InkWell(
                  onTap: () => context.go('/employee/leave'),
                  child: Text(
                    'Leave Management',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                Text('Leave Policy', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Leave Policy',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPolicySection(
                      theme,
                      LucideIcons.calendar,
                      'Leave Entitlement',
                      'Employees are entitled to a total of 33 days of paid leave per calendar year, categorized as follows:\n\n• Annual Leave: 18 Days\n• Sick Leave: 10 Days\n• Causal Leave: 5 Days',
                    ),
                    const Divider(height: 40),
                    _buildPolicySection(
                      theme,
                      LucideIcons.clock,
                      'Notice Period',
                      'Applications for Annual Leave must be submitted at least 15 days in advance. Causal leave requires a minimum of 2 days notice. Sick leave should be reported as soon as possible on the day of absence.',
                    ),
                    const Divider(height: 40),
                    _buildPolicySection(
                      theme,
                      LucideIcons.fileText,
                      'Approval Process',
                      'All leave requests are subject to approval by the center administrator based on operational requirements and staff leaves. You will receive an automated notification once your request has been processed.',
                    ),
                    const Divider(height: 40),
                    _buildPolicySection(
                      theme,
                      LucideIcons.info,
                      'Unpaid Leave',
                      'Unpaid leave may be granted in exceptional circumstances at the discretion of management once all paid leave entitlements have been exhausted.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(
    ThemeData theme,
    IconData icon,
    String title,
    String content,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
