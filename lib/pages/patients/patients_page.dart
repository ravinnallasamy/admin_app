import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/add_patient_dialog.dart';
import 'patient_details.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isAddingPatient = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final response = await _supabase
          .from('patients')
          .select('*')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _patients = List<Map<String, dynamic>>.from(response);
        _filteredPatients = List.from(_patients);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load patients: ${e.toString()}')),
      );
    }
  }

  Future<void> _addNewPatient(BuildContext context) async {
    if (_isAddingPatient) return;

    setState(() => _isAddingPatient = true);

    try {
      final newPatient = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const AddPatientDialog(),
      );

      if (newPatient != null && mounted) {
        setState(() {
          _patients.insert(0, newPatient);
          _filterPatients(_searchController.text);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding patient: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingPatient = false);
      }
    }
  }

  Future<void> _deletePatient(int id, int index) async {
    try {
      await _supabase.from('patients').delete().eq('id', id);

      setState(() {
        _patients.removeAt(index);
        _filterPatients(_searchController.text);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting patient: ${e.toString()}')),
      );
    }
  }

  void _filterPatients(String query) {
    setState(() {
      _filteredPatients = _patients.where((patient) {
        final name = patient['name']?.toString().toLowerCase() ?? '';
        final condition = patient['condition']?.toString().toLowerCase() ?? '';
        final phone = patient['phone']?.toString().toLowerCase() ?? '';
        return name.contains(query.toLowerCase()) ||
            condition.contains(query.toLowerCase()) ||
            phone.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _handleRefresh() async {
    await _fetchPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        actions: [
          IconButton(
            icon: _isAddingPatient
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.add),
            onPressed: _isAddingPatient ? null : () => _addNewPatient(context),
          ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchPatients,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: _filterPatients,
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load patients',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _fetchPatients,
            ),
          ],
        ),
      );
    }

    if (_filteredPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No patients found'
                  : 'No matching patients',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'Add a new patient by clicking the + button'
                  : 'Try a different search term',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.separated(
        itemCount: _filteredPatients.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final patient = _filteredPatients[index];
          return _buildPatientCard(patient, index);
        },
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient, int index) {
    final originalIndex = _patients.indexWhere((p) => p['id'] == patient['id']);

    return Dismissible(
      key: Key(patient['id'].toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.blue,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await _editPatient(context, patient, originalIndex);
          return false;
        } else {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Patient'),
              content: const Text('Are you sure you want to delete this patient?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _deletePatient(patient['id'], originalIndex);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(patient['name']?[0] ?? '?',
                style: const TextStyle(color: Colors.blue)),
          ),
          title: Text(
            patient['name'] ?? 'No name',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (patient['condition'] != null)
                Text('Condition: ${patient['condition']}'),
              if (patient['last_visit'] != null)
                Text('Last visit: ${_formatDate(patient['last_visit'])}'),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailsPage(
                  patient: patient,
                  onPatientUpdated: (updatedPatient) {
                    setState(() {
                      _patients[originalIndex] = updatedPatient;
                      _filterPatients(_searchController.text);
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _editPatient(BuildContext context, Map<String, dynamic> patient, int index) async {
    try {
      final updatedPatient = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AddPatientDialog(patient: patient),
      );

      if (updatedPatient != null && mounted) {
        final response = await _supabase
            .from('patients')
            .update(updatedPatient)
            .eq('id', patient['id'])
            .select()
            .single();

        setState(() {
          _patients[index] = response;
          _filterPatients(_searchController.text);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating patient: ${e.toString()}')),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}