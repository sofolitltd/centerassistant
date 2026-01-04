import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/employee.dart';
import '/core/providers/auth_providers.dart';
import '/core/providers/employee_providers.dart';

class EmployeeProfilePage extends ConsumerStatefulWidget {
  const EmployeeProfilePage({super.key});

  @override
  ConsumerState<EmployeeProfilePage> createState() =>
      _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends ConsumerState<EmployeeProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _pPhoneController;
  late TextEditingController _oPhoneController;
  late TextEditingController _pEmailController;
  late TextEditingController _oEmailController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _pPhoneController = TextEditingController();
    _oPhoneController = TextEditingController();
    _pEmailController = TextEditingController();
    _oEmailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pPhoneController.dispose();
    _oPhoneController.dispose();
    _pEmailController.dispose();
    _oEmailController.dispose();
    super.dispose();
  }

  void _initFields(Employee employee) {
    _nameController.text = employee.name;
    _pPhoneController.text = employee.personalPhone;
    _oPhoneController.text = employee.officialPhone;
    _pEmailController.text = employee.personalEmail;
    _oEmailController.text = employee.officialEmail;
  }

  Future<void> _handleSave(Employee currentEmployee) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedEmployee = Employee(
        id: currentEmployee.id,
        employeeId: currentEmployee.employeeId,
        name: _nameController.text.trim(),
        personalPhone: _pPhoneController.text.trim(),
        officialPhone: _oPhoneController.text.trim(),
        personalEmail: _pEmailController.text.trim(),
        officialEmail: _oEmailController.text.trim(),
        department: currentEmployee.department,
        email: currentEmployee.email,
        password: currentEmployee.password,
        role: currentEmployee.role,
        mustChangePassword: currentEmployee.mustChangePassword,
        isActive: currentEmployee.isActive,
        joinDate: currentEmployee.joinDate,
        createdAt: currentEmployee.createdAt,
        image: currentEmployee.image,
      );

      await ref.read(employeeServiceProvider).updateEmployee(updatedEmployee);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final employeeAsync = authState.employeeId != null
        ? ref.watch(employeeByIdProvider(authState.employeeId!))
        : const AsyncValue<Employee?>.data(null);

    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
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
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey,
                    ),
                    Text('My Profile', style: theme.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 16),

                employeeAsync.when(
                  data: (employee) {
                    if (employee == null) {
                      return const Center(child: Text('Profile not found'));
                    }

                    if (!_isEditing) {
                      _initFields(employee);
                    }

                    return Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(theme, isMobile, employee),
                          const SizedBox(height: 32),
                          _buildProfileCard(theme, isMobile, employee),
                          const SizedBox(height: 32),
                          _buildInfoSection(theme, isMobile),
                          const SizedBox(height: 32),
                          _buildAccountStatus(theme, isMobile, employee),
                        ],
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isMobile, Employee employee) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'My Profile',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!_isEditing)
          ElevatedButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(LucideIcons.edit3, size: 18),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
            ),
          )
        else
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _isEditing = false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _handleSave(employee),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.save, size: 18),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildProfileCard(ThemeData theme, bool isMobile, Employee employee) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: isMobile
            ? Column(
                children: [
                  _buildAvatar(theme, employee),
                  const SizedBox(height: 20),
                  _buildBasicInfo(theme, employee, textAlign: TextAlign.center),
                ],
              )
            : Row(
                children: [
                  _buildAvatar(theme, employee),
                  const SizedBox(width: 32),
                  Expanded(child: _buildBasicInfo(theme, employee)),
                ],
              ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, Employee employee) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey.withValues(alpha: 0.1),
          backgroundImage: employee.image.isNotEmpty
              ? NetworkImage(employee.image)
              : null,
          child: employee.image.isEmpty
              ? const Icon(LucideIcons.user, size: 50, color: Colors.grey)
              : null,
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              radius: 18,
              child: IconButton(
                icon: const Icon(
                  LucideIcons.camera,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: () {}, // Image upload logic
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBasicInfo(
    ThemeData theme,
    Employee employee, {
    TextAlign textAlign = TextAlign.start,
  }) {
    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          employee.name,
          textAlign: textAlign,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          employee.department,
          textAlign: textAlign,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'ID: ${employee.id.toUpperCase()}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(theme, 'Basic Information'),
        const SizedBox(height: 12),
        _buildResponsiveGrid(
          children: [
            _buildTextField(
              label: 'Full Name',
              controller: _nameController,
              enabled: _isEditing,
              prefixIcon: LucideIcons.user,
              isRequired: true,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSectionTitle(theme, 'Contact Information'),
        const SizedBox(height: 12),
        _buildResponsiveGrid(
          isMobile: isMobile,
          children: [
            _buildTextField(
              label: 'Personal Phone',
              controller: _pPhoneController,
              enabled: _isEditing,
              prefixIcon: LucideIcons.phone,
            ),
            _buildTextField(
              label: 'Official Phone',
              controller: _oPhoneController,
              enabled: _isEditing,
              prefixIcon: LucideIcons.phoneCall,
            ),
            _buildTextField(
              label: 'Personal Email',
              controller: _pEmailController,
              enabled: _isEditing,
              prefixIcon: LucideIcons.mail,
            ),
            _buildTextField(
              label: 'Official Email',
              controller: _oEmailController,
              enabled: _isEditing,
              prefixIcon: LucideIcons.briefcase,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResponsiveGrid({
    required List<Widget> children,
    bool isMobile = false,
  }) {
    if (isMobile) {
      return Column(
        children: children
            .map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: child,
              ),
            )
            .toList(),
      );
    }

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: children
          .map(
            (child) => SizedBox(
              width: (900 - 48 - 24) / 2, // Max width - padding - spacing
              child: child,
            ),
          )
          .toList(),
    );
  }

  Widget _buildAccountStatus(
    ThemeData theme,
    bool isMobile,
    Employee employee,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(theme, 'Employment Details'),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoBadge(
                  'Joined Date',
                  employee.joinDate.toString().split(' ')[0],
                  LucideIcons.calendar,
                ),
                _buildInfoBadge(
                  'System Role',
                  employee.role.toUpperCase(),
                  LucideIcons.shieldCheck,
                ),
                _buildInfoBadge(
                  'Account',
                  employee.isActive ? 'ACTIVE' : 'INACTIVE',
                  LucideIcons.activity,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData prefixIcon,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(prefixIcon, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: !enabled,
            fillColor: enabled ? null : Colors.grey.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          validator: isRequired
              ? (v) => v == null || v.isEmpty ? 'Required' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildInfoBadge(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
