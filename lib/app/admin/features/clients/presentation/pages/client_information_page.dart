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
        final isMobile = constraints.maxWidth < 900;

        return SingleChildScrollView(
          child: Column(
            children: [
              if (isMobile)
                Column(
                  children: [
                    _buildPersonalCard(),
                    const SizedBox(height: 24),
                    _buildParentCard(),
                    const SizedBox(height: 24),
                    _buildContactCard(),
                    const SizedBox(height: 24),
                    _buildEnrollmentCard(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildPersonalCard(),
                          const SizedBox(height: 24),
                          _buildParentCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildContactCard(),
                          const SizedBox(height: 24),
                          _buildEnrollmentCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalCard() {
    return _buildInfoCard('1. Personal Information', [
      Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.blue.shade50,
            backgroundImage: client.image.isNotEmpty
                ? NetworkImage(client.image)
                : null,
            child: client.image.isEmpty
                ? const Icon(LucideIcons.user, size: 32, color: Colors.blue)
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
                  'ID: ${client.clientId.toUpperCase()}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
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
    ]);
  }

  Widget _buildParentCard() {
    return _buildInfoCard('2. Parent Information', [
      _buildInfoRow('Father Name', client.fatherName, icon: LucideIcons.user),
      _buildInfoRow(
        'Father Contact',
        client.fatherContact,
        icon: LucideIcons.phone,
      ),
      const Divider(height: 32),
      _buildInfoRow('Mother Name', client.motherName, icon: LucideIcons.user),
      _buildInfoRow(
        'Mother Contact',
        client.motherContact,
        icon: LucideIcons.phone,
      ),
    ]);
  }

  Widget _buildContactCard() {
    return _buildInfoCard('3. Contact & Address', [
      _buildInfoRow('Mobile Number', client.mobileNo, icon: LucideIcons.phone),
      _buildInfoRow('Email Address', client.email, icon: LucideIcons.mail),
      _buildInfoRow('Home Address', client.address, icon: LucideIcons.mapPin),
    ]);
  }

  Widget _buildEnrollmentCard() {
    return _buildInfoCard('4. Enrollment Status', [
      _buildInfoRow(
        'Enrollment Date',
        DateFormat('dd MMM, yyyy').format(client.enrollmentDate),
        icon: LucideIcons.calendar,
      ),
      _buildInfoRow(
        'Discontinue Date',
        client.discontinueDate != null
            ? DateFormat('dd MMM, yyyy').format(client.discontinueDate!)
            : 'Active',
        icon: LucideIcons.calendarX,
        valueColor: client.discontinueDate != null ? Colors.red : Colors.green,
      ),
      _buildInfoRow(
        'Registration Date',
        DateFormat('dd MMM, yyyy').format(client.createdAt),
        icon: LucideIcons.clock,
      ),
    ]);
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
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

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 8),
          ],
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
