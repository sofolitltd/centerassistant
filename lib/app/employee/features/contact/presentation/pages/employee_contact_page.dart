import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '/core/providers/employee_providers.dart';

class EmployeeContactPage extends ConsumerWidget {
  const EmployeeContactPage({super.key});

  Future<void> _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
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
                Text('Directory', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Employee Directory',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find and contact your colleagues easily.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: Card(
                elevation: 0,
                margin: .zero,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: employeesAsync.when(
                  data: (employees) {
                    final activeEmployees = employees
                        .where((e) => e.isActive)
                        .toList();
                    if (activeEmployees.isEmpty) {
                      return const Center(child: Text('No colleagues found.'));
                    }

                    // Sort by name
                    activeEmployees.sort((a, b) => a.name.compareTo(b.name));

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        const double tableMinWidth = 1200.0;

                        Widget table = DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ),
                          dataRowMaxHeight: 52,
                          dataRowMinHeight: 48,
                          columnSpacing: 24,
                          border: TableBorder.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Employee',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Department',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Designation',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Official Phone',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Personal Phone',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Official Email',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Personal Email',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: activeEmployees.map((colleague) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundImage:
                                            colleague.image.isNotEmpty
                                            ? NetworkImage(colleague.image)
                                            : null,
                                        child: colleague.image.isEmpty
                                            ? const Icon(
                                                LucideIcons.user,
                                                size: 14,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        colleague.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    colleague.department.toUpperCase(),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    colleague.designation,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                _buildClickableCell(
                                  context,
                                  colleague.officialPhone,
                                  isPhone: true,
                                ),
                                _buildClickableCell(
                                  context,
                                  colleague.personalPhone,
                                  isPhone: true,
                                ),
                                _buildClickableCell(
                                  context,
                                  colleague.officialEmail,
                                  isPhone: false,
                                ),
                                _buildClickableCell(
                                  context,
                                  colleague.personalEmail,
                                  isPhone: false,
                                ),
                              ],
                            );
                          }).toList(),
                        );

                        if (constraints.maxWidth < tableMinWidth) {
                          return Scrollbar(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: tableMinWidth,
                                ),
                                child: table,
                              ),
                            ),
                          );
                        } else {
                          return SizedBox(width: double.infinity, child: table);
                        }
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataCell _buildClickableCell(
    BuildContext context,
    String value, {
    required bool isPhone,
  }) {
    if (value.isEmpty) {
      return const DataCell(Text('-', style: TextStyle(fontSize: 13)));
    }

    return DataCell(
      InkWell(
        onTap: () {
          final url = isPhone
              ? 'tel:${value.replaceAll(' ', '')}'
              : 'mailto:$value';
          _launchURL(context, url);
        },
        child: Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
