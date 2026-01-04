import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/employee.dart';
import '/core/providers/employee_providers.dart';

class EditEmployeePage extends ConsumerStatefulWidget {
  final String employeeId;
  const EditEmployeePage({super.key, required this.employeeId});

  @override
  ConsumerState<EditEmployeePage> createState() => _EditEmployeePageState();
}

class _EditEmployeePageState extends ConsumerState<EditEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nickNameController = TextEditingController();
  final _personalPhoneController = TextEditingController();
  final _officialPhoneController = TextEditingController();
  final _personalEmailController = TextEditingController();
  final _officialEmailController = TextEditingController();
  final _empIdFieldController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedDesignation;
  String _selectedGender = 'male';
  DateTime? _selectedDob;
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nickNameController.dispose();
    _personalPhoneController.dispose();
    _officialPhoneController.dispose();
    _personalEmailController.dispose();
    _officialEmailController.dispose();
    _empIdFieldController.dispose();
    super.dispose();
  }

  void _initializeData(Employee employee) {
    if (_isInitialized) return;
    _nameController.text = employee.name;
    _nickNameController.text = employee.nickName;
    _personalPhoneController.text = employee.personalPhone;
    _officialPhoneController.text = employee.officialPhone;
    _personalEmailController.text = employee.personalEmail;
    _officialEmailController.text = employee.officialEmail;
    _empIdFieldController.text = employee.employeeId;
    _selectedDepartment = employee.department;
    _selectedDesignation = employee.designation;
    _selectedGender = employee.gender;
    _selectedDob = employee.dateOfBirth;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    final employeeAsync = ref.watch(employeeByIdProvider(widget.employeeId));

    return Scaffold(
      body: employeeAsync.when(
        data: (employee) {
          if (employee == null) {
            return const Center(child: Text('Employee not found'));
          }
          _initializeData(employee);

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(employee),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildResponsiveRow(
                              isMobile: isMobile,
                              children: [
                                _buildFieldBlock(
                                  'Full Name',
                                  _nameController,
                                  isRequired: true,
                                ),
                                _buildFieldBlock(
                                  'Nick Name',
                                  _nickNameController,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Employee ID in its own row with duplication check logic
                            _buildFieldTitle('Employee ID (System)'),
                            TextFormField(
                              controller: _empIdFieldController,
                              readOnly: true, // As per requirements
                              style: TextStyle(color: Colors.grey),
                              decoration: _inputDecoration(hint: 'ID').copyWith(
                                fillColor: Colors.grey.shade100,
                                focusColor: Colors.white,
                                focusedBorder: InputBorder.none,
                              ),
                            ),

                            const SizedBox(height: 24),

                            _buildResponsiveRow(
                              isMobile: isMobile,
                              children: [
                                _buildDepartmentDropdown(),
                                _buildDesignationDropdown(),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildResponsiveRow(
                              isMobile: isMobile,
                              children: [
                                _buildFieldBlock(
                                  'Personal Phone',
                                  _personalPhoneController,
                                  icon: LucideIcons.phone,
                                ),
                                _buildFieldBlock(
                                  'Official Phone',
                                  _officialPhoneController,
                                  icon: LucideIcons.phoneCall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildResponsiveRow(
                              isMobile: isMobile,
                              children: [
                                _buildFieldBlock(
                                  'Personal Email',
                                  _personalEmailController,
                                  icon: LucideIcons.mail,
                                ),
                                _buildFieldBlock(
                                  'Official Email',
                                  _officialEmailController,
                                  icon: LucideIcons.briefcase,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            _buildResponsiveRow(
                              isMobile: isMobile,
                              children: [
                                _buildGenderDropdown(),
                                _buildDatePicker(),
                              ],
                            ),
                            const SizedBox(height: 48),
                            _buildFooterActions(employee),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(Employee employee) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => context.go('/admin/dashboard'),
              child: const Text('Admin', style: TextStyle(color: Colors.grey)),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            InkWell(
              onTap: () => context.go('/admin/employees'),
              child: const Text(
                'Employees',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            const Text('Edit Profile'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Edit: ${employee.name}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
      ],
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFieldBlock(
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldTitle(label),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(prefixIcon: icon),
          validator: isRequired
              ? (v) => v!.isEmpty ? 'Field required' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldTitle('Department'),
        Consumer(
          builder: (context, ref, _) {
            final deptsAsync = ref.watch(departmentsProvider);
            return deptsAsync.when(
              data: (items) {
                final uniqueItems = items.toSet().toList();
                if (_selectedDepartment != null &&
                    !uniqueItems.contains(_selectedDepartment)) {
                  _selectedDepartment = null;
                }
                return ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    items: uniqueItems
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedDepartment = v;
                      _selectedDesignation = null;
                    }),
                    decoration: _inputDecoration(),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading depts'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDesignationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldTitle('Designation'),
        Consumer(
          builder: (context, ref, _) {
            final desigsAsync = ref.watch(allDesignationsProvider);
            return desigsAsync.when(
              data: (items) {
                final filtered = items
                    .where((d) => d.department == _selectedDepartment)
                    .map((d) => d.name)
                    .toSet()
                    .toList();
                if (_selectedDesignation != null &&
                    !filtered.contains(_selectedDesignation)) {
                  _selectedDesignation = null;
                }
                return ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButtonFormField<String>(
                    value: _selectedDesignation,
                    items: filtered
                        .map(
                          (name) =>
                              DropdownMenuItem(value: name, child: Text(name)),
                        )
                        .toList(),
                    onChanged: _selectedDepartment == null
                        ? null
                        : (v) => setState(() => _selectedDesignation = v),
                    decoration: _inputDecoration(),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading desigs'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldTitle('Gender'),
        ButtonTheme(
          alignedDropdown: true,
          child: DropdownButtonFormField<String>(
            value: _selectedGender,
            items: const [
              DropdownMenuItem(value: 'male', child: Text('MALE')),
              DropdownMenuItem(value: 'female', child: Text('FEMALE')),
            ],
            onChanged: (v) => setState(() => _selectedGender = v!),
            decoration: _inputDecoration(),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldTitle('Date of Birth'),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  _selectedDob ??
                  DateTime.now().subtract(const Duration(days: 365 * 20)),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _selectedDob = picked);
          },
          child: InputDecorator(
            decoration: _inputDecoration(prefixIcon: LucideIcons.calendar),
            child: Text(
              _selectedDob == null
                  ? 'Select Date'
                  : DateFormat('MMM dd, yyyy').format(_selectedDob!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterActions(Employee employee) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => context.go('/admin/employees'),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSaving ? null : () => _handleUpdate(employee),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Update Profile'),
        ),
      ],
    );
  }

  Future<void> _handleUpdate(Employee current) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updated = Employee(
        id: current.id,
        employeeId: current.employeeId, // ID is preserved
        name: _nameController.text.trim(),
        nickName: _nickNameController.text.trim(),
        personalPhone: _personalPhoneController.text.trim(),
        officialPhone: _officialPhoneController.text.trim(),
        personalEmail: _personalEmailController.text.trim(),
        officialEmail: _officialEmailController.text.trim(),
        department: _selectedDepartment ?? '',
        designation: _selectedDesignation ?? '',
        gender: _selectedGender,
        dateOfBirth: _selectedDob,
        email: current.email,
        password: current.password,
        role: current.role,
        isActive: current.isActive,
        joinDate: current.joinDate,
        createdAt: current.createdAt,
        image: current.image,
      );
      await ref.read(employeeServiceProvider).updateEmployee(updated);
      if (mounted) {
        context.go('/admin/employees');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  InputDecoration _inputDecoration({IconData? prefixIcon, String? hint}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade100),
      ),
    );
  }

  Widget _buildResponsiveRow({
    required bool isMobile,
    required List<Widget> children,
  }) {
    if (isMobile)
      return Column(
        children:
            children.expand((w) => [w, const SizedBox(height: 20)]).toList()
              ..removeLast(),
      );
    return Row(
      children:
          children
              .expand((w) => [Expanded(child: w), const SizedBox(width: 24)])
              .toList()
            ..removeLast(),
    );
  }
}
