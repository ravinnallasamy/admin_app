import 'package:flutter/material.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
      ),
      body: ListView(
        children: [
          _buildAlertCard('Medication Refill', 'John Doe needs Lisinopril refill', Colors.orange),
          _buildAlertCard('Test Results', 'Jane Smith lab results available', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildAlertCard(String title, String message, Color color) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: color.withOpacity(0.1),
      child: ListTile(
        leading: Icon(Icons.notifications, color: color),
        title: Text(title, style: TextStyle(color: color)),
        subtitle: Text(message),
        trailing: Icon(Icons.chevron_right, color: color),
        onTap: () {
          // View alert details
        },
      ),
    );
  }
}