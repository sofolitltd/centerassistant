import 'dart:ui';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '/core/models/employee.dart';
import '/core/providers/employee_providers.dart';

class EmployeePage extends ConsumerWidget {
  const EmployeePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);
    final schedulableDeptsAsync = ref.watch(schedulableDepartmentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => context.go('/admin/dashboard'),
                          child: Text(
                            'Admin',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey,
                        ),
                        Text('Employees', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Employee Directory',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go('/admin/employees/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Employee'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Table Card
            Expanded(
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: employeesAsync.when(
                  data: (employees) {
                    if (employees.isEmpty) {
                      return const Center(child: Text('No employees found.'));
                    }

                    return schedulableDeptsAsync.when(
                      data: (schedulableDepts) {
                        // Reverse numeric sort by employeeId
                        final sortedEmployees = List<Employee>.from(employees)
                          ..sort((a, b) {
                            try {
                              final idA = int.parse(a.employeeId);
                              final idB = int.parse(b.employeeId);
                              return idB.compareTo(idA);
                            } catch (_) {
                              return b.employeeId.compareTo(a.employeeId);
                            }
                          });

                        return ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.stylus,
                            },
                          ),
                          child: DataTable2(
                            columnSpacing: 24,
                            horizontalMargin: 12,
                            minWidth: 1100,
                            headingRowColor: WidgetStateProperty.all(
                              theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                            ),
                            border: TableBorder.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            columns: const [
                              DataColumn2(
                                label: Text(
                                  'ID',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                headingRowAlignment: MainAxisAlignment.center,
                                fixedWidth: 60,
                              ),
                              DataColumn2(
                                label: Text(
                                  'Employee Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                size: ColumnSize.L,
                              ),
                              DataColumn2(
                                label: Text(
                                  'Department',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn2(
                                label: Text(
                                  'Designation',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn2(
                                label: Text(
                                  'Contact',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                size: ColumnSize.M,
                              ),
                              DataColumn2(
                                label: Text(
                                  'Portal Access',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                fixedWidth: 120,
                              ),
                              DataColumn2(
                                label: Text(
                                  'Actions',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                fixedWidth: 130,
                              ),
                            ],
                            rows: sortedEmployees.map((employee) {
                              final bool isSchedulable = schedulableDepts
                                  .contains(employee.department);

                              return DataRow2(
                                onTap: () =>
                                    _showEmployeeInfoDialog(context, employee),
                                cells: [
                                  DataCell(
                                    Center(
                                      child: Text(
                                        employee.employeeId,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundImage:
                                              employee.image.isNotEmpty
                                              ? NetworkImage(employee.image)
                                              : null,
                                          child: employee.image.isEmpty
                                              ? const Icon(
                                                  Icons.person,
                                                  size: 14,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            employee.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(employee.department.toUpperCase()),
                                  ),
                                  DataCell(Text(employee.designation)),
                                  DataCell(
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (employee.officialPhone.isNotEmpty)
                                          Text(
                                            employee.officialPhone,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        if (employee.officialEmail.isNotEmpty)
                                          Text(
                                            employee.officialEmail,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: employee.hasPortalAccess
                                            ? Colors.green.shade50
                                            : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: employee.hasPortalAccess
                                              ? Colors.green.shade200
                                              : Colors.orange.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            employee.hasPortalAccess
                                                ? Icons.check_circle
                                                : Icons.lock_outline,
                                            size: 10,
                                            color: employee.hasPortalAccess
                                                ? Colors.green.shade700
                                                : Colors.orange.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            employee.hasPortalAccess
                                                ? 'Active'
                                                : 'No Access',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: employee.hasPortalAccess
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            LucideIcons.calendar,
                                            size: 16,
                                          ),
                                          onPressed: isSchedulable
                                              ? () => context.go(
                                                  '/admin/schedule?employeeId=${employee.id}',
                                                )
                                              : null,
                                          tooltip: 'Schedule',
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            LucideIcons.clock,
                                            size: 16,
                                          ),
                                          onPressed: () => context.go(
                                            '/admin/employees/${employee.id}/availability?name=${Uri.encodeComponent(employee.name)}',
                                          ),
                                          tooltip: 'Availability',
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(
                                            Icons.more_vert,
                                            size: 16,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onSelected: (value) =>
                                              _handleMenuAction(
                                                context,
                                                ref,
                                                employee,
                                                value,
                                              ),
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.edit,
                                                  size: 18,
                                                ),
                                                title: Text('Edit'),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'invite',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.person_add,
                                                  size: 18,
                                                  color:
                                                      employee.hasPortalAccess
                                                      ? Colors.blue
                                                      : Colors.green,
                                                ),
                                                title: Text(
                                                  employee.hasPortalAccess
                                                      ? 'Manage Portal'
                                                      : 'Invite to Portal',
                                                  style: TextStyle(
                                                    color:
                                                        employee.hasPortalAccess
                                                        ? Colors.blue
                                                        : Colors.green,
                                                  ),
                                                ),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                            if (employee.email.isNotEmpty &&
                                                employee.password.isNotEmpty)
                                              PopupMenuItem(
                                                value: 'toggle_access',
                                                child: ListTile(
                                                  leading: Icon(
                                                    employee.isActive
                                                        ? Icons.block
                                                        : Icons
                                                              .check_circle_outline,
                                                    size: 18,
                                                    color: employee.isActive
                                                        ? Colors.orange
                                                        : Colors.green,
                                                  ),
                                                  title: Text(
                                                    employee.isActive
                                                        ? 'Block Portal Access'
                                                        : 'Enable Portal Access',
                                                    style: TextStyle(
                                                      color: employee.isActive
                                                          ? Colors.orange
                                                          : Colors.green,
                                                    ),
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.delete,
                                                  size: 18,
                                                  color: Colors.red,
                                                ),
                                                title: Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(
                        child: Text('Error loading departments'),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
    String value,
  ) {
    if (value == 'edit') {
      context.go('/admin/employees/${employee.id}/edit');
    } else if (value == 'delete') {
      _showDeleteConfirmDialog(context, ref, employee);
    } else if (value == 'invite') {
      context.go('/admin/employees/invite?userId=${employee.id}');
    } else if (value == 'toggle_access') {
      final updatedEmployee = employee.copyWith(isActive: !employee.isActive);
      ref.read(employeeServiceProvider).updateEmployee(updatedEmployee);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            employee.isActive
                ? '${employee.name} portal access blocked'
                : '${employee.name} portal access enabled',
          ),
          backgroundColor: employee.isActive ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  void _showEmployeeInfoDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        content: Container(
          constraints: const BoxConstraints(minWidth: 350, maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Employee Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      child: const Icon(Icons.close, size: 16),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: employee.image.isNotEmpty
                          ? NetworkImage(employee.image)
                          : null,
                      child: employee.image.isEmpty
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Text(
                                'ID: ${employee.employeeId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  '|',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              ),
                              Text(
                                employee.department.toUpperCase(),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                      letterSpacing: 1.2,
                                    ),
                              ),
                            ],
                          ),
                          Text(
                            employee.designation,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Joined: ${DateFormat('dd MMM, yyyy').format(employee.joinedDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildInfoSection(context, 'Contact Information', [
                  _buildInfoRow(
                    context,
                    Icons.phone_iphone,
                    'Personal Phone',
                    employee.personalPhone,
                    actions: [
                      _ActionButton(
                        icon: LucideIcons.copy,
                        onTap: () =>
                            _copyToClipboard(context, employee.personalPhone),
                      ),
                      _ActionButton(
                        icon: LucideIcons.phone,
                        onTap: () =>
                            _launchURL('tel:${employee.personalPhone}'),
                      ),
                      _ActionButton(
                        icon: LucideIcons.share2,
                        onTap: () => Share.share(employee.personalPhone),
                      ),
                    ],
                  ),
                  _buildInfoRow(
                    context,
                    Icons.phone_android,
                    'Official Phone',
                    employee.officialPhone,
                    actions: [
                      _ActionButton(
                        icon: LucideIcons.copy,
                        onTap: () =>
                            _copyToClipboard(context, employee.officialPhone),
                      ),
                      _ActionButton(
                        icon: LucideIcons.phone,
                        onTap: () =>
                            _launchURL('tel:${employee.officialPhone}'),
                      ),
                      _ActionButton(
                        icon: LucideIcons.share2,
                        onTap: () => Share.share(employee.officialPhone),
                      ),
                    ],
                  ),
                  _buildInfoRow(
                    context,
                    Icons.email_outlined,
                    'Personal Email',
                    employee.personalEmail,
                    actions: [
                      _ActionButton(
                        icon: LucideIcons.copy,
                        onTap: () =>
                            _copyToClipboard(context, employee.personalEmail),
                      ),
                      _ActionButton(
                        icon: LucideIcons.mail,
                        onTap: () =>
                            _launchURL('mailto:${employee.personalEmail}'),
                      ),
                      _ActionButton(
                        icon: LucideIcons.share2,
                        onTap: () => Share.share(employee.personalEmail),
                      ),
                    ],
                  ),
                  _buildInfoRow(
                    context,
                    Icons.work_outline,
                    'Official Email',
                    employee.officialEmail,
                    actions: [
                      _ActionButton(
                        icon: LucideIcons.copy,
                        onTap: () =>
                            _copyToClipboard(context, employee.officialEmail),
                      ),
                      _ActionButton(
                        icon: LucideIcons.mail,
                        onTap: () =>
                            _launchURL('mailto:${employee.officialEmail}'),
                      ),
                      _ActionButton(
                        icon: LucideIcons.share2,
                        onTap: () => Share.share(employee.officialEmail),
                      ),
                    ],
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: $text'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const Divider(height: 24),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    List<Widget>? actions,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (actions != null && value.isNotEmpty) ...[
            const SizedBox(width: 8),
            Row(mainAxisSize: MainAxisSize.min, children: actions),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(employeeServiceProvider).deleteEmployee(employee.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: Colors.blue.shade700),
        ),
      ),
    );
  }
}
