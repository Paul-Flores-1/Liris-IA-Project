import 'package:cloud_firestore/cloud_firestore.dart';

class Perfume {
  final String id;
  final String marca;
  final String nombre;
  final double precio;
  final String sexo;
  final String imagenUrl;
  final String ml; 
  final Map<String, dynamic> notasOlfativas;

  Perfume({
    required this.id,
    required this.marca,
    required this.nombre,
    required this.precio,
    required this.sexo,
    required this.imagenUrl,
    required this.ml,
    required this.notasOlfativas,
  });

  factory Perfume.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Perfume(
      id: doc.id,
      marca: data['marca'] ?? 'Desconocida',
      nombre: data['nombre'] ?? 'Sin nombre',
      precio: (data['precio'] ?? 0).toDouble(),
      sexo: data['sexo'] ?? 'Unisex',
      imagenUrl: data['imagen_url'] ?? '',
      // Convertimos el int de Firebase (ej. 100) a String para la UI
      ml: data['ml']?.toString() ?? '100', 
      notasOlfativas: data['notas_olfativas'] ?? {},
    );
  }
}