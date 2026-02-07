import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/client.dart';

class ClientInformationPage extends StatelessWidget {
  final Client client;
  const ClientInformationPage({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Column(
          children: [
            if (isMobile)
              Column(
                children: [
                  _buildPersonalCard(),
                  const SizedBox(height: 16),
                  _buildContactCard(),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildPersonalCard()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildContactCard()),
                ],
              ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildPersonalCard() {
    return _buildInfoCard('Personal Information', [
      Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: client.image.isNotEmpty
                ? NetworkImage(client.image)
                : null,
            child: client.image.isEmpty
                ? const Icon(LucideIcons.user, size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Id: ${client.clientId.toUpperCase()}',
                  style: const TextStyle(color: Colors.grey, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      _buildInfoRow('Full Name', client.name),
      _buildInfoRow('Nick Name', client.nickName),
      _buildInfoRow('Gender', client.gender),
      _buildInfoRow('Age', '${client.age} years'),
      _buildInfoRow(
        'Date of Birth',
        DateFormat('dd MMM, yyyy').format(client.dateOfBirth),
      ),
      _buildInfoRow(
        'Registration Date',
        DateFormat('dd MMM, yyyy').format(client.createdAt),
      ),
    ]);
  }

  Widget _buildContactCard() {
    return _buildInfoCard('Contact Information', [
      _buildInfoRow('Mobile Number', client.mobileNo),
      _buildInfoRow('Email Address', client.email),
      _buildInfoRow('Home Address', client.address),
    ]);
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
