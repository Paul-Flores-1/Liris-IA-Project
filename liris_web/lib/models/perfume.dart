import 'package:cloud_firestore/cloud_firestore.dart';

class Perfume {
  final String id;
  final String nombre;
  final String marca;
  final double precio;
  final String tipo;
  final String clima;
  final Map<String, dynamic> notas;
  final String imagenUrl;
  
  final String sexo;
  final String tamano; // Sin 'ñ'

  Perfume({
    required this.id,
    required this.nombre,
    required this.marca,
    required this.precio,
    required this.tipo,
    required this.clima,
    required this.notas,
    required this.imagenUrl,
    required this.sexo,
    required this.tamano,
  });

  factory Perfume.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    String capitalize(String s) {
      if (s.isEmpty) return s;
      return s[0].toUpperCase() + s.substring(1).toLowerCase();
    }

    return Perfume(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      marca: data['marca'] ?? '',
      precio: (data['precio'] as num?)?.toDouble() ?? 0.0,
      tipo: data['tipo'] ?? '',
      clima: data['clima_ideal'] ?? '',
      notas: data['notas'] != null ? Map<String, dynamic>.from(data['notas']) : {},
      imagenUrl: data['imagen_url'] ?? '',
      sexo: capitalize(data['sexo'] ?? 'Unisex'),
      
      tamano: data['tamaño']?.toString() ?? '100ml',
    );
  }
}