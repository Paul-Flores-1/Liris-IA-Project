import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart'; 
import './detalles.dart';

// --- FUNCIÓN AUXILIAR PARA EVITAR WARNINGS ---
Color _colorWithOpacity(Color color, double opacity) {
  int alpha = (255 * opacity).round();
  return color.withAlpha(alpha); 
}

class FavoritosView extends StatelessWidget {
  const FavoritosView({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Configuración de Estilos ---
    final colorFondo = Theme.of(context).scaffoldBackgroundColor;
    final colorSuperficie = Theme.of(context).cardTheme.color ?? const Color(0xFF2A2A2A);
    final colorTexto = Theme.of(context).colorScheme.onSurface;
    final colorDorado = const Color(0xFFD9AD00);
    
    final colorGrisSuave = colorTexto.withAlpha(153); 

    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final favoritePerfumes = favoritesProvider.favorites;

    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: Text(
          'Mis Favoritos',
          style: TextStyle(
            color: colorTexto,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorFondo,
        elevation: 0,
        iconTheme: IconThemeData(color: colorTexto),
        actions: [
          if (favoritePerfumes.isNotEmpty) 
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: colorGrisSuave),
              tooltip: 'Vaciar favoritos',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: colorSuperficie,
                    title: Text('Vaciar Favoritos', style: TextStyle(color: colorTexto)),
                    content: Text('¿Estás seguro de que quieres eliminar todos los favoritos?', style: TextStyle(color: colorGrisSuave)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('Cancelar', style: TextStyle(color: colorTexto)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          favoritesProvider.clearFavorites();
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Favoritos vaciados correctamente.')),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text('Eliminar Todo', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: favoritePerfumes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: _colorWithOpacity(colorGrisSuave, 0.4), 
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '¡Aún no tienes favoritos!',
                    style: TextStyle(
                      color: colorGrisSuave,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Marca tus perfumes preferidos para verlos aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _colorWithOpacity(colorGrisSuave, 0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(), 
                    icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
                    label: const Text(
                      'Explorar Perfumes',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorDorado,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: favoritePerfumes.length,
              itemBuilder: (context, index) {
                final perfume = favoritePerfumes[index];
                final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$'); 

                return Dismissible(
                  key: ValueKey(perfume.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(153),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: colorSuperficie,
                        title: Text('Eliminar de Favoritos', style: TextStyle(color: colorTexto)),
                        content: Text('¿Estás seguro de que quieres eliminar "${perfume.nombre}"?', style: TextStyle(color: colorGrisSuave)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text('Cancelar', style: TextStyle(color: colorTexto)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    favoritesProvider.removeFavorite(perfume.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${perfume.nombre}" eliminado.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DetallesView(perfume: perfume),
                        ),
                      );
                    },
                    child: Card(
                      color: colorSuperficie,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.white12.withAlpha(51)),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Imagen del perfume
                            Hero(
                              tag: perfume.id,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: perfume.imagenUrl.isNotEmpty
                                    ? Image.network(
                                          perfume.imagenUrl,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[800],
                                              child: Icon(Icons.broken_image, color: colorGrisSuave),
                                            ),
                                        )
                                    : Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[800],
                                          child: Icon(Icons.image_not_supported, color: colorGrisSuave),
                                        ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Información del perfume
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    perfume.marca.toUpperCase(),
                                    style: TextStyle(
                                      color: colorGrisSuave,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.8,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    perfume.nombre,
                                    style: TextStyle(
                                      color: colorTexto,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currencyFormat.format(perfume.precio),
                                    style: TextStyle(
                                      color: colorDorado,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // --- BOTÓN DE ELIMINAR CORREGIDO ---
                            IconButton(
                              onPressed: () {
                                // Aquí llamamos directamente al provider para eliminar
                                favoritesProvider.removeFavorite(perfume.id);
                              },
                              icon: Icon(
                                Icons.favorite, 
                                color: Colors.redAccent.withAlpha(204), 
                                size: 28
                              ),
                              tooltip: 'Quitar de favoritos',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}