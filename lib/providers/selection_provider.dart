// lib/providers/selection_provider.dart


import 'package:flutter_riverpod/legacy.dart';


// Provider que guarda el índice de la tarjeta seleccionada (null = ninguna)
final selectedCardProvider = StateProvider<int?>((ref) => 0);