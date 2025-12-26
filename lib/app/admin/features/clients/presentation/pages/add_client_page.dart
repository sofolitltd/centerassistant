import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/core/providers/client_providers.dart';

class AddClientPage extends ConsumerStatefulWidget {
  const AddClientPage({super.key});

  @override
  ConsumerState<AddClientPage> createState() => _AddClientPageState();
}

class _AddClientPageState extends ConsumerState<AddClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  String _gender = 'Male';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                onTap: () => context.go('/admin/clients'),
                child: Text(
                  'Clients',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              Text('Add Client', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add New Client',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Card(
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
                              validator: (value) =>
                                  value!.isEmpty ? 'Please enter a name' : null,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldTitle('Gender'),
                            ButtonTheme(
                              alignedDropdown: true,
                              child: DropdownButtonFormField<String>(
                                initialValue: _gender,
                                decoration: const InputDecoration(
                                  hintText: 'Select Gender',
                                ),
                                items: ['Male', 'Female']
                                    .map(
                                      (label) => DropdownMenuItem(
                                        value: label,
                                        child: Text(label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _gender = value);
                                  }
                                },
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
                            _buildFieldTitle('Mobile No'),
                            TextFormField(
                              controller: _mobileController,
                              decoration: const InputDecoration(
                                hintText: 'e.g. +123456789',
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldTitle('Email'),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                hintText: 'client@example.com',
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
                            _buildFieldTitle('Date of Birth'),
                            InkWell(
                              onTap: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (pickedDate != null) {
                                  setState(() => _selectedDate = pickedDate);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  hintText: 'Select DOB',
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedDate == null
                                          ? 'Select Date'
                                          : DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(_selectedDate!),
                                    ),
                                    const Icon(Icons.calendar_today, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldTitle('Address'),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                hintText: 'Enter address',
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
                          onPressed: () => context.go('/admin/clients'),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate() &&
                                _selectedDate != null) {
                              ref
                                  .read(clientServiceProvider)
                                  .addClient(
                                    name: _nameController.text,
                                    mobileNo: _mobileController.text,
                                    email: _emailController.text,
                                    address: _addressController.text,
                                    gender: _gender,
                                    dateOfBirth: _selectedDate!,
                                  );
                              context.go('/admin/clients');
                            } else if (_selectedDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select a date of birth',
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text('Add Client'),
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
    );
  }
}
