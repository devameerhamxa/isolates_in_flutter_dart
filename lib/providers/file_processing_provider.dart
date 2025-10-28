import 'dart:developer';
import 'dart:isolate';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class FileProcessingProvider with ChangeNotifier {
  double _progress = 0.0;
  String _status = '';
  bool _isProcessing = false;
  List<Map<String, dynamic>> _processedData = [];

  double get progress => _progress;
  String get status => _status;
  bool get isProcessing => _isProcessing;
  List<Map<String, dynamic>> get processedData => _processedData;

  void _updateProgress(double value) {
    _progress = value;
    notifyListeners();
  }

  void _updateStatus(String status) {
    _status = status;
    notifyListeners();
  }

  Future<void> processLargeFile(String filePath) async {
    _isProcessing = true;
    _progress = 0.0;
    _processedData = [];
    notifyListeners();

    try {
      final receivePort = ReceivePort();
      final progressReceivePort = ReceivePort();

      _updateStatus('Starting file processing...');

      final isolate = await Isolate.spawn(
        _processFileInIsolate,
        ProcessFileMessage(
          filePath: filePath,
          sendPort: receivePort.sendPort,
          progressPort: progressReceivePort.sendPort,
        ),
      );

      // Listen for progress updates
      progressReceivePort.listen((progress) {
        if (progress is double) {
          _updateProgress(progress);
        }
      });

      // Wait for final result
      final result = await receivePort.first;
      if (result is List<Map<String, dynamic>>) {
        _processedData = result;
        _updateStatus('Processing completed successfully!');
      } else if (result is String) {
        _updateStatus('Error: $result');
      }

      // Cleanup
      progressReceivePort.close();
      receivePort.close();
      isolate.kill();
    } catch (e) {
      _updateStatus('Error: ${e.toString()}');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Isolate worker function
  static void _processFileInIsolate(ProcessFileMessage message) async {
    try {
      final file = File(message.filePath);
      final fileSize = await file.length();
      var processedBytes = 0;
      final List<Map<String, dynamic>> processedRecords = [];

      // Process file in chunks
      final stream = file
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (var line in stream) {
        // Simulate heavy processing for each line
        await Future.delayed(const Duration(milliseconds: 10));

        try {
          final data = jsonDecode(line);
          if (data is Map<String, dynamic>) {
            // Apply some transformations
            data['processed_timestamp'] = DateTime.now().toIso8601String();
            data['line_length'] = line.length;
            processedRecords.add(data);
          }
        } catch (e) {
          log('Error processing line: $e');
        }

        processedBytes += line.length;
        final progress = processedBytes / fileSize;
        message.progressPort.send(progress);
      }

      message.sendPort.send(processedRecords);
    } catch (e) {
      message.sendPort.send('Error processing file: ${e.toString()}');
    }
  }

  Future<String> generateSampleFile() async {
    try {
      // Try to get the application documents directory
      Directory directory;
      try {
        directory = await path_provider.getApplicationDocumentsDirectory();
      } catch (e) {
        // Fallback to temporary directory if app documents directory is not available
        directory = await path_provider.getTemporaryDirectory();
      }

      final file = File('${directory.path}/sample_data.json');

      final sampleData = List.generate(
        1000,
        (index) => {
          'id': index,
          'name': 'Item $index',
          'value': (index * 3.14159).toString(),
          'timestamp': DateTime.now()
              .add(Duration(minutes: index))
              .toIso8601String(),
          'data': List.generate(50, (i) => 'data_$i').join(','),
        },
      );

      final sink = file.openWrite();
      for (var data in sampleData) {
        sink.writeln(jsonEncode(data));
      }
      await sink.flush();
      await sink.close();

      return file.path;
    } catch (e) {
      throw 'Error generating sample file: ${e.toString()}';
    }
  }
}

class ProcessFileMessage {
  final String filePath;
  final SendPort sendPort;
  final SendPort progressPort;

  ProcessFileMessage({
    required this.filePath,
    required this.sendPort,
    required this.progressPort,
  });
}
