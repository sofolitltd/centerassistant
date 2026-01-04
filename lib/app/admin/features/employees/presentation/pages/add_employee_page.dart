import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/providers/employee_providers.dart';

class AddEmployeePage extends ConsumerStatefulWidget {
  const AddEmployeePage({super.key});

  @override
  ConsumerState<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends ConsumerState<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nickNameController = TextEditingController();
  final _personalPhoneController = TextEditingController();
  final _officialPhoneController = TextEditingController();
  final _personalEmailController = TextEditingController();
  final _officialEmailController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedDesignation;
  String _selectedGender = 'male';
  DateTime? _selectedDob;

  @override
  void dispose() {
    _nameController.dispose();
    _nickNameController.dispose();
    _personalPhoneController.dispose();
    _officialPhoneController.dispose();
    _personalEmailController.dispose();
    _officialEmailController.dispose();
    super.dispose();
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

  Widget _buildResponsiveRow({
    required bool isMobile,
    required List<Widget> children,
  }) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            children
                .expand((widget) => [widget, const SizedBox(height: 20)])
                .toList()
              ..removeLast(),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          children
              .expand(
                (widget) => [
                  Expanded(child: widget),
                  const SizedBox(width: 24),
                ],
              )
              .toList()
            ..removeLast(),
    );
  }

  InputDecoration _inputDecoration({String? hint, IconData? prefixIcon}) {
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    return Scaffold(
      backgroundColor: Colors.black12.withValues(alpha: 0.03),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
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
                                hint: 'e.g. John Doe',
                                isRequired: true,
                              ),
                              _buildFieldBlock(
                                'Nick Name',
                                _nickNameController,
                                hint: 'e.g. Johnny',
                              ),
                            ],
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
                                hint: '01XXXXXXXXX',
                                icon: LucideIcons.phone,
                              ),
                              _buildFieldBlock(
                                'Official Phone',
                                _officialPhoneController,
                                hint: '01XXXXXXXXX',
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
                                hint: 'john@example.com',
                                icon: LucideIcons.mail,
                              ),
                              _buildFieldBlock(
                                'Official Email',
                                _officialEmailController,
                                hint: 'john.doe@center.com',
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
                          _buildFooterActions(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add New Employee',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        const SizedBox(height: 8),
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
            const Text('Create Profile'),
          ],
        ),
      ],
    );
  }

  Widget _buildFieldBlock(
    String label,
    TextEditingController controller, {
    String? hint,
    IconData? icon,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldTitle(label),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(hint: hint, prefixIcon: icon),
          validator: isRequired
              ? (v) => v!.isEmpty ? 'This field is required' : null
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
                // Fix: Ensure the value exists in items to avoid Assertion failure
                final uniqueItems = items.toSet().toList();
                if (_selectedDepartment != null && !uniqueItems.contains(_selectedDepartment)) {
                  _selectedDepartment = null;
                }
                
                return ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    hint: const Text('Select Dept'),
                    items: uniqueItems
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedDepartment = v;
                        _selectedDesignation = null;
                      });
                    },
                    decoration: _inputDecoration(),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading departments'),
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
            final designationsAsync = ref.watch(allDesignationsProvider);
            return designationsAsync.when(
              data: (items) {
                final filtered = items
                    .where((d) => d.department == _selectedDepartment)
                    .map((d) => d.name)
                    .toSet()
                    .toList();
                
                // Fix: Ensure selected value exists in filtered list
                if (_selectedDesignation != null && !filtered.contains(_selectedDesignation)) {
                  _selectedDesignation = null;
                }

                return ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButtonFormField<String>(
                    value: _selectedDesignation,
                    hint: Text(
                      _selectedDepartment == null
                          ? 'Select Dept First'
                          : 'Select Desig',
                    ),
                    items: filtered
                        .map(
                          (name) => DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          ),
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
              error: (_, __) => const Text('Error loading designations'),
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
              initialDate: DateTime.now().subtract(
                const Duration(days: 365 * 20),
              ),
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
              style: TextStyle(
                color: _selectedDob == null ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => context.go('/admin/employees'),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'Create Employee Account',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      ref.read(employeeServiceProvider).addEmployee(
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
            email: _officialEmailController.text.trim(),
            password: '',
          );
      context.go('/admin/employees');
    }
  }
}
