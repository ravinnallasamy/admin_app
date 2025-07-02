import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MedicationsTab extends StatefulWidget {
  final int patientId;

  const MedicationsTab({
    super.key,
    required this.patientId,
  });

  @override
  State<MedicationsTab> createState() => _MedicationsTabState();
}

class _MedicationsTabState extends State<MedicationsTab> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;
  bool _isSaving = false;
  final Map<String, TimeOfDay?> _selectedTimes = {
    'morning': null,
    'afternoon': null,
    'evening': null,
    'night': null,
  };
  final List<String> _selectedDosageTimes = [];

  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  Future<void> _fetchMedications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('medications')
          .select()
          .eq('patient_id', widget.patientId)
          .order('start_date', ascending: false);

      if (mounted) {
        setState(() {
          _medications = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load medications: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context, String timeOfDay) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTimes[timeOfDay] = picked;
      });
    }
  }

  Future<void> _addMedication() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();

    // Reset selections
    _selectedTimes.forEach((key, value) => _selectedTimes[key] = null);
    _selectedDosageTimes.clear();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Medication', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Medication Name*',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: dosageController,
                        decoration: const InputDecoration(
                          labelText: 'Dosage*',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: frequencyController,
                        decoration: const InputDecoration(
                          labelText: 'Frequency*',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Dosage Times*',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['morning', 'afternoon', 'evening', 'night'].map((time) {
                          return SizedBox(
                            width: 150,
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _selectedDosageTimes.contains(time),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedDosageTimes.add(time);
                                      } else {
                                        _selectedDosageTimes.remove(time);
                                        _selectedTimes[time] = null;
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text('${time[0].toUpperCase()}${time.substring(1)}'),
                                ),
                                if (_selectedDosageTimes.contains(time))
                                  SizedBox(
                                    width: 100,
                                    child: TextButton(
                                      onPressed: () => _selectTime(context, time),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: Text(
                                        _selectedTimes[time]?.format(context) ?? 'Set time',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
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
                  onPressed: () async {
                    if (_isSaving) return;

                    if (!(formKey.currentState?.validate() ?? false)) return;

                    if (_selectedDosageTimes.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select at least one dosage time')),
                      );
                      return;
                    }

                    for (var time in _selectedDosageTimes) {
                      if (_selectedTimes[time] == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please set time for $time')),
                        );
                        return;
                      }
                    }

                    setState(() => _isSaving = true);

                    try {
                      final timesMap = {};
                      for (var time in _selectedDosageTimes) {
                        final tod = _selectedTimes[time]!;
                        timesMap[time] =
                        '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
                      }

                      final response = await _supabase
                          .from('medications')
                          .insert({
                        'patient_id': widget.patientId,
                        'name': nameController.text,
                        'dosage': dosageController.text,
                        'frequency': frequencyController.text,
                        'times': timesMap,
                      })
                          .select()
                          .single()
                          .timeout(const Duration(seconds: 10));

                      if (mounted) {
                        Navigator.pop(context);
                        _fetchMedications();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Medication saved successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } on PostgrestException catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save: ${e.message}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _isSaving = false);
                      }
                    }
                  },
                  child: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editMedication(Map<String, dynamic> medication) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: medication['name']);
    final dosageController = TextEditingController(text: medication['dosage']);
    final frequencyController = TextEditingController(text: medication['frequency']);

    // Parse existing times
    final existingTimes = medication['times'] is Map ?
    Map<String, dynamic>.from(medication['times']) : {};

    // Initialize selections
    _selectedDosageTimes.clear();
    _selectedTimes.forEach((key, value) => _selectedTimes[key] = null);

    existingTimes.forEach((time, value) {
      _selectedDosageTimes.add(time);
      final parts = value.toString().split(':');
      if (parts.length == 2) {
        _selectedTimes[time] = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    });

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Medication', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Medication Name*',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: dosageController,
                        decoration: const InputDecoration(
                          labelText: 'Dosage*',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: frequencyController,
                        decoration: const InputDecoration(
                          labelText: 'Frequency*',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Dosage Times*',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['morning', 'afternoon', 'evening', 'night'].map((time) {
                          return SizedBox(
                            width: 150,
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _selectedDosageTimes.contains(time),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedDosageTimes.add(time);
                                      } else {
                                        _selectedDosageTimes.remove(time);
                                        _selectedTimes[time] = null;
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text('${time[0].toUpperCase()}${time.substring(1)}'),
                                ),
                                if (_selectedDosageTimes.contains(time))
                                  SizedBox(
                                    width: 100,
                                    child: TextButton(
                                      onPressed: () => _selectTime(context, time),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: Text(
                                        _selectedTimes[time]?.format(context) ?? 'Set time',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
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
                  onPressed: () async {
                    if (_isSaving) return;

                    if (!(formKey.currentState?.validate() ?? false)) return;

                    if (_selectedDosageTimes.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select at least one dosage time')),
                      );
                      return;
                    }

                    for (var time in _selectedDosageTimes) {
                      if (_selectedTimes[time] == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please set time for $time')),
                        );
                        return;
                      }
                    }

                    setState(() => _isSaving = true);

                    try {
                      final timesMap = {};
                      for (var time in _selectedDosageTimes) {
                        final tod = _selectedTimes[time]!;
                        timesMap[time] =
                        '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
                      }

                      await _supabase
                          .from('medications')
                          .update({
                        'name': nameController.text,
                        'dosage': dosageController.text,
                        'frequency': frequencyController.text,
                        'times': timesMap,
                      })
                          .eq('id', medication['id'])
                          .timeout(const Duration(seconds: 10));

                      if (mounted) {
                        Navigator.pop(context);
                        _fetchMedications();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Medication updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } on PostgrestException catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update: ${e.message}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _isSaving = false);
                      }
                    }
                  },
                  child: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteMedication(int medicationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this medication?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _supabase
            .from('medications')
            .delete()
            .eq('id', medicationId)
            .timeout(const Duration(seconds: 10));

        _fetchMedications();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } on PostgrestException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Medications',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addMedication,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Medication'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_medications.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.medication_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No medications found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a medication to get started',
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchMedications,
                child: ListView.separated(
                  itemCount: _medications.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final med = _medications[index];
                    final times = med['times'] is Map
                        ? Map<String, dynamic>.from(med['times'])
                        : {};

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    med['name'],
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.primary),
                                      onPressed: () => _editMedication(med),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.error),
                                      onPressed: () => _deleteMedication(med['id']),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildMedicationDetail('Dosage', med['dosage']),
                            _buildMedicationDetail('Frequency', med['frequency']),
                            if (times.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text('Scheduled Times:',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  )),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: times.entries.map((e) => Chip(
                                  label: Text(
                                    '${e.key[0].toUpperCase()}${e.key.substring(1)}: ${e.value}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                )).toList(),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text(
                              'Started: ${_formatDate(med['start_date'])}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}