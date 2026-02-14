import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  // --- MÉTODO DE PAGO MEJORADO ---
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
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Row(
          children: [
            Icon(Icons.payment, color: Color(0xFFD9AD00)),
            SizedBox(width: 12),
            Text('Completar Pago'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Abre este enlace para completar tu compra:'),
            const SizedBox(height: 16),
            SelectableText(checkoutUrl, style: const TextStyle(color: Colors.blue)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              Navigator.pop(ctx);
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

  // --- NUEVO CONTENIDO DE DETALLES (SIN ACORDEÓN) ---
  Widget _buildDetailsContent(BuildContext context, Color colorTexto,
      Color colorDorado, Color colorGrisSuave, Color colorSuperficie) {
    
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MARCA
          Text(
            widget.perfume.marca.toUpperCase(),
            style: TextStyle(
              color: colorGrisSuave,
              letterSpacing: 1.5,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          // NOMBRE
          Text(
            widget.perfume.nombre,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: colorTexto,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          
          // PRECIO
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(widget.perfume.precio),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorDorado,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "MXN",
                style: TextStyle(color: colorGrisSuave.withAlpha(178), fontSize: 12, fontWeight: FontWeight.bold), 
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // --- FICHA TÉCNICA (GRID) ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorSuperficie.withAlpha(100),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(Icons.person_outline, "Para", widget.perfume.sexo, colorTexto, colorDorado),
                _buildVerticalDivider(),
                // Asumiendo que tamano es un String, si es int, usa .toString()
                _buildInfoItem(Icons.straighten, "Tamaño", widget.perfume.tamano, colorTexto, colorDorado),
                _buildVerticalDivider(),
                _buildInfoItem(Icons.wb_sunny_outlined, "Clima", widget.perfume.clima, colorTexto, colorDorado),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- NOTAS OLFATIVAS VISUALES ---
          Text(
            "NOTAS OLFATIVAS",
            style: TextStyle(color: colorGrisSuave, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          _buildNotesChips(widget.perfume.notas, colorSuperficie, colorTexto),

          const SizedBox(height: 32),

          // --- ENVÍO ---
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: colorDorado, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Envío estándar gratuito. Solo en Acapulco.",
                  style: TextStyle(color: colorTexto.withAlpha(200), fontSize: 13),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // --- BOTÓN DE COMPRA ---
          SizedBox(
            width: double.infinity,
            child: _estaPagando
                ? Center(child: CircularProgressIndicator(color: colorDorado))
                : ElevatedButton.icon(
                    onPressed: _iniciarPago,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text(
                      "COMPRAR AHORA",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorDorado,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS PARA LA NUEVA UI ---

  Widget _buildInfoItem(IconData icon, String label, String value, Color colorTexto, Color colorDorado) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: colorDorado, size: 24),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(color: colorTexto.withOpacity(0.5), fontSize: 10, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorTexto, fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: const Color.fromARGB(26, 36, 36, 36),
    );
  }

  Widget _buildNotesChips(Map<String, dynamic>? notes, Color colorSuperficie, Color colorTexto) {
    if (notes == null || notes.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: notes.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorSuperficie,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "${entry.key.toUpperCase()}: ",
                  style: TextStyle(color: colorTexto.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: entry.value.toString(),
                  style: TextStyle(color: colorTexto, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- IMAGEN OPTIMIZADA (NO SE CORTA) ---
  Widget _buildImageColumn(
      BuildContext context, Color colorSuperficie, Color colorFondo) {
    
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        Hero(
          tag: widget.perfume.id,
          child: Container(
            // Altura dinámica: 55% de la pantalla
            height: screenHeight * 0.55, 
            width: double.infinity,
            decoration: BoxDecoration(
              // CAMBIO AQUÍ: Se usa transparente en lugar de colorSuperficie
              color: Colors.transparent, 
              image: widget.perfume.imagenUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.perfume.imagenUrl),
                      fit: BoxFit.contain, // Muestra la botella completa
                    )
                  : null,
            ),
            child: widget.perfume.imagenUrl.isEmpty
                ? const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        size: 80, color: const Color(0xFF2A2A2A)))
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(0), 
                          colorFondo.withAlpha(0), 
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // --- BUILD PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    final colorFondo = Theme.of(context).scaffoldBackgroundColor;
    final colorSuperficie = Theme.of(context).cardTheme.color ?? const Color(0xFF2A2A2A);
    final colorTexto = Theme.of(context).colorScheme.onSurface;
    final colorDorado = const Color(0xFFD9AD00);
    final colorGrisSuave = colorTexto.withAlpha(153);

    return Scaffold(
      backgroundColor: colorFondo,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: colorFondo.withAlpha(180),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, child) {
              final isFavorite = favoritesProvider.isFavorite(widget.perfume.id);

              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.redAccent : Colors.white,
                  size: 28,
                ),
                onPressed: () async {
                  if (isFavorite) {
                    await favoritesProvider.removeFavorite(widget.perfume.id);
                  } else {
                    await favoritesProvider.addFavorite(widget.perfume);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFavorite ? "Eliminado de favoritos" : "Añadido a favoritos",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: colorDorado,
                        duration: const Duration(milliseconds: 1500),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isWideScreen = constraints.maxWidth > 900;
              
              if (isWideScreen) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16.0,
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildImageColumn(context, colorSuperficie, colorFondo),
                        ),
                        Expanded(
                          flex: 1,
                          child: _buildDetailsContent(context, colorTexto,
                              colorDorado, colorGrisSuave, colorSuperficie),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return SafeArea(
                  top: false, 
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        _buildImageColumn(context, colorSuperficie, colorFondo),
                        _buildDetailsContent(context, colorTexto, colorDorado,
                            colorGrisSuave, colorSuperficie),
                        const SizedBox(height: 40), 
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}