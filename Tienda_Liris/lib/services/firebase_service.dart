import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String _limpiarTexto(String texto) {
    return texto.toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll(',', ' ')
        .trim();
  }

  static Future<List<Map<String, dynamic>>> buscarPerfumesPorNotas(List<dynamic> notasIA, String sexoIA) async {
    List<Map<String, dynamic>> resultadosEncontrados = [];
    
    try {
      QuerySnapshot query = await _db.collection('productos').get();
      String sexoBuscado = _limpiarTexto(sexoIA);

      for (var doc in query.docs) {
        if (resultadosEncontrados.length >= 3) break;

        var data = doc.data() as Map<String, dynamic>;
        
        String sexoBD = _limpiarTexto((data['sexo'] ?? '').toString());
        
        if (sexoBuscado.isNotEmpty && sexoBuscado != "unisex") {
            if (!sexoBD.contains(sexoBuscado) && !sexoBuscado.contains(sexoBD)) {
                continue;
            }
        }

        Map<String, dynamic> notasBD = data['notas_olfativas'] ?? {};
        String salida = (notasBD['salida'] ?? '').toString();
        String corazon = (notasBD['corazon'] ?? '').toString();
        String fondo = (notasBD['fondo'] ?? '').toString();
        String todasLasNotas = _limpiarTexto("$salida $corazon $fondo");

        bool hayCoincidencia = false;

        for (var notaIA in notasIA) {
          String notaBuscada = _limpiarTexto(notaIA.toString());
          List<String> palabrasClave = [notaBuscada];
          
          if (notaBuscada.contains('amaderad') || notaBuscada.contains('madera')) {
            palabrasClave.addAll(['madera', 'oud', 'cedro', 'sandalo', 'vetiver', 'pino', 'amberwood']);
          } else if (notaBuscada.contains('citric') || notaBuscada.contains('fresco')) {
            palabrasClave.addAll(['limon', 'naranja', 'bergamota', 'mandarina', 'pomelo']);
          } else if (notaBuscada.contains('dulce')) {
            palabrasClave.addAll(['vainilla', 'caramelo', 'chocolate', 'tonka', 'praline', 'coco']);
          } else if (notaBuscada.contains('floral')) {
            palabrasClave.addAll(['rosa', 'jazmin', 'iris', 'lavanda', 'violeta', 'orquidea']);
          }

          for (String palabra in palabrasClave) {
            if (palabra.length > 2 && todasLasNotas.contains(palabra)) {
              hayCoincidencia = true;
              break; 
            }
          }
          if (hayCoincidencia) break; 
        }

        if (hayCoincidencia) {
          resultadosEncontrados.add({
            'id': doc.id,
            'nombre': data['nombre'] ?? 'Perfume',
            'marca': data['marca'] ?? 'Desconocida',
            'precio': data['precio'] ?? 0,
            'imagen_url': data['imagen_url'] ?? '', 
          });
        }
      }
    } catch (_) {
      // Silencio total en caso de error
    }
    
    return resultadosEncontrados;
  }
}