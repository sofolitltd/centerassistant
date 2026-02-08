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

  // Controllers
  final _nameController = TextEditingController();
  final _nickNameController = TextEditingController();
  final _personalPhoneController = TextEditingController();
  final _officialPhoneController = TextEditingController();
  final _personalEmailController = TextEditingController();
  final _officialEmailController = TextEditingController();
  final _empIdFieldController = TextEditingController();
  final _nidController = TextEditingController();
  final _tinController = TextEditingController();
  final _presentAddressController = TextEditingController();
  final _permanentAddressController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedDesignation;
  String _selectedGender = 'male';
  DateTime? _selectedDob;
  DateTime _joinedDate = DateTime.now();
  DateTime? _separationDate;
  bool _isActive = true;
  List<Education> _educationList = [];
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
    _nidController.dispose();
    _tinController.dispose();
    _presentAddressController.dispose();
    _permanentAddressController.dispose();
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
    _nidController.text = employee.nid;
    _tinController.text = employee.tin;
    _presentAddressController.text = employee.presentAddress;
    _permanentAddressController.text = employee.permanentAddress;
    _selectedDepartment = employee.department;
    _selectedDesignation = employee.designation;
    _selectedGender = employee.gender;
    _selectedDob = employee.dateOfBirth;
    _joinedDate = employee.joinedDate;
    _separationDate = employee.separationDate;
    _isActive = employee.isActive;
    _educationList = List.from(employee.education);
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    final employeeAsync = ref.watch(employeeByIdProvider(widget.employeeId));

    return Scaffold(
      body: employeeAsync.when(
        data: (employee) {
          if (employee == null) return const Center(child: Text('Not found'));
          _initializeData(employee);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(employee),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: isMobile
                          ? Column(
                              children: [
                                _buildBasicInfo(isMobile),
                                const SizedBox(height: 24),
                                _buildEmploymentInfo(isMobile, employee),
                                const SizedBox(height: 24),
                                _buildContactInfo(isMobile),
                                const SizedBox(height: 24),
                                _buildEducationSection(),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildBasicInfo(isMobile),
                                      const SizedBox(height: 24),
                                      _buildEmploymentInfo(isMobile, employee),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildContactInfo(isMobile),
                                      const SizedBox(height: 24),
                                      _buildEducationSection(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 48),
                    _buildFooterActions(employee),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBasicInfo(bool isMobile) {
    return _buildSectionCard('1. Basic Information', [
      _buildResponsiveRow(
        isMobile: isMobile,
        children: [
          _buildFieldBlock('Full Name', _nameController, isRequired: true),
          _buildFieldBlock('Nick Name', _nickNameController),
        ],
      ),
      const SizedBox(height: 20),
      _buildResponsiveRow(
        isMobile: isMobile,
        children: [
          _buildGenderDropdown(),
          _buildDatePicker(
            'Date of Birth',
            _selectedDob,
            (d) => setState(() => _selectedDob = d),
          ),
        ],
      ),
      const SizedBox(height: 20),
      _buildResponsiveRow(
        isMobile: isMobile,
        children: [
          _buildFieldBlock(
            'NID Number',
            _nidController,
            icon: LucideIcons.creditCard,
          ),
          _buildFieldBlock(
            'TIN Number',
            _tinController,
            icon: LucideIcons.fileText,
          ),
        ],
      ),
    ]);
  }

  Widget _buildEmploymentInfo(bool isMobile, Employee employee) {
    return _buildSectionCard('3. Professional & Employment', [
      _buildFieldTitle('Employee ID (System)'),
      TextFormField(
        controller: _empIdFieldController,
        decoration: _inputDecoration(prefixIcon: LucideIcons.hash),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
      const SizedBox(height: 20),
      _buildResponsiveRow(
        isMobile: isMobile,
        children: [_buildDepartmentDropdown(), _buildDesignationDropdown()],
      ),
      const SizedBox(height: 20),
      _buildResponsiveRow(
        isMobile: isMobile,
        children: [
          _buildDatePicker(
            'Joined Date',
            _joinedDate,
            (d) => setState(() => _joinedDate = d ?? DateTime.now()),
          ),
          _buildDatePicker(
            'Separation Date',
            _separationDate,
            (d) => setState(() => _separationDate = d),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Registration Date:',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Text(
            DateFormat('dd MMM, yyyy').format(employee.createdAt),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Switch(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeColor: Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            _isActive ? 'Active Account' : 'Inactive Account',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isActive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildContactInfo(bool isMobile) {
    return _buildSectionCard('2. Contact Information', [
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
      const SizedBox(height: 20),
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
      const SizedBox(height: 20),
      _buildFieldTitle('Present Address'),
      TextFormField(
        controller: _presentAddressController,
        maxLines: 2,
        decoration: _inputDecoration(prefixIcon: LucideIcons.mapPin),
      ),
      const SizedBox(height: 20),
      _buildFieldTitle('Permanent Address'),
      TextFormField(
        controller: _permanentAddressController,
        maxLines: 2,
        decoration: _inputDecoration(prefixIcon: LucideIcons.home),
      ),
    ]);
  }

  Widget _buildEducationSection() {
    return _buildSectionCard('4. Education', [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Qualifications',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          ElevatedButton.icon(
            onPressed: _showAddEducationDialog,
            icon: const Icon(LucideIcons.plus, size: 14),
            label: const Text('Add Edu'),
          ),
        ],
      ),
      if (_educationList.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'No academic records',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        )
      else
        ..._educationList.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ListTile(
              contentPadding: EdgeInsets.only(left: 16, right: 8, bottom: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              tileColor: Colors.grey.shade50,
              dense: true,
              title: Text('${e.value.degree} | ${e.value.passingYear}'),
              subtitle: Text(e.value.institute),
              trailing: IconButton(
                icon: const Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: Colors.red,
                ),
                onPressed: () => setState(() => _educationList.removeAt(e.key)),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blueAccent,
              ),
            ),
            const Divider(height: 32),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Employee emp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => context.go('/admin/dashboard'),
              child: const Text(
                'Admin',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            InkWell(
              onTap: () => context.go('/admin/employees'),
              child: const Text(
                'Employees',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Edit: ${emp.name}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
          validator: isRequired ? (v) => v!.isEmpty ? 'Required' : null : null,
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
              error: (_, __) => const Text('Error'),
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
              error: (_, __) => const Text('Error'),
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
            initialValue: _selectedGender,
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Male')),
              DropdownMenuItem(value: 'female', child: Text('Female')),
            ],
            onChanged: (v) => setState(() => _selectedGender = v!),
            decoration: _inputDecoration(),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? value,
    Function(DateTime?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldTitle(label),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) onChanged(picked);
          },
          child: InputDecorator(
            decoration: _inputDecoration(prefixIcon: LucideIcons.calendar),
            child: Text(
              value == null
                  ? 'Select Date'
                  : DateFormat('MMM dd, yyyy').format(value),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddEducationDialog() {
    final instController = TextEditingController();
    final degController = TextEditingController();
    final yearController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 350),
          child: Row(
            children: [
              const Text('Add Education'),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: degController,
              decoration: const InputDecoration(
                labelText: 'Degree',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: instController,
              decoration: const InputDecoration(
                labelText: 'Institute',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: yearController,
              decoration: const InputDecoration(
                labelText: 'Passing Year',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (degController.text.isNotEmpty &&
                  instController.text.isNotEmpty) {
                setState(() {
                  _educationList.add(
                    Education(
                      institute: instController.text.trim(),
                      degree: degController.text.trim(),
                      passingYear: yearController.text.trim(),
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(Employee current) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => context.go('/admin/employees'),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSaving ? null : () => _handleUpdate(current),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
    final newEmpId = _empIdFieldController.text.trim();
    setState(() => _isSaving = true);
    try {
      if (newEmpId != current.employeeId) {
        final allEmployees = await ref.read(employeesProvider.future);
        if (allEmployees.any((e) => e.employeeId == newEmpId)) {
          if (mounted) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: Employee ID exists.')),
            );
          }
          return;
        }
      }
      final updated = current.copyWith(
        employeeId: newEmpId,
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
        nid: _nidController.text.trim(),
        tin: _tinController.text.trim(),
        presentAddress: _presentAddressController.text.trim(),
        permanentAddress: _permanentAddressController.text.trim(),
        education: _educationList,
        joinedDate: _joinedDate,
        separationDate: _separationDate,
        isActive: _isActive,
      );
      await ref.read(employeeServiceProvider).updateEmployee(updated);
      if (mounted) {
        context.go('/admin/employees');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            children.expand((w) => [w, const SizedBox(height: 20)]).toList()
              ..removeLast(),
      );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          children
              .expand((w) => [Expanded(child: w), const SizedBox(width: 24)])
              .toList()
            ..removeLast(),
    );
  }
}
