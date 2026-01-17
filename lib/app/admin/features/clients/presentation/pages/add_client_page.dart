import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/providers/client_providers.dart';

class AddClientPage extends ConsumerStatefulWidget {
  const AddClientPage({super.key});

  @override
  ConsumerState<AddClientPage> createState() => _AddClientPageState();
}

class _AddClientPageState extends ConsumerState<AddClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nickNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedGender = 'Male';
  DateTime? _selectedDob;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nickNameController.dispose();
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
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
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
      backgroundColor: Colors.black12.withOpacity(0.03),
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
                                hint: 'e.g. John Smith',
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
                              _buildGenderDropdown(),
                              _buildDatePicker(),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildResponsiveRow(
                            isMobile: isMobile,
                            children: [
                              _buildFieldBlock(
                                'Mobile Number',
                                _mobileController,
                                hint: '01XXXXXXXXX',
                                icon: LucideIcons.phone,
                                isRequired: true,
                              ),
                              _buildFieldBlock(
                                'Email Address',
                                _emailController,
                                hint: 'client@example.com',
                                icon: LucideIcons.mail,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildFieldBlock(
                            'Full Address',
                            _addressController,
                            hint: 'Enter current address',
                            icon: LucideIcons.mapPin,
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
          'Register New Client',
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
              onTap: () => context.go('/admin/clients'),
              child: const Text(
                'Clients',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            const Text('New Registration'),
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

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldTitle('Gender'),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          items: const [
            DropdownMenuItem(value: 'Male', child: Text('MALE')),
            DropdownMenuItem(value: 'Female', child: Text('FEMALE')),
          ],
          onChanged: (v) => setState(() => _selectedGender = v!),
          decoration: _inputDecoration(),
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
                const Duration(days: 365 * 10),
              ),
              firstDate: DateTime(1900),
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
          onPressed: () => context.go('/admin/clients'),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Add Client',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate() && _selectedDob != null) {
      setState(() => _isSaving = true);
      try {
        await ref
            .read(clientServiceProvider)
            .addClient(
              name: _nameController.text.trim(),
              nickName: _nickNameController.text.trim(),
              mobileNo: _mobileController.text.trim(),
              email: _emailController.text.trim(),
              address: _addressController.text.trim(),
              gender: _selectedGender,
              dateOfBirth: _selectedDob!,
            );
        if (mounted) context.go('/admin/clients');
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    } else if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Date of Birth')),
      );
    }
  }

  Widget _buildResponsiveRow({
    required bool isMobile,
    required List<Widget> children,
  }) {
    if (isMobile) {
      return Column(
        children:
            children.expand((w) => [w, const SizedBox(height: 20)]).toList()
              ..removeLast(),
      );
    }
    return Row(
      children:
          children
              .expand((w) => [Expanded(child: w), const SizedBox(width: 24)])
              .toList()
            ..removeLast(),
    );
  }
}
