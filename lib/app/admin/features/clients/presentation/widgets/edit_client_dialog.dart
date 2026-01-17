import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/client.dart';
import '/core/providers/client_providers.dart';

class EditClientDialog extends ConsumerStatefulWidget {
  final Client client;

  const EditClientDialog({super.key, required this.client});

  @override
  ConsumerState<EditClientDialog> createState() => _EditClientDialogState();
}

class _EditClientDialogState extends ConsumerState<EditClientDialog> {
  late TextEditingController nameController;
  late TextEditingController nickNameController;
  late TextEditingController mobileController;
  late TextEditingController emailController;
  late String selectedGender;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.client.name);
    nickNameController = TextEditingController(text: widget.client.nickName);
    mobileController = TextEditingController(text: widget.client.mobileNo);
    emailController = TextEditingController(text: widget.client.email);
    selectedGender = widget.client.gender;
  }

  @override
  void dispose() {
    nameController.dispose();
    nickNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400, maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Client',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Full Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: .symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nick Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nickNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: .symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mobile No',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: .symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Email Address',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: .symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gender',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedGender,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: .symmetric(horizontal: 12, vertical: 12),
                ),
                items: ['Male', 'Female']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => selectedGender = val!),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final updatedClient = widget.client.copyWith(
                        name: nameController.text,
                        nickName: nickNameController.text,
                        mobileNo: mobileController.text,
                        email: emailController.text,
                        gender: selectedGender,
                      );
                      await ref
                          .read(clientServiceProvider)
                          .updateClient(updatedClient);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Update Client'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
