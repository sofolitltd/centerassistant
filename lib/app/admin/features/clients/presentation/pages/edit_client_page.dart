import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/client.dart';
import '/core/providers/client_providers.dart';

class EditClientPage extends ConsumerStatefulWidget {
  final String clientId;
  const EditClientPage({super.key, required this.clientId});

  @override
  ConsumerState<EditClientPage> createState() => _EditClientPageState();
}

class _EditClientPageState extends ConsumerState<EditClientPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _nickNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _clientIdController = TextEditingController();

  final _fatherNameController = TextEditingController();
  final _fatherContactController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherContactController = TextEditingController();

  String _selectedGender = 'Male';
  DateTime? _selectedDob;
  DateTime _enrollmentDate = DateTime.now();
  DateTime? _discontinueDate;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nickNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _clientIdController.dispose();
    _fatherNameController.dispose();
    _fatherContactController.dispose();
    _motherNameController.dispose();
    _motherContactController.dispose();
    super.dispose();
  }

  void _initializeFields(Client client) {
    if (_isInitialized) return;
    _nameController.text = client.name;
    _nickNameController.text = client.nickName;
    _mobileController.text = client.mobileNo;
    _emailController.text = client.email;
    _addressController.text = client.address;
    _clientIdController.text = client.clientId;
    _fatherNameController.text = client.fatherName;
    _fatherContactController.text = client.fatherContact;
    _motherNameController.text = client.motherName;
    _motherContactController.text = client.motherContact;
    _selectedGender = client.gender;
    _selectedDob = client.dateOfBirth;
    _enrollmentDate = client.enrollmentDate;
    _discontinueDate = client.discontinueDate;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(clientByIdProvider(widget.clientId));

    return clientAsync.when(
      data: (client) {
        if (client == null) {
          return const Scaffold(body: Center(child: Text('Client not found')));
        }
        _initializeFields(client);

        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 900;

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: isMobile
                          ? Column(
                              children: [
                                _buildBasicInfo(isMobile),
                                const SizedBox(height: 24),
                                _buildParentInfo(isMobile),
                                const SizedBox(height: 24),
                                _buildContactInfo(isMobile),
                                const SizedBox(height: 24),
                                _buildEnrollmentInfo(isMobile),
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
                                      _buildParentInfo(isMobile),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildContactInfo(isMobile),
                                      const SizedBox(height: 24),
                                      _buildEnrollmentInfo(isMobile),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 48),
                    _buildFooterActions(client),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildBasicInfo(bool isMobile) {
    return _buildSectionCard('1. Basic Information', [
      _buildFieldTitle('Client ID (System)'),
      TextFormField(
        controller: _clientIdController,
        decoration: _inputDecoration(prefixIcon: LucideIcons.hash),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
      const SizedBox(height: 20),
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
            isRequired: true,
          ),
        ],
      ),
    ]);
  }

  Widget _buildParentInfo(bool isMobile) {
    return _buildSectionCard('2. Parent Information', [
      _buildResponsiveRow(
        isMobile: isMobile,
        children: [
          _buildFieldBlock(
            'Father Name',
            _fatherNameController,
            icon: LucideIcons.user,
          ),
          _buildFieldBlock(
            'Father Contact',
            _fatherContactController,
            icon: LucideIcons.phone,
          ),
        ],
      ),
      const SizedBox(height: 20),
      _buildResponsiveRow(
        isMobile: isMobile,
        children: [
          _buildFieldBlock(
            'Mother Name',
            _motherNameController,
            icon: LucideIcons.user,
          ),
          _buildFieldBlock(
            'Mother Contact',
            _motherContactController,
            icon: LucideIcons.phone,
          ),
        ],
      ),
    ]);
  }

  Widget _buildContactInfo(bool isMobile) {
    return _buildSectionCard('3. Contact & Address', [
      _buildResponsiveRow(
        isMobile: isMobile,
        children: [
          _buildFieldBlock(
            'Mobile Number',
            _mobileController,
            icon: LucideIcons.phone,
            isRequired: true,
          ),
          _buildFieldBlock(
            'Email Address',
            _emailController,
            icon: LucideIcons.mail,
          ),
        ],
      ),
      const SizedBox(height: 20),
      _buildFieldTitle('Full Address'),
      TextFormField(
        controller: _addressController,
        maxLines: 2,
        decoration: _inputDecoration(prefixIcon: LucideIcons.mapPin),
      ),
    ]);
  }

  Widget _buildEnrollmentInfo(bool isMobile) {
    return _buildSectionCard('4. Enrollment Status', [
      _buildResponsiveRow(
        isMobile: isMobile,
        children: [
          _buildDatePicker(
            'Enrollment Date',
            _enrollmentDate,
            (d) => setState(() => _enrollmentDate = d ?? DateTime.now()),
          ),
          _buildDatePicker(
            'Discontinue Date',
            _discontinueDate,
            (d) => setState(() => _discontinueDate = d),
          ),
        ],
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

  Widget _buildHeader() {
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
              onTap: () => context.go('/admin/clients'),
              child: const Text(
                'Clients',
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
        const Text(
          'Edit Client',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
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
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
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
    Function(DateTime?) onChanged, {
    bool isRequired = false,
  }) {
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
              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
            );
            if (picked != null) onChanged(picked);
          },
          child: InputDecorator(
            decoration: _inputDecoration(prefixIcon: LucideIcons.calendar),
            child: Text(
              value == null
                  ? 'Select Date'
                  : DateFormat('MMM dd, yyyy').format(value),
              style: TextStyle(
                color: value == null ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterActions(Client client) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSaving ? null : () => _handleSubmit(client),

          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Update Client'),
        ),
      ],
    );
  }

  void _handleSubmit(Client client) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Date of Birth')),
        );
        return;
      }

      setState(() => _isSaving = true);
      try {
        final updatedClient = client.copyWith(
          name: _nameController.text.trim(),
          nickName: _nickNameController.text.trim(),
          mobileNo: _mobileController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          gender: _selectedGender,
          dateOfBirth: _selectedDob!,
          fatherName: _fatherNameController.text.trim(),
          fatherContact: _fatherContactController.text.trim(),
          motherName: _motherNameController.text.trim(),
          motherContact: _motherContactController.text.trim(),
          enrollmentDate: _enrollmentDate,
          discontinueDate: _discontinueDate,
        );

        await ref.read(clientServiceProvider).updateClient(updatedClient);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
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
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            children.expand((w) => [w, const SizedBox(height: 20)]).toList()
              ..removeLast(),
      );
    }
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
