import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class FileUploadProvider with ChangeNotifier {
  bool _isUploading = false;
  double _progress = 0.0;
  String _status = '';

  bool get isUploading => _isUploading;
  double get progress => _progress;
  String get status => _status;

  void _updateProgress(double value) {
    _progress = value;
    notifyListeners();
  }

  void _updateStatus(String message) {
    _status = message;
    notifyListeners();
  }

  Future<void> uploadFile(String filePath) async {
    _isUploading = true;
    _progress = 0;
    notifyListeners();

    try {
      final receivePort = ReceivePort();
      final progressReceivePort = ReceivePort();

      _updateStatus('Starting file upload...');

      final isolate = await Isolate.spawn(
        _uploadFileInIsolate,
        UploadMessage(
          filePath: filePath,
          sendPort: receivePort.sendPort,
          progressPort: progressReceivePort.sendPort,
        ),
      );

      // Listen for progress updates
      progressReceivePort.listen((progress) {
        if (progress is double) {
          _updateProgress(progress);
          _updateStatus('Uploading: ${(progress * 100).toStringAsFixed(1)}%');
        }
      });

      // Wait for final result
      final result = await receivePort.first;
      if (result is String && result.startsWith('Error:')) {
        _updateStatus(result);
      } else {
        _updateStatus('Upload completed successfully!');
      }

      // Cleanup
      progressReceivePort.close();
      receivePort.close();
      isolate.kill();
    } catch (e) {
      _updateStatus('Error: ${e.toString()}');
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // Isolate worker function
  static Future<void> _uploadFileInIsolate(UploadMessage message) async {
    try {
      final file = File(message.filePath);
      final fileSize = await file.length();
      final fileName = path.basename(message.filePath);

      // Simulated upload URL (replace with your actual upload endpoint)
      final uri = Uri.parse('https://api.example.com/upload');

      // Read file in chunks and track progress
      final chunks = file.openRead();
      var uploadedBytes = 0;

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      final multipartFile = http.MultipartFile(
        'file',
        chunks,
        fileSize,
        filename: fileName,
      );

      // Add file to request
      request.files.add(multipartFile);

      // Track upload progress
      final completer = Completer<void>();
      var lastProgress = 0.0;

      // Send request and track progress
      final response = await request.send();

      response.stream.listen(
        (List<int> bytes) {
          uploadedBytes += bytes.length;
          final progress = uploadedBytes / fileSize;

          // Only send progress updates when there's a significant change
          if (progress - lastProgress >= 0.01) {
            // Update every 1%
            message.progressPort.send(progress);
            lastProgress = progress;
          }
        },
        onDone: () {
          message.sendPort.send('Success');
          completer.complete();
        },
        onError: (error) {
          message.sendPort.send('Error: $error');
          completer.complete();
        },
        cancelOnError: true,
      );

      await completer.future;
    } catch (e) {
      message.sendPort.send('Error: ${e.toString()}');
    }
  }

  // Method to simulate upload for testing
}

class UploadMessage {
  final String filePath;
  final SendPort sendPort;
  final SendPort progressPort;

  UploadMessage({
    required this.filePath,
    required this.sendPort,
    required this.progressPort,
  });
}
