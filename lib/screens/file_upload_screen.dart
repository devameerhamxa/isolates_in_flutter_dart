import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/file_upload_provider.dart';

class FileUploadScreen extends StatelessWidget {
  const FileUploadScreen({super.key});

  Future<void> _pickAndUploadFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        if (!context.mounted) return;

        // Start upload
        await context.read<FileUploadProvider>().uploadFile(
          result.files.single.path!,
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Upload with Isolates'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<FileUploadProvider>(
            builder: (context, provider, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (provider.isUploading) ...[
                    CircularProgressIndicator(value: provider.progress),
                    const SizedBox(height: 20),
                    Text(
                      provider.status,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(value: provider.progress),
                    const SizedBox(height: 10),
                    Text(
                      '${(provider.progress * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ] else ...[
                    const Icon(
                      Icons.cloud_upload_outlined,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      provider.status.isNotEmpty
                          ? provider.status
                          : 'Select a file to upload',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: provider.isUploading
                        ? null
                        : () => _pickAndUploadFile(context),
                    child: const Text('Select and Upload File'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
