import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/perfume.dart';

class FavoritesProvider extends ChangeNotifier {
  String? _userId;
  final List<Perfume> _favorites = [];
  var _subscription;

  FavoritesProvider(this._userId) {
    if (_userId != null) {
      _listenToFavorites();
    }
  }

  List<Perfume> get favorites => _favorites;

  // --- REFERENCIA A LA BASE DE DATOS ---
  CollectionReference get _userFavoritesCollection {
    if (_userId == null) {
      throw Exception("No hay usuario autenticado");
    }
   
    return FirebaseFirestore.instance
        .collection('usuarios') 
        .doc(_userId!)
        .collection('favoritos'); 
  }

  // --- ACTUALIZAR USUARIO (LOGIN/LOGOUT) ---
  void updateUser(String? newUserId) {
    if (_userId != newUserId) {
      _subscription?.cancel();
      _userId = newUserId;
      _favorites.clear();
      
      if (newUserId != null) {
        _listenToFavorites();
      }
      notifyListeners();
    }
  }

  // --- LECTURA EN TIEMPO REAL (OPTIMIZADA) ---
  void _listenToFavorites() {
    if (_userId == null) return;

    _subscription = _userFavoritesCollection.snapshots().listen((snapshot) {
      _favorites.clear();
      
      // ¡AQUÍ ESTÁ EL TRUCO! 
      // Como guardamos todos los datos, los leemos directamente.
      // Ya no hace falta la segunda consulta con 'whereIn'.
      for (var doc in snapshot.docs) {
        try {
          _favorites.add(Perfume.fromFirestore(doc));
        } catch (e) {
          debugPrint("Error al procesar favorito ${doc.id}: $e");
        }
      }

      notifyListeners();
    }, onError: (error) {
      debugPrint("Error al escuchar favoritos: $error");
    });
  }

  // --- AÑADIR FAVORITO (GUARDANDO DATOS) ---
  Future<void> addFavorite(Perfume perfume) async {
    if (_userId == null) return;
    
    // Evitar duplicados visuales rápidos
    if (_favorites.any((fav) => fav.id == perfume.id)) return;

    try {
      // Guardamos TODOS los datos del perfume en la subcolección
      await _userFavoritesCollection.doc(perfume.id).set({
        'id': perfume.id,
        'nombre': perfume.nombre,
        'marca': perfume.marca,
        'precio': perfume.precio,
        'tipo': perfume.tipo,
        'clima_ideal': perfume.clima,
        'notas': perfume.notas,
        'imagen_url': perfume.imagenUrl, // Asegúrate que coincida con tu modelo
        'sexo': perfume.sexo,
        'tamano': perfume.tamano, // Sin ñ
        'timestamp': FieldValue.serverTimestamp(), // Para ordenar si quisieras
      });
    } catch (e) {
      debugPrint("Error al añadir favorito: $e");
    }
  }

  // --- ELIMINAR FAVORITO ---
  Future<void> removeFavorite(String perfumeId) async {
    if (_userId == null) return;

    try {
      await _userFavoritesCollection.doc(perfumeId).delete();
    } catch (e) {
      debugPrint("Error al eliminar favorito: $e");
    }
  }

  bool isFavorite(String perfumeId) {
    return _favorites.any((perfume) => perfume.id == perfumeId);
  }
  
  // --- BORRAR TODOS LOS FAVORITOS ---
  Future<void> clearFavorites() async {
    if (_userId == null) return;

    try {
      // 1. Obtenemos todos los documentos de la colección
      final snapshot = await _userFavoritesCollection.get();
      
      // 2. Usamos un "Batch" para borrarlos todos de una vez (es más eficiente)
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // 3. Ejecutamos el borrado
      await batch.commit();
      
      
    } catch (e) {
      debugPrint("Error al limpiar favoritos: $e");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}