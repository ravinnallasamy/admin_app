import 'package:flutter/material.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Schedule new appointment
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildAppointmentCard('John Doe', '10:00 AM', 'Regular Checkup'),
          _buildAppointmentCard('Jane Smith', '11:30 AM', 'Diabetes Consultation'),
          _buildAppointmentCard('Robert Johnson', '2:00 PM', 'Follow-up'),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(String name, String time, String reason) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: Text(name),
        subtitle: Text('$time • $reason'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // View appointment details
        },
      ),
    );
  }
}