import 'package:flutter/material.dart';

class PrescriptionsPage extends StatelessWidget {
  const PrescriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Add new prescription
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildPrescriptionCard('John Doe', 'Lisinopril', '10mg daily'),
          _buildPrescriptionCard('Jane Smith', 'Metformin', '500mg twice daily'),
          _buildPrescriptionCard('Robert Johnson', 'Ibuprofen', '400mg as needed'),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(String patient, String medicine, String dosage) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: const Icon(Icons.medication),
        title: Text(medicine),
        subtitle: Text('$patient • $dosage'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // View prescription details
        },
      ),
    );
  }
}