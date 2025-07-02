import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPatientDialog extends StatefulWidget {
  final Map<String, dynamic>? patient;

  const AddPatientDialog({super.key, this.patient});

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _conditionController = TextEditingController();
  final _notesController = TextEditingController();

  String? _gender;
  String? _bloodGroup;
  DateTime? _birthDate;
  bool _isMarried = false;
  bool _hasInsurance = false;
  bool _isSubmitting = false;

  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-',
    'AB+', 'AB-', 'O+', 'O-',
    'Unknown'
  ];

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _idController.text = widget.patient!['id']?.toString() ?? '';
      _nameController.text = widget.patient!['name'] ?? '';
      _ageController.text = widget.patient!['age']?.toString() ?? '';
      _phoneController.text = widget.patient!['phone'] ?? '';
      _emailController.text = widget.patient!['email'] ?? '';
      _addressController.text = widget.patient!['address'] ?? '';
      _conditionController.text = widget.patient!['condition'] ?? '';
      _notesController.text = widget.patient!['notes'] ?? '';
      _gender = widget.patient!['gender'];
      _bloodGroup = widget.patient!['blood_group'];
      _isMarried = widget.patient!['is_married'] ?? false;
      _hasInsurance = widget.patient!['has_insurance'] ?? false;

      try {
        _birthDate = widget.patient!['birth_date'] != null
            ? DateTime.parse(widget.patient!['birth_date'])
            : null;
      } catch (e) {
        _birthDate = null;
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _conditionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submitForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final patientData = {
        'id': int.tryParse(_idController.text),
        'name': _nameController.text,
        'age': int.tryParse(_ageController.text),
        'birth_date': _birthDate?.toIso8601String(),
        'gender': _gender,
        'blood_group': _bloodGroup,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'condition': _conditionController.text,
        'notes': _notesController.text,
        'is_married': _isMarried,
        'has_insurance': _hasInsurance,
      };

      // Remove null values
      patientData.removeWhere((key, value) => value == null);

      final response = widget.patient == null
          ? await _supabase.from('patients').insert(patientData).select().single()
          : await _supabase.from('patients').update(patientData).eq('id', widget.patient!['id']).select().single();

      if (!mounted) return;
      Navigator.pop(context, response);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database error: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(
        widget.patient == null ? 'Add New Patient' : 'Edit Patient',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(_idController, 'Patient ID*', true, keyboardType: TextInputType.number),
              _buildTextField(_nameController, 'Full Name*', true),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(_ageController, 'Age', false, keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Birth Date',
                        border: OutlineInputBorder(),
                      ),
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            _birthDate != null
                                ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                                : 'Select date',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildDropdown(_genders, _gender, 'Gender', (value) {
                setState(() => _gender = value);
              }, required: true),
              _buildDropdown(_bloodGroups, _bloodGroup, 'Blood Group', (value) {
                setState(() => _bloodGroup = value);
              }),
              _buildTextField(_phoneController, 'Phone Number', false, keyboardType: TextInputType.phone),
              _buildTextField(_emailController, 'Email', false, keyboardType: TextInputType.emailAddress),
              _buildTextField(_addressController, 'Address', false, maxLines: 2),
              _buildTextField(_conditionController, 'Medical Condition*', true),
              _buildTextField(_notesController, 'Notes', false, maxLines: 3),
              SwitchListTile(
                title: const Text('Married'),
                value: _isMarried,
                onChanged: (value) => setState(() => _isMarried = value),
              ),
              SwitchListTile(
                title: const Text('Has Insurance'),
                value: _hasInsurance,
                onChanged: (value) => setState(() => _hasInsurance = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
          ),
          onPressed: _isSubmitting ? null : () => _submitForm(context),
          child: _isSubmitting
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Text('SAVE', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      bool required, {
        TextInputType? keyboardType,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: required
            ? (value) => value!.isEmpty ? '$label is required' : null
            : null,
      ),
    );
  }

  Widget _buildDropdown(
      List<String> items,
      String? value,
      String label,
      ValueChanged<String?> onChanged, {
        bool required = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: required
            ? (value) => value == null ? 'Please select $label' : null
            : null,
      ),
    );
  }
}