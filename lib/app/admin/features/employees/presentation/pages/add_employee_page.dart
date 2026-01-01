import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/providers/employee_providers.dart';

class AddEmployeePage extends ConsumerStatefulWidget {
  const AddEmployeePage({super.key});

  @override
  ConsumerState<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends ConsumerState<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _personalPhoneController = TextEditingController();
  final _officialPhoneController = TextEditingController();
  final _personalEmailController = TextEditingController();
  final _officialEmailController = TextEditingController();
  String? _selectedDepartment;

  @override
  void dispose() {
    _nameController.dispose();
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
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                  const SizedBox(width: 16),
                ],
              )
              .toList()
            ..removeLast(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Employee',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  InkWell(
                    onTap: () => context.go('/admin/employees'),
                    child: Text(
                      'Employees',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  Text(
                    'Add Employee',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildResponsiveRow(
                          isMobile: isMobile,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldTitle('Name'),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter full name',
                                  ),
                                  validator: (value) => value!.isEmpty
                                      ? 'Please enter a name'
                                      : null,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldTitle('Department'),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final departmentsAsync = ref.watch(
                                      departmentsProvider,
                                    );
                                    return departmentsAsync.when(
                                      data: (departments) {
                                        return ButtonTheme(
                                          alignedDropdown: true,
                                          child: DropdownButtonFormField<String>(
                                            hint: const Text(
                                              'Select Department',
                                            ),
                                            initialValue: _selectedDepartment,
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedDepartment = value;
                                              });
                                            },
                                            items: departments
                                                .map(
                                                  (String department) =>
                                                      DropdownMenuItem<String>(
                                                        value: department,
                                                        child: Text(
                                                          department
                                                              .toUpperCase(),
                                                        ),
                                                      ),
                                                )
                                                .toList(),
                                            validator: (value) => value == null
                                                ? 'Please select a department'
                                                : null,
                                          ),
                                        );
                                      },
                                      loading: () =>
                                          const CircularProgressIndicator(),
                                      error: (err, stack) => const Text(
                                        'Error loading departments',
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildResponsiveRow(
                          isMobile: isMobile,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldTitle('Personal Phone'),
                                TextFormField(
                                  controller: _personalPhoneController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. +123456789',
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldTitle('Official Phone'),
                                TextFormField(
                                  controller: _officialPhoneController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. +123456789',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildResponsiveRow(
                          isMobile: isMobile,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldTitle('Personal Email'),
                                TextFormField(
                                  controller: _personalEmailController,
                                  decoration: const InputDecoration(
                                    hintText: 'personal@example.com',
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldTitle('Official Email'),
                                TextFormField(
                                  controller: _officialEmailController,
                                  decoration: const InputDecoration(
                                    hintText: 'work@example.com',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => context.go('/admin/employees'),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  ref
                                      .read(employeeServiceProvider)
                                      .addEmployee(
                                        name: _nameController.text,
                                        personalPhone:
                                            _personalPhoneController.text,
                                        officialPhone:
                                            _officialPhoneController.text,
                                        personalEmail:
                                            _personalEmailController.text,
                                        officialEmail:
                                            _officialEmailController.text,
                                        department: _selectedDepartment ?? '',
                                        email: _officialEmailController.text,
                                        password: '',
                                      );
                                  context.go('/admin/employees');
                                }
                              },
                              child: const Text('Add Employee'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
