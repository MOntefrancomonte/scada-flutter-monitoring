// lib/providers/counter_provider.dart

// Provider para el contador (se mantiene como ChangeNotifier para compatibilidad)
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/legacy.dart';

class Counter extends ChangeNotifier {
  int value = 0;

  void increment() {
    value++;
    notifyListeners();
  }
}

final counterProvider = ChangeNotifierProvider<Counter>((ref) => Counter());
