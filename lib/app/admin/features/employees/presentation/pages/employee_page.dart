import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
    final double width = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (width > 1100) {
      crossAxisCount = 4;
    } else if (width > 900) {
      crossAxisCount = 3;
    } else if (width > 600) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    final bool isMobile = width < 600;

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Employees',
                          style: Theme.of(context).textTheme.headlineMedium!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            InkWell(
                              onTap: () => context.go('/admin/layout'),
                              child: Text(
                                'Admin',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Colors.grey,
                            ),
                            Text(
                              'Employees',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    ElevatedButton.icon(
                      onPressed: () => context.go('/admin/employees/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Employee'),
                    ),
                ],
              ),
              if (isMobile) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.go('/admin/employees/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Employee'),
                ),
              ],
              const SizedBox(height: 24),
              employeesAsync.when(
                data: (employees) {
                  if (employees.isEmpty) {
                    return const Center(
                      child: Text('No employees found. Add one!'),
                    );
                  }
                  return MasonryGridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      final employee = employees[index];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundImage: NetworkImage(
                                      employee.image,
                                    ),
                                    child: employee.image.isEmpty
                                        ? const Icon(Icons.person, size: 30)
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    employee.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        employee.department.toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey.shade600,
                                              letterSpacing: 0.5,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(width: 8),
                                      // Portal access indicator
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: employee.hasPortalAccess
                                              ? Colors.green.shade100
                                              : Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: employee.hasPortalAccess
                                                ? Colors.green.shade300
                                                : Colors.orange.shade300,
                                            width: 1,
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
                                            const SizedBox(width: 3),
                                            Text(
                                              employee.hasPortalAccess
                                                  ? 'Portal'
                                                  : 'No Access',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: employee.hasPortalAccess
                                                    ? Colors.green.shade700
                                                    : Colors.orange.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () => _showEmployeeInfoDialog(
                                      context,
                                      employee,
                                    ),
                                    child: const Text('View Details'),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            context.go(
                                              '/admin/employees/${employee.id}/schedule',
                                            );
                                          },
                                          child: const Text(
                                            'Schedule',
                                            style: TextStyle(fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            context.go(
                                              '/admin/employees/${employee.id}/availability?name=${Uri.encodeComponent(employee.name)}',
                                            );
                                          },

                                          child: const Text(
                                            'Availability',
                                            style: TextStyle(fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: PopupMenuButton<String>(
                                color: Colors.white,
                                icon: const Icon(Icons.more_vert, size: 20),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditEmployeeDialog(
                                      context,
                                      ref,
                                      employee,
                                    );
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmDialog(
                                      context,
                                      ref,
                                      employee,
                                    );
                                  } else if (value == 'invite') {
                                    context.go(
                                      '/admin/employees/invite?userId=${employee.id}',
                                    );
                                  } else if (value == 'toggle_access') {
                                    // Toggle active status instantly
                                    final updatedEmployee = Employee(
                                      id: employee.id,
                                      name: employee.name,
                                      personalPhone: employee.personalPhone,
                                      officialPhone: employee.officialPhone,
                                      personalEmail: employee.personalEmail,
                                      officialEmail: employee.officialEmail,
                                      department: employee.department,
                                      email: employee.email,
                                      password: employee.password,
                                      role: employee.role,
                                      mustChangePassword:
                                          employee.mustChangePassword,
                                      isActive: !employee.isActive, // Toggle
                                      joinDate: employee.joinDate,
                                      createdAt: employee.createdAt,
                                      image: employee.image,
                                    );
                                    ref
                                        .read(employeeServiceProvider)
                                        .updateEmployee(updatedEmployee);

                                    // Show feedback
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          employee.isActive
                                              ? '${employee.name} portal access blocked'
                                              : '${employee.name} portal access enabled',
                                        ),
                                        backgroundColor: employee.isActive
                                            ? Colors.orange
                                            : Colors.green,
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit, size: 18),
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
                                        color: employee.hasPortalAccess
                                            ? Colors.blue
                                            : Colors.green,
                                      ),
                                      title: Text(
                                        employee.hasPortalAccess
                                            ? 'Manage Portal Access'
                                            : 'Invite to Portal',
                                        style: TextStyle(
                                          color: employee.hasPortalAccess
                                              ? Colors.blue
                                              : Colors.green,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  // Block/Unblock toggle - only show if employee has portal credentials
                                  if (employee.email.isNotEmpty &&
                                      employee.password.isNotEmpty)
                                    PopupMenuItem(
                                      value: 'toggle_access',
                                      child: ListTile(
                                        leading: Icon(
                                          employee.isActive
                                              ? Icons.block
                                              : Icons.check_circle_outline,
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
                                        contentPadding: EdgeInsets.zero,
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
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
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
                      backgroundImage: NetworkImage(employee.image),
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Text(
                                'ID: ${employee.id.toUpperCase()}',
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
                          const SizedBox(height: 4),
                          Text(
                            'Joined: ${DateFormat('dd MMM, yyyy').format(employee.joinDate)}',
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
                        onTap: () => SharePlus.instance.share(
                          ShareParams(text: employee.personalPhone),
                        ),
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
                        onTap: () => SharePlus.instance.share(
                          ShareParams(text: employee.officialPhone),
                        ),
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
                        onTap: () => SharePlus.instance.share(
                          ShareParams(text: employee.personalEmail),
                        ),
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
                        onTap: () => SharePlus.instance.share(
                          ShareParams(text: employee.officialEmail),
                        ),
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

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  void _showEditEmployeeDialog(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
  ) {
    final nameController = TextEditingController(text: employee.name);
    final pPhoneController = TextEditingController(
      text: employee.personalPhone,
    );
    final oPhoneController = TextEditingController(
      text: employee.officialPhone,
    );
    final pEmailController = TextEditingController(
      text: employee.personalEmail,
    );
    final oEmailController = TextEditingController(
      text: employee.officialEmail,
    );
    String selectedDept = employee.department;

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final departmentsAsync = ref.watch(departmentsProvider);
          return departmentsAsync.when(
            data: (departments) => AlertDialog(
              insetPadding: EdgeInsets.zero,
              title: Container(
                constraints: const BoxConstraints(minWidth: 350),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Employee'),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldTitle('Name'),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(hintText: 'Enter name'),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldTitle('Personal Phone'),
                    TextField(
                      controller: pPhoneController,
                      decoration: const InputDecoration(
                        hintText: 'Enter personal phone',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldTitle('Official Phone'),
                    TextField(
                      controller: oPhoneController,
                      decoration: const InputDecoration(
                        hintText: 'Enter official phone',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldTitle('Personal Email'),
                    TextField(
                      controller: pEmailController,
                      decoration: const InputDecoration(
                        hintText: 'Enter personal email',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldTitle('Official Email'),
                    TextField(
                      controller: oEmailController,
                      decoration: const InputDecoration(
                        hintText: 'Enter official email',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldTitle('Department'),
                    ButtonTheme(
                      alignedDropdown: true,
                      child: DropdownButtonFormField<String>(
                        initialValue: departments.contains(selectedDept)
                            ? selectedDept
                            : (departments.isNotEmpty
                                  ? departments.first
                                  : null),
                        items: departments
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                        onChanged: (val) => selectedDept = val!,
                        decoration: const InputDecoration(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final updatedEmployee = Employee(
                      id: employee.id,
                      name: nameController.text,
                      personalPhone: pPhoneController.text,
                      officialPhone: oPhoneController.text,
                      personalEmail: pEmailController.text,
                      officialEmail: oEmailController.text,
                      department: selectedDept,
                      email: employee.email,
                      password: employee.password,
                      role: employee.role,
                      mustChangePassword: employee.mustChangePassword,
                      joinDate: employee.joinDate,
                      createdAt: employee.createdAt,
                      image: employee.image,
                    );
                    ref
                        .read(employeeServiceProvider)
                        .updateEmployee(updatedEmployee);
                    Navigator.pop(context);
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error loading departments: $e'),
          );
        },
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
