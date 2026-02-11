// models/medicion.dart
class Medicion {
  final String id;
  final int timestamp;
  final double agua;
  final double diesel;
  final double glp;
  final double aguaR;

  Medicion({
    required this.id,
    required this.timestamp,
    required this.agua,
    required this.diesel,
    required this.glp,
    required this.aguaR,
  });

  // Factory para convertir el JSON de GraphQL
  factory Medicion.fromJson(Map<String, dynamic> json) {
    return Medicion(
      id: json['id'] ?? '',
      // Nota: El modelo autogenerado usa 'timestamp'
      timestamp: json['timestamp'] ?? 0,
      agua: (json['Agua'] ?? 0).toDouble(),
      diesel: (json['Diesel'] ?? 0).toDouble(),
      glp: (json['gLP'] ?? 0).toDouble(), // Asegura la 'g' minúscula si así está en tu Dynamo
      aguaR: (json['AguaR'] ?? 0).toDouble(),
    );
  }

  // Para compatibilidad con tu código existente que usa Maps
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'Agua': agua,
      'Diesel': diesel,
      'gLP': glp,
      'AguaR': aguaR,
    };
  }
}