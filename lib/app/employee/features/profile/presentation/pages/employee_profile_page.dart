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

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: .centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumbs
                Row(
                  children: [
                    InkWell(
                      onTap: () => context.go('/employee/layout'),
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
                      return const Center(child: Text('Not found'));
                    }

                    // Only init fields once when not editing or when employee data changes
                    if (!_isEditing) {
                      _initFields(employee);
                    }

                    return Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                  onPressed: () =>
                                      setState(() => _isEditing = true),
                                  icon: const Icon(LucideIcons.edit3, size: 18),
                                  label: const Text('Edit Profile'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        theme.colorScheme.secondary,
                                    foregroundColor:
                                        theme.colorScheme.onSecondary,
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          setState(() => _isEditing = false),
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : () => _handleSave(employee),
                                      icon: _isLoading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              LucideIcons.save,
                                              size: 18,
                                            ),
                                      label: const Text('Save Changes'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.primary,
                                        foregroundColor:
                                            theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          Center(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Row(
                                spacing: 16,
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 60,
                                        backgroundColor: Colors.grey.withValues(
                                          alpha: 0.1,
                                        ),
                                        backgroundImage:
                                            employee.image.isNotEmpty
                                            ? NetworkImage(employee.image)
                                            : null,
                                        child: employee.image.isEmpty
                                            ? const Icon(
                                                LucideIcons.user,
                                                size: 50,
                                              )
                                            : null,
                                      ),
                                      if (_isEditing)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: CircleAvatar(
                                            backgroundColor:
                                                theme.colorScheme.primary,
                                            radius: 18,
                                            child: IconButton(
                                              icon: const Icon(
                                                LucideIcons.camera,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                // Implement image upload
                                              },
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Column(
                                    crossAxisAlignment: .start,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        employee.name,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        employee.department,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: Colors.grey),
                                      ),
                                      const SizedBox(),
                                      //id
                                      Text(
                                        'ID: ${employee.id.toUpperCase()}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          _buildSectionTitle(context, 'Basic Information'),
                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
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
                          ),

                          const SizedBox(height: 32),

                          _buildSectionTitle(context, 'Contact Information'),
                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Personal Phone',
                                        controller: _pPhoneController,
                                        enabled: _isEditing,
                                        prefixIcon: LucideIcons.phone,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Official Phone',
                                        controller: _oPhoneController,
                                        enabled: _isEditing,
                                        prefixIcon: LucideIcons.phoneCall,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Personal Email',
                                        controller: _pEmailController,
                                        enabled: _isEditing,
                                        prefixIcon: LucideIcons.mail,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Official Email',
                                        controller: _oEmailController,
                                        enabled: _isEditing,
                                        prefixIcon: LucideIcons.briefcase,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                          _buildSectionTitle(context, 'Account Status'),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildInfoBadge(
                                    'Joined',
                                    employee.joinDate.toString().split(' ')[0],
                                    LucideIcons.calendar,
                                  ),
                                  _buildInfoBadge(
                                    'Role',
                                    employee.role.toUpperCase(),
                                    LucideIcons.shield,
                                  ),
                                  _buildInfoBadge(
                                    'Status',
                                    employee.isActive ? 'ACTIVE' : 'INACTIVE',
                                    LucideIcons.checkCircle,
                                  ),
                                ],
                              ),
                            ),
                          ),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
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
              vertical: 12,
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
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
