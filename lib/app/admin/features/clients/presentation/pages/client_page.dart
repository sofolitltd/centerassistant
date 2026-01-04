import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '/core/models/client.dart';
import '/core/providers/client_providers.dart';

class ClientPage extends ConsumerWidget {
  const ClientPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);
    final double width = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (width > 1100) {
      crossAxisCount = 4;
    } else if (width > 900) {
      crossAxisCount = 3;
    } else if (width > 600) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    final bool isMobile = width < 600;

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () => context.go('/admin/dashboard'),
                              child: Text(
                                'Admin',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Colors.grey,
                            ),
                            Text(
                              'Clients',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Clients',
                          style: Theme.of(context).textTheme.headlineMedium!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    ElevatedButton.icon(
                      onPressed: () => context.go('/admin/clients/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Client'),
                    ),
                ],
              ),
              if (isMobile) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.go('/admin/clients/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Client'),
                ),
              ],
              const SizedBox(height: 24),
              clientsAsync.when(
                data: (clients) {
                  if (clients.isEmpty) {
                    return const Center(
                      child: Text('No clients found. Add one!'),
                    );
                  }
                  return MasonryGridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundImage: NetworkImage(client.image),
                                    child: client.image.isEmpty
                                        ? const Icon(Icons.person, size: 30)
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    client.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    client.email,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey.shade600),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () =>
                                        _showClientInfoDialog(context, client),
                                    child: const Text('View Details'),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            context.go(
                                              '/admin/clients/${client.id}/schedule',
                                            );
                                          },
                                          child: const Text(
                                            'Schedule',
                                            style: TextStyle(fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            context.go(
                                              '/admin/clients/${client.id}/availability?name=${Uri.encodeComponent(client.name)}',
                                            );
                                          },

                                          child: const Text(
                                            'Availability',
                                            style: TextStyle(fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: PopupMenuButton<String>(
                                color: Colors.white,
                                icon: const Icon(Icons.more_vert, size: 20),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditClientDialog(context, ref, client);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmDialog(
                                      context,
                                      ref,
                                      client,
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit, size: 18),
                                      title: Text('Edit'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      title: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClientInfoDialog(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        content: Container(
          constraints: const BoxConstraints(minWidth: 400, maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Client Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      child: const Icon(Icons.close, size: 16),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(client.image),
                      child: client.image.isEmpty
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Text(
                                'ID: ${client.clientId.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  '|',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              ),
                              Text(
                                client.gender.toUpperCase(),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                      letterSpacing: 1.2,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'DOB: ${DateFormat('dd MMM, yyyy').format(client.dateOfBirth)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                ' (${_getFormattedAge(client.dateOfBirth)} Years)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildInfoSection(context, 'Contact Information', [
                  _buildInfoRow(
                    context,
                    Icons.phone_iphone,
                    'Mobile No',
                    client.mobileNo,
                    actions: [
                      _ActionButton(
                        icon: LucideIcons.copy,
                        onTap: () => _copyToClipboard(context, client.mobileNo),
                      ),
                      _ActionButton(
                        icon: LucideIcons.phone,
                        onTap: () => _launchURL('tel:${client.mobileNo}'),
                      ),
                      _ActionButton(
                        icon: LucideIcons.share2,
                        onTap: () => SharePlus.instance.share(
                          ShareParams(text: client.mobileNo),
                        ),
                      ),
                    ],
                  ),
                  _buildInfoRow(
                    context,
                    Icons.email_outlined,
                    'Email Address',
                    client.email,
                    actions: [
                      _ActionButton(
                        icon: LucideIcons.copy,
                        onTap: () => _copyToClipboard(context, client.email),
                      ),
                      _ActionButton(
                        icon: LucideIcons.mail,
                        onTap: () => _launchURL('mailto:${client.email}'),
                      ),
                      _ActionButton(
                        icon: LucideIcons.share2,
                        onTap: () => SharePlus.instance.share(
                          ShareParams(text: client.email),
                        ),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 24),
                _buildInfoSection(context, 'Personal Details', [
                  _buildInfoRow(
                    context,
                    Icons.location_on_outlined,
                    'Address',
                    client.address,
                    actions: [
                      _ActionButton(
                        icon: LucideIcons.copy,
                        onTap: () => _copyToClipboard(context, client.address),
                      ),
                      _ActionButton(
                        icon: LucideIcons.share2,
                        onTap: () => SharePlus.instance.share(
                          ShareParams(text: client.address),
                        ),
                      ),
                    ],
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFormattedAge(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    int years = currentDate.year - birthDate.year;
    int months = currentDate.month - birthDate.month;
    if (months < 0 || (months == 0 && currentDate.day < birthDate.day)) {
      years--;
      months += 12;
    }
    if (currentDate.day < birthDate.day) {
      months--;
      if (months < 0) {
        months = 11;
      }
    }
    return '$years.$months';
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: $text'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const Divider(height: 24),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    List<Widget>? actions,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (actions != null && value.isNotEmpty) ...[
            const SizedBox(width: 8),
            Row(mainAxisSize: MainAxisSize.min, children: actions),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Client client,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete ${client.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(clientServiceProvider).deleteClient(client.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

  void _showEditClientDialog(
    BuildContext context,
    WidgetRef ref,
    Client client,
  ) {
    final nameController = TextEditingController(text: client.name);
    final mobileController = TextEditingController(text: client.mobileNo);
    final emailController = TextEditingController(text: client.email);
    final addressController = TextEditingController(text: client.address);
    DateTime selectedDate = client.dateOfBirth;
    String selectedGender = client.gender;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          insetPadding: EdgeInsets.zero,
          title: Container(
            constraints: const BoxConstraints(minWidth: 350),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Client'),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldTitle('Name'),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter full name',
                  ),
                ),
                const SizedBox(height: 16),
                _buildFieldTitle('Mobile'),
                TextField(
                  controller: mobileController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. +123456789',
                  ),
                ),
                const SizedBox(height: 16),
                _buildFieldTitle('Email'),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: 'client@example.com',
                  ),
                ),
                const SizedBox(height: 16),
                _buildFieldTitle('Address'),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(hintText: 'Enter address'),
                ),
                const SizedBox(height: 16),
                _buildFieldTitle('Gender'),
                ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedGender,
                    items: ['Male', 'Female']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedGender = val!),
                    decoration: const InputDecoration(),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFieldTitle('Date of Birth'),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedClient = Client(
                  id: client.id,
                  clientId: client.clientId,
                  name: nameController.text,
                  mobileNo: mobileController.text,
                  email: emailController.text,
                  address: addressController.text,
                  gender: selectedGender,
                  dateOfBirth: selectedDate,
                  createdAt: client.createdAt,
                  image: client.image,
                );
                ref.read(clientServiceProvider).updateClient(updatedClient);
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: Colors.blue.shade700),
        ),
      ),
    );
  }
}
