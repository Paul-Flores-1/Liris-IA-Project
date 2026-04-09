import 'package:http/http.dart' as http;
import 'dart:convert';

class IaService {
  // NOTA: Asegúrate de que esta IP sea la que te da 'ipconfig' en tu PC actualmente.
  static const String _baseUrl = 'http://192.168.100.8:8080/chat';

  /// Envía el mensaje al Triple-Core de Liris y devuelve la respuesta procesada.
  /// AHORA RECIBE EL GÉNERO DEL USUARIO COMO PARÁMETRO OPCIONAL
  static Future<Map<String, dynamic>> enviarMensajeALiris(String mensaje, {String? generoUsuario}) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        // AQUÍ LA MAGIA: Enviamos el mensaje y el género (si existe) al backend
        body: jsonEncode({
          'mensaje': mensaje,
          'genero_usuario': generoUsuario, 
        }),
      );

      if (response.statusCode == 200) {
        // Decodificamos con UTF-8 para que los acentos y la 'ñ' salgan perfectos en el celular
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        // Si la IA encontró productos, los pre-procesamos para la UI
        if (data['status'] == 'success' && data['productos'] != null) {
          List productosRaw = data['productos'];
          
          // Creamos una lista limpia, pero rescatando el ID y notas para detalles.dart
          List<Map<String, dynamic>> productosProcesados = productosRaw.map((p) {
            return {
              'id': p['id'] ?? '', // <-- Vital para la navegación a detalles
              'nombre': p['nombre']?.toString().toUpperCase() ?? 'PERFUME SIN NOMBRE',
              'marca': p['marca']?.toString().toUpperCase() ?? 'GENÉRICO',
              'precio': p['precio']?.toString() ?? '0.00',
              'ml': p['ml']?.toString() ?? 'N/A',
              'descripcion_ia': p['descripcion_ia'] ?? 'Una excelente opción para ti.',
              'imagen_url': p['imagen_url'] ?? '', 
              'sexo': p['sexo'] ?? '',
              'notas_olfativas': p['notas_olfativas'] ?? {}, // <-- Vital para detalles
            };
          }).toList();

          return {
            'status': 'success',
            'intencion': data['intencion'],
            'respuesta_texto': data['respuesta_texto'] ?? 'Mira lo que encontré:',
            'productos': productosProcesados,
            'datos_ia': data['datos_ia'] 
          };
        }

        return data; 
      } else {
        print("Error en el servidor de IA: ${response.statusCode}");
        return {
          "status": "error",
          "respuesta_texto": "El servidor respondió con un error (Código: ${response.statusCode}).",
          "productos": []
        };
      }
    } catch (e) {
      print("Error de conexión con Liris: $e");
      return {
        "status": "error",
        "respuesta_texto": "No puedo conectar con Liris. Verifica que tu PC y celular compartan el Wi-Fi y la IP sea correcta.",
        "productos": []
      };
    }
  }
}