// api_gateway_service.dart - VERSIÓN SIMPLIFICADA
import 'dart:convert';
import 'dart:io';
//import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class APIGatewayService {
  // Tu URL de API Gateway
  static const String _baseUrl = 'https://d11qhuqgtk.execute-api.us-east-2.amazonaws.com/prod';

  // Método para registrar token FCM SIN AUTENTICACIÓN
  static Future<bool> registerFCMToken(String fcmToken) async {
    try {
      // Obtener información del dispositivo
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;
      String platform;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        platform = 'android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
        platform = 'ios';
      } else {
        deviceId = 'web_${DateTime.now().millisecondsSinceEpoch}';
        platform = 'web';
      }

      // Enviar token FCM a API Gateway
      final response = await http.post(
        Uri.parse('$_baseUrl/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          // NO necesitamos Authorization header
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
          'deviceId': deviceId,
          'platform': platform,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Token FCM registrado exitosamente');
        print('📊 Respuesta: ${response.body}');
        return true;
      } else {
        print('❌ Error API Gateway: ${response.statusCode}');
        print('📋 Detalles: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error en registerFCMToken: $e');
      return false;
    }
  }

  // Método para eliminar token (opcional)
  static Future<bool> deleteFCMToken(String deviceId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceId': deviceId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error eliminando token: $e');
      return false;
    }
  }
}