import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // Necesario para el efecto de barra flotante translúcida

// Imports de vistas
import 'micuenta.dart';
import 'detalles.dart';
import 'favoritos.dart';
import 'liris.dart';
import 'sobrenosotros.dart';
import 'contacto.dart';

// Imports de modelos y providers
import '../models/perfume.dart';
import '../providers/favorites_provider.dart';

class CatalogoView extends StatefulWidget {
  const CatalogoView({super.key});

  @override
  State<CatalogoView> createState() => _CatalogoViewState();
}

class _CatalogoViewState extends State<CatalogoView> {
  // --- VARIABLES DE ESTADO ---
  int _selectedIndex = 0; 
  final TextEditingController _searchController = TextEditingController();
  
  // Lista de marcas para los botones horizontales
  final List<String> _marcas = [
    'Todas', 'Afnan', 'Ariana Grande', 'Armaf', 'Calvin Klein', 
    'Carolina Herrera', 'Dior', 'Dolce Gabbana', 'Jean Paul Gaultier', 
    'Lancome', 'Paco Rabanne', 'Valentino', 'Versace', 'YSL'
  ];
  String _selectedMarca = 'Todas';

  // Colores de la paleta premium
  final Color colorDorado = const Color(0xFFD9AD00);
  final Color colorSuperficie = const Color(0xFF252525);
  final Color colorFondoImagen = const Color(0xFF333333);
  final Color colorFondo = const Color(0xFF121212); 

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- NAVEGACIÓN INFERIOR ---
  void _onItemTapped(int index) {
    if (index == 3) {
      _mostrarMenuMas(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // --- SOLUCIÓN 1: Menú "Más" Anti-Congelamientos ---
  void _mostrarMenuMas(BuildContext context) {
    showModalBottomSheet<int>(
      context: context,
      backgroundColor: colorSuperficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4, 
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))
              ),
              const SizedBox(height: 20),
              
              ListTile(
                leading: Icon(Icons.person_outline, color: colorDorado),
                title: const Text('Mi Cuenta', style: TextStyle(color: Colors.white, fontSize: 16)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                onTap: () => Navigator.pop(ctx, 1), // Solo cierra y devuelve un número
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: colorDorado),
                title: const Text('Sobre Nosotros', style: TextStyle(color: Colors.white, fontSize: 16)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                onTap: () => Navigator.pop(ctx, 2), 
              ),
              ListTile(
                leading: Icon(Icons.mail_outline, color: colorDorado),
                title: const Text('Contacto', style: TextStyle(color: Colors.white, fontSize: 16)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                onTap: () => Navigator.pop(ctx, 3), 
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    ).then((opcionSeleccionada) {
      // MAGIA: Ejecuta el cambio de pantalla solo cuando la animación del panel ya terminó
      if (opcionSeleccionada == null) return; 

      if (opcionSeleccionada == 1) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MiCuentaView()));
      } else if (opcionSeleccionada == 2) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SobreNosotrosView()));
      } else if (opcionSeleccionada == 3) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactView()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      // extendBody permite que el contenido del catálogo pase por debajo de la barra flotante
      extendBody: true, 
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildCatalogoContent(), 
          const FavoritosView(),   
          const LirisView(),       
        ],
      ),
      // --- BARRA FLOTANTE ESTILO ISLA ---
      bottomNavigationBar: _buildFloatingBottomNav(),
    );
  }

  // --- DISEÑO DE BARRA FLOTANTE (GLASSMORPHISM) ---
  Widget _buildFloatingBottomNav() {
    return Padding(
      // Márgenes para separarla de los bordes del dispositivo
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30), // Bordes súper redondeados
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Efecto de vidrio desenfocado
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              // Color de superficie translúcido
              color: colorSuperficie.withAlpha(200), 
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withAlpha(25), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Inicio'),
                _buildNavItem(1, Icons.favorite_outline, Icons.favorite, 'Favoritos'),
                _buildNavItem(2, Icons.auto_awesome_outlined, Icons.auto_awesome, 'Liris'),
                _buildNavItem(3, Icons.menu_rounded, Icons.menu_rounded, 'Más'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey<bool>(isSelected),
                color: isSelected ? colorDorado : Colors.white.withAlpha(150),
                size: isSelected ? 28 : 24, // El ícono crece sutilmente al ser seleccionado
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colorDorado : Colors.white.withAlpha(150),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- CONTENIDO PRINCIPAL DEL CATÁLOGO ---
  Widget _buildCatalogoContent() {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // --- HEADER STICKY ---
          SliverAppBar(
            expandedHeight: 100.0,
            floating: true,
            pinned: true,
            backgroundColor: colorFondo,
            elevation: 0,
            title: _buildSearchBar(),
            titleSpacing: 16,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorDorado.withAlpha(20),
                  border: Border(bottom: BorderSide(color: colorDorado.withAlpha(50), width: 1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: colorDorado, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Enviar a Acapulco, Guerrero",
                      style: TextStyle(color: colorDorado, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Icon(Icons.keyboard_arrow_right, color: colorDorado, size: 16),
                  ],
                ),
              ),
            ),
          ),

          // --- BOTONES DESLIZABLES DE MARCAS ---
          SliverToBoxAdapter(
            child: Container(
              height: 50,
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _marcas.length,
                itemBuilder: (context, index) {
                  final marca = _marcas[index];
                  final isSelected = _selectedMarca == marca;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(marca),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedMarca = selected ? marca : 'Todas';
                        });
                      },
                      selectedColor: colorDorado.withAlpha(50),
                      backgroundColor: colorSuperficie,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: isSelected ? colorDorado : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(color: isSelected ? colorDorado : Colors.white12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  );
                },
              ),
            ),
          ),

          // --- BANNER PROMOCIONAL ---
          if (_searchController.text.isEmpty && _selectedMarca == 'Todas')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [colorDorado.withAlpha(200), const Color(0xFFB38B00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: colorDorado.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("NUEVA COLECCIÓN", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                              SizedBox(height: 4),
                              Text("Descubre tu\nfirma personal", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18, height: 1.1)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Icon(Icons.auto_awesome, color: Colors.white.withAlpha(150), size: 60),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // --- GRILLA DE PRODUCTOS ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('productos').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SliverToBoxAdapter(child: Center(child: Text("Error al cargar datos", style: TextStyle(color: Colors.white))));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: colorDorado),
                    )
                  )
                );
              }

              List<Perfume> perfumes = snapshot.data!.docs.map((doc) => Perfume.fromFirestore(doc)).toList();
              
              if (_selectedMarca != 'Todas') {
                final queryMarca = _selectedMarca.toLowerCase();
                perfumes = perfumes.where((p) => p.marca.toLowerCase().contains(queryMarca)).toList();
              }

              if (_searchController.text.isNotEmpty) {
                final query = _searchController.text.toLowerCase();
                perfumes = perfumes.where((p) => 
                  p.nombre.toLowerCase().contains(query) || 
                  p.marca.toLowerCase().contains(query)
                ).toList();
              }

              if (perfumes.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(60.0),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.white.withAlpha(100)),
                        const SizedBox(height: 16),
                        const Text("No encontramos fragancias", style: TextStyle(color: Colors.white54, fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220, 
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.55, 
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ProductCardEcommerce(
                      perfume: perfumes[index], 
                      colorDorado: colorDorado,
                      colorSuperficie: colorSuperficie,
                      colorFondoImagen: colorFondoImagen,
                    ),
                    childCount: perfumes.length,
                  ),
                ),
              );
            },
          ),
          
          // Ampliamos el espacio inferior para que la última tarjeta no quede detrás de la barra flotante
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: colorSuperficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: (v) => setState(() {}),
        decoration: InputDecoration(
          hintText: "Buscar marcas, perfumes...",
          hintStyle: TextStyle(color: Colors.white.withAlpha(120), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.cancel, size: 18, color: Colors.white54), 
                onPressed: () { _searchController.clear(); setState(() {}); }
              ) 
            : null,
        ),
      ),
    );
  }
}

