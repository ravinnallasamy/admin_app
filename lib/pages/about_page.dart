import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // ✅ Slightly smaller image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24), // reduce width by adding padding
              child: Image.asset(
                'lib/assets/tumo.jpg',
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Medical Portal v1.0',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'A comprehensive medical management system',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Managed by',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Text(
              'TUMOCARE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Founder: @ravin',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              '© 2023 Tumocare. All rights reserved.',
              style: TextStyle(fontSize: 14),
            ),
            _buildInfoCard(
              context: context,
              title: 'Privacy Policy',
              content: '''
1. Information Collection:
We collect basic user information to provide our services effectively.

2. Data Usage:
Your data is used solely for medical portal functionality and is never shared with third parties without consent.

3. Security:
We implement industry-standard security measures to protect your information.

4. Changes:
We may update this policy periodically. Continued use constitutes acceptance.
              ''',
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              context: context,
              title: 'Terms of Service',
              content: '''
1. Acceptance:
By using this app, you agree to these terms.

2. Medical Disclaimer:
This portal provides tools but doesn't replace professional medical advice.

3. User Responsibilities:
You're responsible for maintaining the confidentiality of your account.

4. Limitations:
Tumocare isn't liable for indirect damages from app use.

5. Governing Law:
These terms are governed by the laws of [Your Country].
              ''',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
