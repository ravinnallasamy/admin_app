import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/pages/widgets/reports_tab.dart';
import 'package:app/pages/widgets/appointments_tab.dart';
import 'package:app/pages/widgets/medications_tab.dart';

class PatientDetailsPage extends StatefulWidget {
  final Map<String, dynamic> patient;
  final Function(Map<String, dynamic>) onPatientUpdated;

  const PatientDetailsPage({
    super.key,
    required this.patient,
    required this.onPatientUpdated,
  });

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  late Map<String, dynamic> _currentPatient;
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _currentPatient = Map.from(widget.patient);
  }

  Future<void> _updatePatient(Map<String, dynamic> updatedData) async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('patients')
          .update(updatedData)
          .eq('id', _currentPatient['id'])
          .select()
          .single();

      setState(() => _currentPatient = response);
      widget.onPatientUpdated(response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating patient: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showEditDialog() async {
    final formKey = GlobalKey<FormState>();
    Map<String, dynamic> editedPatient = Map.from(_currentPatient);
    DateTime? selectedDate;

    if (_currentPatient['birth_date'] != null) {
      selectedDate = DateTime.tryParse(_currentPatient['birth_date']);
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Patient'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: editedPatient['name'],
                      decoration: const InputDecoration(labelText: 'Name*'),
                      validator: (value) =>
                      value?.isEmpty ?? true ? 'Name is required' : null,
                      onChanged: (value) => editedPatient['name'] = value,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: editedPatient['age']?.toString(),
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                      editedPatient['age'] = int.tryParse(value),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        selectedDate != null
                            ? 'Birth Date: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}'
                            : 'Select Birth Date',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ??
                              DateTime.now().subtract(const Duration(days: 365 * 30)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                            editedPatient['birth_date'] = date.toIso8601String();
                          });
                        }
                      },
                    ),
                    // Add more fields as needed
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.pop(context, editedPatient);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && mounted) {
      await _updatePatient(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentPatient['name'] ?? 'Patient Details'),
          actions: [
            IconButton(
              icon: _isLoading
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.edit),
              onPressed: _isLoading ? null : _showEditDialog,
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.info), text: 'Details'),
              Tab(icon: Icon(Icons.assignment), text: 'Reports'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Appointments'),
              Tab(icon: Icon(Icons.medication), text: 'Medications'),
            ],
            onTap: (index) {
              if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MedicationsTab(patientId: _currentPatient['id']),
                  ),
                );
              }
            },
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildDetailsTab(),
            ReportsTab(
              patient: _currentPatient,
              onPatientUpdated: _updatePatient,
            ),
            AppointmentsTab(
              patientId: _currentPatient['id'], // ✅ Corrected
              onPatientUpdated: _updatePatient,
            ),
            Container(), // Placeholder for Medications
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Patient ID', _currentPatient['id']?.toString() ?? 'N/A'),
          _buildDetailRow('Name', _currentPatient['name'] ?? 'N/A'),
          _buildDetailRow('Age', _currentPatient['age']?.toString() ?? 'N/A'),
          if (_currentPatient['birth_date'] != null)
            _buildDetailRow(
              'Birth Date',
              DateFormat('dd/MM/yyyy')
                  .format(DateTime.parse(_currentPatient['birth_date'])),
            ),
          _buildDetailRow('Gender', _currentPatient['gender'] ?? 'N/A'),
          _buildDetailRow('Blood Group', _currentPatient['blood_group'] ?? 'N/A'),
          _buildDetailRow('Condition', _currentPatient['condition'] ?? 'N/A'),
          _buildDetailRow(
            'Last Visit',
            _currentPatient['last_visit'] != null
                ? DateFormat('dd/MM/yyyy')
                .format(DateTime.parse(_currentPatient['last_visit']))
                : 'N/A',
          ),
          _buildDetailRow('Address', _currentPatient['address'] ?? 'N/A'),
          _buildDetailRow('Phone', _currentPatient['phone'] ?? 'N/A'),
          _buildDetailRow('Email', _currentPatient['email'] ?? 'N/A'),
          _buildDetailRow(
            'Marital Status',
            _currentPatient['is_married'] == true ? 'Married' : 'Single',
          ),
          _buildDetailRow(
            'Insurance',
            _currentPatient['has_insurance'] == true ? 'Yes' : 'No',
          ),
          if (_currentPatient['notes'] != null)
            _buildDetailRow('Notes', _currentPatient['notes']),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
