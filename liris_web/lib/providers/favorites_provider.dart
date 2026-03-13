import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Necesario para StreamSubscription

import '../models/perfume.dart';

class FavoritesProvider extends ChangeNotifier {
  String? _userId;
  final List<Perfume> _favorites = [];
  
  // Solución a la advertencia azul: Le damos un tipo explícito en lugar de "var"
  StreamSubscription<QuerySnapshot>? _subscription;

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
      // Guardamos los datos con la NUEVA estructura del modelo
      await _userFavoritesCollection.doc(perfume.id).set({
        'id': perfume.id,
        'nombre': perfume.nombre,
        'marca': perfume.marca,
        'precio': perfume.precio,
        'imagen_url': perfume.imagenUrl,
        'sexo': perfume.sexo,
        'ml': perfume.ml, // Campo nuevo
        'notas_olfativas': perfume.notasOlfativas, // Campo nuevo
        'timestamp': FieldValue.serverTimestamp(), 
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
      final snapshot = await _userFavoritesCollection.get();
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

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