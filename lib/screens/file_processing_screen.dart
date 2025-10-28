import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_processing_provider.dart';

class FileProcessingScreen extends StatelessWidget {
  const FileProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Processing with Isolates'),
        backgroundColor: Colors.blue,
      ),
      body: Consumer<FileProcessingProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: provider.isProcessing
                      ? null
                      : () async {
                          try {
                            final filePath = await provider
                                .generateSampleFile();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Sample file generated successfully!',
                                  ),
                                ),
                              );
                              provider.processLargeFile(filePath);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              log('Error: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),

                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Generate and Process File'),
                ),
                const SizedBox(height: 20),
                if (provider.isProcessing) ...[
                  LinearProgressIndicator(value: provider.progress),
                  const SizedBox(height: 10),
                  Text(
                    'Progress: ${(provider.progress * 100).toStringAsFixed(1)}%',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Status: ${provider.status}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                const SizedBox(height: 20),
                if (provider.processedData.isNotEmpty) ...[
                  Text(
                    'Processed ${provider.processedData.length} records',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.processedData.length,
                      itemBuilder: (context, index) {
                        final item = provider.processedData[index];
                        return Card(
                          child: ListTile(
                            title: Text('Item ${item['id']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Name: ${item['name']}'),
                                Text('Value: ${item['value']}'),
                                Text(
                                  'Processed: ${item['processed_timestamp']}',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
