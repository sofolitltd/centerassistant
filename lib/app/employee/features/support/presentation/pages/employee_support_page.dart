import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '/core/constants/app_constants.dart';

class EmployeeSupportPage extends StatelessWidget {
  const EmployeeSupportPage({super.key});

  Future<void> _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: Could not open link')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                InkWell(
                  onTap: () => context.go('/employee/layout'),
                  child: Text(
                    'Overview',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                Text('Help & Support', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Help & Support',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Need assistance? Find answers to common questions or reach out to our support team.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),

            // FAQ Section
            _buildSectionTitle(context, 'Frequently Asked Questions'),
            const SizedBox(height: 16),
            _buildFAQTile(
              context,
              'How do I reset my password?',
              'You can reset your password from the Profile page. If you\'ve forgotten your current password, please contact your administrator.',
            ),
            _buildFAQTile(
              context,
              'How do I view my assigned clients?',
              'Navigate to the "My Clients" section from the sidebar to see all clients currently assigned to your schedule.',
            ),
            _buildFAQTile(
              context,
              'What should I do if my schedule is incorrect?',
              'If you notice discrepancies in your weekly schedule, please notify your supervisor or center administrator to update the master template.',
            ),

            const SizedBox(height: 40),

            // Contact Support Section
            _buildSectionTitle(context, 'Contact Support'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    context,
                    LucideIcons.mail,
                    'Email Support',
                    AppConstants.supportEmail,
                    Colors.blue,
                    onTap: () => _launchURL(
                      context,
                      'mailto:${AppConstants.supportEmail}',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildContactCard(
                    context,
                    LucideIcons.phone,
                    'Phone Support',
                    AppConstants.supportPhone,
                    Colors.green,
                    onTap: () => _launchURL(
                      context,
                      'tel:${AppConstants.supportPhone.replaceAll(' ', '')}',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Resources
            _buildSectionTitle(context, 'Resources'),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildResourceLink(
                    context,
                    LucideIcons.fileText,
                    'User Guide & Documentation',
                  ),
                  const Divider(height: 1),
                  _buildResourceLink(
                    context,
                    LucideIcons.video,
                    'Video Tutorials',
                  ),
                  const Divider(height: 1),
                  _buildResourceLink(
                    context,
                    LucideIcons.info,
                    'Privacy Policy',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildFAQTile(BuildContext context, String question, String answer) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(
            answer,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceLink(BuildContext context, IconData icon, String label) {
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: Theme.of(context).colorScheme.secondary,
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(
        LucideIcons.externalLink,
        size: 14,
        color: Colors.grey,
      ),
      onTap: () {},
    );
  }
}
