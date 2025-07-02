import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

class ReportsTab extends StatefulWidget {
  final Map<String, dynamic> patient;
  final Function(Map<String, dynamic>) onPatientUpdated;

  const ReportsTab({
    super.key,
    required this.patient,
    required this.onPatientUpdated,
  });

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('patient_id', widget.patient['id'])
          .order('uploaded_at', ascending: false);

      if (response != null) {
        setState(() {
          _reports = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reports: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addReport(BuildContext context) async {
    final reportController = TextEditingController();
    PlatformFile? pickedFile;
    bool isButtonEnabled = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Medical Report'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: reportController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Enter report description',
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        isButtonEnabled = value.isNotEmpty && pickedFile != null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (pickedFile != null)
                    Text('Selected file: ${pickedFile!.name}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
                        allowMultiple: false,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        setState(() {
                          pickedFile = result.files.first;
                          isButtonEnabled =
                              reportController.text.isNotEmpty && pickedFile != null;
                        });
                      }
                    },
                    child: const Text('Select File'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isButtonEnabled
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('Upload'),
              ),
            ],
          );
        },
      ),
    );

    if (result != true) return;

    setState(() => _isLoading = true);

    try {
      if (pickedFile == null || pickedFile!.bytes == null) {
        throw Exception('No file selected or file is empty');
      }

      final fileBytes = pickedFile!.bytes!;
      final fileExtension = pickedFile!.extension ?? 'pdf';
      final fileName = pickedFile!.name;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'reports/${widget.patient['id']}/${timestamp}_$fileName';

      // Upload file to Supabase Storage
      await _supabase.storage
          .from('patient_reports')
          .uploadBinary(
        filePath,
        fileBytes,
        fileOptions: FileOptions(
          contentType: _getMimeType(fileExtension),
        ),
      );

      // Get public URL
      final fileUrl = _supabase.storage
          .from('patient_reports')
          .getPublicUrl(filePath);

      // Insert into reports table
      await _supabase.from('reports').insert({
        'patient_id': widget.patient['id'],
        'description': reportController.text,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_type': fileExtension,
        'file_path': filePath,
        'uploaded_at': DateTime.now().toIso8601String(),
      });

      await _loadReports(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _viewReport(Map<String, dynamic> report) async {
    final fileUrl = report['file_url'] as String;
    final fileType = (report['file_type'] as String? ?? 'pdf').toLowerCase();

    try {
      final uri = Uri.parse(fileUrl);

      // For all file types, open in a new browser tab or download directly
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception("Could not launch file URL");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error viewing report: $e')),
        );
      }
    }
  }

  Future<void> _openFileExternally(String filePath) async {
    try {
      final uri = Uri.parse(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // If direct launch fails, try downloading and then opening
        await _downloadAndOpenFile(filePath, 'temp_${DateTime.now().millisecondsSinceEpoch}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  Future<void> _downloadAndOpenFile(String url, String fileName) async {
    setState(() => _isLoading = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) await file.delete();

      final response = await HttpClient().getUrl(Uri.parse(url));
      final httpResponse = await response.close();
      final bytes = await httpResponse.fold<Uint8List>(
        Uint8List(0),
            (previous, element) => Uint8List.fromList([...previous, ...element]),
      );

      await file.writeAsBytes(bytes);
      await OpenFile.open(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteReport(String reportId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
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

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final report = _reports[index];
      final filePath = report['file_path'] as String;

      await _supabase.storage.from('patient_reports').remove([filePath]);
      await _supabase.from('reports').delete().eq('id', reportId);
      await _loadReports(); // Refresh after deletion

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _addReport(context),
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload New Report'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50), // Let the row handle width
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isLoading ? null : _loadReports,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(50, 50),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    tooltip: 'Refresh reports',
                  ),
                ],
              ),
            ),
            Expanded(
              child: _reports.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 50, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No reports available', style: TextStyle(fontSize: 16)),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  final report = _reports[index];
                  final uploadedAt = DateTime.parse(report['uploaded_at'] ?? DateTime.now().toIso8601String());
                  final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(uploadedAt);
                  final fileType = (report['file_type'] as String? ?? 'pdf').toLowerCase();

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: _getFileIcon(fileType),
                      title: Text(
                        report['description'] ?? 'No description',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(report['file_name'] ?? 'Unknown file'),
                          Text(formattedDate),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: _isLoading
                            ? null
                            : () => _deleteReport(report['id'].toString(), index),
                      ),
                      onTap: () => _viewReport(report),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32);
      case 'jpg':
      case 'jpeg':
      case 'png':
        return const Icon(Icons.image, color: Colors.blue, size: 32);
      case 'doc':
      case 'docx':
        return const Icon(Icons.description, color: Colors.blue, size: 32);
      default:
        return const Icon(Icons.insert_drive_file, color: Colors.grey, size: 32);
    }
  }
}