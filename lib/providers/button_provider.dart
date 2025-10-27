import 'dart:developer';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

class ButtonProvider with ChangeNotifier {
  int _buttonClickCount = 0;

  int get buttonClickCount => _buttonClickCount;

  void incrementButton1() {
    _buttonClickCount++;
    notifyListeners();
  }

  Future<void> incrementButton2() async {
    final receivePort = ReceivePort();

    // Create the isolate
    final isolate = await Isolate.spawn(heavyComputation, receivePort.sendPort);

    // Get the result from the isolate
    final result = await receivePort.first as double;
    log('Heavy computation result: $result');

    // Clean up
    receivePort.close();
    isolate.kill();

    _buttonClickCount += 2;
    notifyListeners();
  }

  void incrementButton3() {
    _buttonClickCount += 3;
    notifyListeners();
  }

  void resetCount() {
    _buttonClickCount = 0;
    notifyListeners();
  }

  // Static method for isolate
  static void heavyComputation(SendPort sendPort) {
    var result = 0.0;
    for (var i = 0; i < 1000000000; i++) {
      result += i;
    }
    sendPort.send(result);
  }

  Future<double> testComputation() async {
    var result = 0.0;
    for (var i = 0; i < 10000; i++) {
      result += i;
      log('Result of heavy computation so far: $result');
    }
    return result;
  }
}
