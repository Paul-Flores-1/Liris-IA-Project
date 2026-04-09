import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; // Para el ImageFilter del Blur
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../models/perfume.dart';
import '../providers/favorites_provider.dart';

class DetallesView extends StatefulWidget {
  final Perfume perfume;
  const DetallesView({super.key, required this.perfume});

  @override
  State<DetallesView> createState() => _DetallesViewState();
}

class _DetallesViewState extends State<DetallesView> {
  bool _estaPagando = false;

  // --- COLORES BASE PARA EL TEMA PREMIUM ---
  final Color colorFondo = const Color(0xFF121212);
  final Color colorDorado = const Color(0xFFD9AD00);
  final Color colorAcento = const Color(0xFF2A2A2A);

  // --- MÉTODO DE PAGO (Mantenido igual) ---
  Future<void> _iniciarPago() async {
    setState(() {
      _estaPagando = true;
    });

    try {
      debugPrint('🚀 Iniciando proceso de Mercado Pago...');
      
      const String functionUrl = 'https://liris-ia-predict-604609230277.us-central1.run.app/crear-pago';
      
      final requestBody = {
        'title': widget.perfume.nombre,
        'unit_price': widget.perfume.precio,
        'quantity': 1,
        'currency_id': 'MXN',
        'email': 'test_user_123@test.com' 
      };
      
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final String checkoutUrl = data['init_point'] ?? data['checkout_url'];
        
        if (checkoutUrl.isNotEmpty) {
          final uri = Uri.parse(checkoutUrl);
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            _mostrarDialogoLink(checkoutUrl, uri);
          }
        } else {
          throw Exception('URL de pago no encontrada');
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
      
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (mounted) {
        _mostrarError("No se pudo iniciar el pago. Intenta de nuevo.", Colors.redAccent);
      }
    } finally {
      if (mounted) {
        setState(() {
          _estaPagando = false;
        });
      }
    }
  }

  void _mostrarDialogoLink(String checkoutUrl, Uri uri) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorAcento,
        title: Row(
          children: [
            Icon(Icons.payment, color: colorDorado),
            const SizedBox(width: 12),
            const Text('Completar Pago', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Abre este enlace para completar tu compra:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            SelectableText(checkoutUrl, style: TextStyle(color: colorDorado)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorDorado, foregroundColor: Colors.black),
            onPressed: () async {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Abrir Link'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color),
    );
  }

  // --- WIDGETS REDISEÑADOS ---

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10), // Translúcido
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(20)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildImageHeader(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return SizedBox(
      height: screenHeight * 0.55,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Imagen de fondo difuminada para ambientar (Efecto Halo)
          if (widget.perfume.imagenUrl.isNotEmpty)
            Opacity(
              opacity: 0.3,
              child: Image.network(
                widget.perfume.imagenUrl,
                fit: BoxFit.cover,
              ),
            ),
          if (widget.perfume.imagenUrl.isNotEmpty)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: colorFondo.withAlpha(150)),
            ),

          // 2. Imagen Principal del Perfume
          Hero(
            tag: widget.perfume.id,
            child: Padding(
              padding: const EdgeInsets.only(top: 80, bottom: 40),
              child: widget.perfume.imagenUrl.isNotEmpty
                  ? Image.network(
                      widget.perfume.imagenUrl,
                      fit: BoxFit.contain,
                    )
                  : const Center(child: Icon(Icons.image_not_supported, size: 80, color: Colors.white24)),
            ),
          ),

          // 3. Degradado inferior para transición suave al contenido
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, colorFondo],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsContent(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MARCA Y NOMBRE
          Center(
            child: Text(
              widget.perfume.marca.toUpperCase(),
              style: TextStyle(
                color: colorDorado,
                letterSpacing: 2.0,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              widget.perfume.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // PRECIO
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currencyFormat.format(widget.perfume.precio),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(top: 6.0),
                  child: Text(
                    "MXN",
                    style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold), 
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // TARJETA DE ESPECIFICACIONES (Glassmorphism)
          _buildGlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoItem(Icons.person_outline, "Para", widget.perfume.sexo),
                Container(height: 40, width: 1, color: Colors.white12), // Divisor
                _buildInfoItem(Icons.water_drop_outlined, "Tamaño", "${widget.perfume.ml} ml"),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // NOTAS OLFATIVAS
          const Text(
            "PIRÁMIDE OLFATIVA",
            style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          _buildNotesSection(widget.perfume.notasOlfativas),

          const SizedBox(height: 32),

          // ENVÍO
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorDorado.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorDorado.withAlpha(30)),
            ),
            child: Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: colorDorado, size: 24),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Envío estándar gratuito.\nDisponible solo en Acapulco.",
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // BOTÓN DE COMPRA
          SizedBox(
            width: double.infinity,
            child: _estaPagando
                ? Center(child: CircularProgressIndicator(color: colorDorado))
                : ElevatedButton(
                    onPressed: _iniciarPago,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorDorado,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      elevation: 10,
                      shadowColor: colorDorado.withAlpha(100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 22),
                        SizedBox(width: 12),
                        Text(
                          "COMPRAR AHORA",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- HELPERS PARA LA UI ---
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: colorDorado, size: 28),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.0),
        ),
        const SizedBox(height: 4),
        Text(
          value.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildNotesSection(Map<String, dynamic>? notes) {
    if (notes == null || notes.isEmpty) {
      return const Text("No hay información de notas.", style: TextStyle(color: Colors.white54));
    }

    return Column(
      children: notes.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorAcento,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForNoteType(entry.key), 
                  color: colorDorado, 
                  size: 18
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconForNoteType(String type) {
    final t = type.toLowerCase();
    if (t.contains('salida')) return Icons.air;
    if (t.contains('corazon') || t.contains('corazón')) return Icons.favorite_border;
    if (t.contains('fondo')) return Icons.spa_outlined;
    return Icons.auto_awesome;
  }

  // --- APPBAR TRANSPARENTE ---
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(100),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Consumer<FavoritesProvider>(
          builder: (context, favoritesProvider, child) {
            final isFavorite = favoritesProvider.isFavorite(widget.perfume.id);
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : Colors.white,
                    size: 22,
                  ),
                  onPressed: () async {
                    if (isFavorite) {
                      await favoritesProvider.removeFavorite(widget.perfume.id);
                    } else {
                      await favoritesProvider.addFavorite(widget.perfume);
                    }
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildImageHeader(context),
            _buildDetailsContent(context),
          ],
        ),
      ),
    );
  }
}