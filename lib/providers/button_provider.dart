import 'package:flutter/foundation.dart';

class ButtonProvider with ChangeNotifier {
  int _buttonClickCount = 0;

  int get buttonClickCount => _buttonClickCount;

  void incrementButton1() {
    _buttonClickCount++;
    notifyListeners();
  }

  void incrementButton2() {
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

  Future<double> heavyComputation() async {
    var result = 0.0;
    for (var i = 0; i < 100000000000; i++) {
      result += i;
    }
    return result;
  }
}