// --- TARJETA DE PRODUCTO E-COMMERCE ---
class _ProductCardEcommerce extends StatelessWidget {
  final Perfume perfume;
  final Color colorDorado;
  final Color colorSuperficie;
  final Color colorFondoImagen;
  static final NumberFormat currencyFormat = NumberFormat('#,##0', 'es_MX');

  const _ProductCardEcommerce({
    required this.perfume, 
    required this.colorDorado,
    required this.colorSuperficie,
    required this.colorFondoImagen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetallesView(perfume: perfume))),
      child: Container(
        decoration: BoxDecoration(
          color: colorSuperficie,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: colorFondoImagen, 
                    padding: const EdgeInsets.all(16),
                    child: Hero(
                      tag: perfume.id,
                      child: perfume.imagenUrl.isNotEmpty
                          ? Image.network(
                              perfume.imagenUrl, 
                              fit: BoxFit.contain,
                              cacheHeight: 300, 
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: colorDorado,
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.broken_image, color: Colors.white24, size: 40),
                            )
                          : const Icon(Icons.image_not_supported, color: Colors.white24, size: 40),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<FavoritesProvider>(
                      builder: (context, provider, _) {
                        final isFav = provider.isFavorite(perfume.id);
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(100),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.redAccent : Colors.white,
                            size: 18,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Textos
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perfume.marca.toUpperCase(), 
                          style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 10, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          perfume.nombre, 
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w400, height: 1.2),
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "\$${currencyFormat.format(perfume.precio)}", 
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Envío gratis", 
                          style: TextStyle(color: Color(0xFF00A650), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}