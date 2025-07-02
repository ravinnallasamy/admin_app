import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final supabase = Supabase.instance.client;
  String feedbackFormUrl = '';
  List<FAQItem> faqs = [];
  Map<String, String> contactInfo = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _fetchContactInfo();
    await _fetchFAQs();
  }

  Future<void> _fetchContactInfo() async {
    try {
      final response = await supabase
          .from('contact_info')
          .select()
          .order('id', ascending: true);

      setState(() {
        for (final item in response) {
          contactInfo[item['key'] as String] = item['value'] as String;
          if (item['key'] == 'form_url') {
            feedbackFormUrl = item['value'] as String;
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching contact info: $e');
    }
  }

  Future<void> _fetchFAQs() async {
    try {
      final response = await supabase
          .from('faqs')
          .select()
          .order('id', ascending: true);

      setState(() {
        faqs = (response as List).map((item) {
          return FAQItem(
            question: item['question'] as String,
            answer: item['answer'] as String,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('Error fetching FAQs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FAQs Section
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (faqs.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: faqs.map((faq) => FAQTile(faq: faq)).toList(),
                ),

              const SizedBox(height: 20),
              const Divider(),

              // Contact Section
              const Text(
                'Contact Support',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (contactInfo.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: [
                    if (contactInfo.containsKey('email'))
                      _buildContactInfoTile(
                        Icons.email,
                        'Email',
                        contactInfo['email']!,
                            () => _launchUrl('mailto:${contactInfo['email']}'),
                      ),
                    if (contactInfo.containsKey('phone'))
                      _buildContactInfoTile(
                        Icons.phone,
                        'Phone',
                        contactInfo['phone']!,
                            () => _launchUrl('tel:${contactInfo['phone']}'),
                      ),
                    if (contactInfo.containsKey('hours'))
                      _buildContactInfoTile(
                        Icons.schedule,
                        'Hours',
                        contactInfo['hours']!,
                        null,
                      ),
                    if (contactInfo.containsKey('address'))
                      _buildContactInfoTile(
                        Icons.location_on,
                        'Address',
                        contactInfo['address']!,
                            () => _launchUrl(
                            'https://maps.google.com/?q=${Uri.encodeComponent(contactInfo['address']!)}'),
                      ),
                  ],
                ),

              const SizedBox(height: 20),
              const Divider(),

              // Feedback Section
              const Text(
                'Feedback',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.feedback, color: Colors.blue),
                title: const Text('Send Feedback'),
                subtitle: const Text('We\'d love to hear your thoughts'),
                trailing: const Icon(Icons.open_in_new),
                onTap: feedbackFormUrl.isEmpty
                    ? null
                    : () => _launchFeedbackForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfoTile(IconData icon, String title, String subtitle, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the URL')),
        );
      }
    }
  }

  Future<void> _launchFeedbackForm() async {
    if (feedbackFormUrl.isEmpty) return;

    try {
      final Uri uri = Uri.parse(feedbackFormUrl);
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open feedback form')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

class FAQItem {
  final String question;
  final String answer;

  const FAQItem({required this.question, required this.answer});
}

class FAQTile extends StatefulWidget {
  final FAQItem faq;

  const FAQTile({super.key, required this.faq});

  @override
  State<FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<FAQTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(
          widget.faq.question,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.blue,
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(widget.faq.answer),
          ),
        ],
      ),
    );
  }
}
