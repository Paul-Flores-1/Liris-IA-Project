import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Imports de vistas
import 'micuenta.dart';
import 'detalles.dart';
import 'favoritos.dart';
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

class _CatalogoViewState extends State<CatalogoView> with TickerProviderStateMixin {
  // Filtros
  String? _marcaSeleccionada;
  String? _tipoSeleccionado;
  String? _sexoSeleccionado;
  String? _climaSeleccionado;
  
  // Ordenamiento
  String _ordenamiento = 'nombre';
  
  // Búsqueda
  final TextEditingController _searchController = TextEditingController();
  
  bool _mostrarFiltros = false;
  
  // Animaciones
  late AnimationController _headerAnimationController;
  late Animation<double> _headerFadeAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _headerFadeAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutQuart,
    );
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _searchController.dispose(); // Limpieza del controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color appBarColor = Theme.of(context).appBarTheme.backgroundColor ?? Colors.black;
    final Color colorDorado = const Color(0xFFD9AD00);
    final Color colorSuperficie = Theme.of(context).cardTheme.color ?? const Color(0xFF2A2A2A);
    final Color colorFondo = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: colorFondo,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        cacheExtent: 1000,
        slivers: [
          // --- HEADER CON FADE Y BUSCADOR ---
          SliverAppBar(
            expandedHeight: 280.0, // Altura ajustada para el buscador
            floating: false,
            pinned: true,
            backgroundColor: appBarColor,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: FadeTransition(
                opacity: _headerFadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- Fila Superior: Menús y Logo ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // --- Menú Izquierdo ---
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _HoverTextButton(
                                title: 'Sobre nosotros',
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SobreNosotrosView()),
                                ),
                              ),
                              const SizedBox(width: 16),
                              _HoverTextButton(
                                title: 'Favoritos',
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const FavoritosView()),
                                ),
                              ),
                            ],
                          ),
            
                          // --- Logo Central ---
                          Expanded(
                            child: Center(
                              child: Image.asset(
                                'assets/images/logo_paul_floress.png',
                                height: 160,
                                fit: BoxFit.contain,
                                cacheWidth: 400,
                              ),
                            ),
                          ),
            
                          // --- Menú Derecho ---
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _HoverTextButton(
                                title: 'Mi Cuenta',
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MiCuentaView()),
                                ),
                              ),
                              const SizedBox(width: 16),
                              _HoverTextButton(
                                title: 'Contacto',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ContactView()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),

                      // --- Barra de Búsqueda ---
                      _buildSearchBar(colorDorado, colorSuperficie),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- PANEL DE FILTROS ---
          SliverToBoxAdapter(
            child: _buildFiltrosPanel(colorDorado, colorSuperficie),
          ),

          // --- CATÁLOGO DE PERFUMES ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('perfumes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(child: _buildErrorState());
                }
                if (snapshot.connectionState == ConnectionState.waiting && _cachedPerfumes == null) {
                  return SliverToBoxAdapter(child: _buildLoadingState(colorDorado));
                }

                List<Perfume> perfumes;
                if (snapshot.hasData) {
                  perfumes = snapshot.data!.docs.map((doc) => Perfume.fromFirestore(doc)).toList();
                  _cachedPerfumes = perfumes;
                } else {
                  perfumes = _cachedPerfumes ?? [];
                }

                // 1. Filtrado por Búsqueda (Texto)
                if (_searchController.text.isNotEmpty) {
                  final query = _searchController.text.toLowerCase();
                  perfumes = perfumes.where((p) {
                    return p.nombre.toLowerCase().contains(query) || 
                           p.marca.toLowerCase().contains(query);
                  }).toList();
                }

                // 2. Filtros de Categoría
                perfumes = _aplicarFiltros(perfumes);
                
                // 3. Ordenamiento
                perfumes = _aplicarOrdenamiento(perfumes);

                if (perfumes.isEmpty) {
                  return SliverToBoxAdapter(child: _buildEmptyState(colorDorado));
                }

                // Lógica de visualización
                final bool isSearching = _searchController.text.isNotEmpty;

                if (_cachedDestacados == null || _cachedResto == null || isSearching) {
                  if (isSearching) {
                    // Si está buscando, mostramos todo junto sin secciones
                    return SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 20),
                        _OptimizedGrid(
                          perfumes: perfumes,
                          esDestacado: false,
                        ),
                      ]),
                    );
                  }

                  // Si no busca, armamos las secciones
                  final perfumesDestacados = List<Perfume>.from(perfumes)
                    ..sort((a, b) => b.precio.compareTo(a.precio));
                  _cachedDestacados = perfumesDestacados.take(6).toList();
                  
                  _cachedResto = List<Perfume>.from(perfumes);
                  _cachedResto!.shuffle();
                }

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Sección destacados
                    _buildSeccionHeader(
                      'Mejor Valorados',
                      'Las fragancias más exclusivas',
                      colorDorado,
                      Icons.star_rounded,
                    ),
                    const SizedBox(height: 20),
                    _OptimizedGrid(
                      perfumes: _cachedDestacados!,
                      esDestacado: true,
                    ),

                    // Sección explorar
                    _buildSeccionHeader(
                      'Explora Nuestra Colección',
                      'Descubre tu fragancia perfecta',
                      colorDorado,
                      Icons.grid_view_rounded,
                    ),
                    const SizedBox(height: 20),
                    _OptimizedGrid(
                      perfumes: _cachedResto!,
                      esDestacado: false,
                    ),
                  ]),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // Cache para evitar reconstrucciones innecesarias
  List<Perfume>? _cachedPerfumes;
  List<Perfume>? _cachedDestacados;
  List<Perfume>? _cachedResto;

  // --- WIDGET BARRA DE BÚSQUEDA CORREGIDO ---
  Widget _buildSearchBar(Color colorDorado, Color colorSuperficie) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      margin: const EdgeInsets.only(top: 0, bottom: 10),
      // Material widget maneja el recorte y elevación correctamente
      child: Material(
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        color: colorSuperficie, 
        borderRadius: BorderRadius.circular(30),
        clipBehavior: Clip.antiAlias, // <--- ESTO CORRIGE LAS ESQUINAS
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: colorDorado.withValues(alpha: 0.5),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            cursorColor: colorDorado,
            onChanged: (value) {
              setState(() {
                _limpiarCache();
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent, // Transparente para ver el Material
              hintText: 'Buscar perfume o marca...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
              prefixIcon: Icon(Icons.search, color: colorDorado),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _limpiarCache();
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltrosPanel(Color colorDorado, Color colorSuperficie) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colorSuperficie,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: colorDorado.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: colorDorado.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _mostrarFiltros = !_mostrarFiltros;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorDorado.withValues(alpha: 0.1), Colors.transparent],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorDorado.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.tune, color: colorDorado, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Filtros y Ordenamiento',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _mostrarFiltros ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      Icons.expand_more,
                      color: colorDorado,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
            child: _mostrarFiltros
                ? _buildFiltrosExpandidos(colorDorado)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosExpandidos(Color colorDorado) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('perfumes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
          }

          final perfumes = snapshot.data!.docs.map((doc) => Perfume.fromFirestore(doc)).toList();
          final marcas = perfumes.map((p) => p.marca).toSet().toList()..sort();
          final tipos = perfumes.map((p) => p.tipo).toSet().toList()..sort();
          final sexos = perfumes.map((p) => p.sexo).toSet().toList()..sort();
          final climas = perfumes.map((p) => p.clima).toSet().toList()..sort();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                childAspectRatio: 3.2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _buildModernFilterDropdown('Marca', _marcaSeleccionada, ['Todas', ...marcas], 
                    (value) => setState(() { _marcaSeleccionada = value == 'Todas' ? null : value; _limpiarCache(); }), colorDorado, Icons.label_outline),
                  _buildModernFilterDropdown('Tipo', _tipoSeleccionado, ['Todos', ...tipos], 
                    (value) => setState(() { _tipoSeleccionado = value == 'Todos' ? null : value; _limpiarCache(); }), colorDorado, Icons.category_outlined),
                  _buildModernFilterDropdown('Para', _sexoSeleccionado, ['Todos', ...sexos], 
                    (value) => setState(() { _sexoSeleccionado = value == 'Todos' ? null : value; _limpiarCache(); }), colorDorado, Icons.person_outline),
                  _buildModernFilterDropdown('Clima', _climaSeleccionado, ['Todos', ...climas], 
                    (value) => setState(() { _climaSeleccionado = value == 'Todos' ? null : value; _limpiarCache(); }), colorDorado, Icons.wb_sunny_outlined),
                ],
              ),
              
              const SizedBox(height: 8),
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 16),
              
              Row(
                children: [
                  Text('Ordenar:', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildModernSortChip('Nombre', 'nombre', colorDorado, Icons.sort_by_alpha),
                        _buildModernSortChip('Precio ↑', 'precio_asc', colorDorado, Icons.arrow_upward),
                        _buildModernSortChip('Precio ↓', 'precio_desc', colorDorado, Icons.arrow_downward),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _marcaSeleccionada = null; _tipoSeleccionado = null;
                        _sexoSeleccionado = null; _climaSeleccionado = null;
                        _ordenamiento = 'nombre'; _limpiarCache();
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Limpiar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _limpiarCache() {
    _cachedDestacados = null;
    _cachedResto = null;
  }

  Widget _buildModernFilterDropdown(String label, String? value, List<String> options, Function(String?) onChanged, Color colorDorado, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value != null ? colorDorado.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isDense: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: value != null ? colorDorado : Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500, fontSize: 12),
          prefixIcon: Icon(icon, color: value != null ? colorDorado : Colors.white.withValues(alpha: 0.6), size: 16),
          prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        dropdownColor: const Color(0xFF2A2A2A),
        style: const TextStyle(color: Colors.white, fontSize: 12),
        icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.5), size: 20),
        items: options.map((option) => DropdownMenuItem(value: option == 'Todas' || option == 'Todos' ? null : option, child: Text(option))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildModernSortChip(String label, String value, Color colorDorado, IconData icon) {
    final isSelected = _ordenamiento == value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ActionChip(
        label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: isSelected ? Colors.black : Colors.white), const SizedBox(width: 4), Text(label)]),
        onPressed: () { setState(() { _ordenamiento = value; _limpiarCache(); }); },
        backgroundColor: isSelected ? colorDorado : Colors.black.withValues(alpha: 0.2),
        side: BorderSide(color: isSelected ? colorDorado : Colors.white.withValues(alpha: 0.2), width: 1),
        labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 11),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        labelPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSeccionHeader(String titulo, String subtitulo, Color colorDorado, IconData icono) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorDorado.withValues(alpha: 0.1), Colors.transparent]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorDorado.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colorDorado.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(icono, color: colorDorado, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
                const SizedBox(height: 2),
                Text(subtitulo, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Color colorDorado) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60.0),
        child: Column(
          children: [
            CircularProgressIndicator(color: colorDorado, strokeWidth: 3),
            const SizedBox(height: 24),
            Text('Cargando fragancias exclusivas...', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color colorDorado) {
    return Center(child: Padding(padding: const EdgeInsets.all(60.0), child: Column(children: [Icon(Icons.search_off, size: 100, color: colorDorado.withValues(alpha: 0.3)), const SizedBox(height: 24), const Text('No encontramos fragancias', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text('Intenta ajustar los filtros', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16))])));
  }

  Widget _buildErrorState() {
    return Center(child: Padding(padding: const EdgeInsets.all(60.0), child: Column(children: [Icon(Icons.error_outline, size: 100, color: Colors.redAccent.withValues(alpha: 0.6)), const SizedBox(height: 24), const Text('Error al cargar', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))])));
  }

  List<Perfume> _aplicarFiltros(List<Perfume> perfumes) {
    return perfumes.where((perfume) {
      if (_marcaSeleccionada != null && perfume.marca != _marcaSeleccionada) return false;
      if (_tipoSeleccionado != null && perfume.tipo != _tipoSeleccionado) return false;
      if (_sexoSeleccionado != null && perfume.sexo != _sexoSeleccionado) return false;
      if (_climaSeleccionado != null && perfume.clima != _climaSeleccionado) return false;
      return true;
    }).toList();
  }

  List<Perfume> _aplicarOrdenamiento(List<Perfume> perfumes) {
    switch (_ordenamiento) {
      case 'precio_asc': perfumes.sort((a, b) => a.precio.compareTo(b.precio)); break;
      case 'precio_desc': perfumes.sort((a, b) => b.precio.compareTo(a.precio)); break;
      case 'nombre': default: perfumes.sort((a, b) => a.nombre.compareTo(b.nombre));
    }
    return perfumes;
  }
}

// --- GRID OPTIMIZADO ---
class _OptimizedGrid extends StatelessWidget {
  final List<Perfume> perfumes;
  final bool esDestacado;

  const _OptimizedGrid({required this.perfumes, required this.esDestacado});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.62,
      ),
      itemCount: perfumes.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 500)), 
          curve: Curves.easeOutQuart,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _PerfumeCardElegante(
            perfume: perfumes[index],
            esDestacado: esDestacado,
          ),
        );
      },
    );
  }
}

// --- BOTÓN HOVER OPTIMIZADO ---
class _HoverTextButton extends StatefulWidget {
  final String title;
  final VoidCallback onPressed;

  const _HoverTextButton({required this.title, required this.onPressed});

  @override
  State<_HoverTextButton> createState() => _HoverTextButtonState();
}

class _HoverTextButtonState extends State<_HoverTextButton> {
  bool _isHovering = false;
  static const Color hoverColor = Color(0xFFD9AD00);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onPressed,
      onHover: (hovering) => setState(() => _isHovering = hovering),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: _isHovering ? hoverColor : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              child: Text(widget.title),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 2,
              width: _isHovering ? 40 : 0,
              color: hoverColor,
            ),
          ],
        ),
      ),
    );
  }
}

// --- TARJETA OPTIMIZADA ---
class _PerfumeCardElegante extends StatefulWidget {
  const _PerfumeCardElegante({required this.perfume, this.esDestacado = false});
  final Perfume perfume;
  final bool esDestacado;

  @override
  State<_PerfumeCardElegante> createState() => _PerfumeCardEleganteState();
}

class _PerfumeCardEleganteState extends State<_PerfumeCardElegante> {
  bool _isHovering = false;
  static const Color colorDorado = Color(0xFFD9AD00);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetallesView(perfume: widget.perfume)),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
          transform: Matrix4.identity()..scale(_isHovering ? 1.03 : 1.0),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isHovering ? colorDorado.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.3),
                blurRadius: _isHovering ? 30 : 10,
                offset: Offset(0, _isHovering ? 10 : 4),
              ),
            ],
            border: Border.all(
              color: _isHovering ? colorDorado.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: RepaintBoundary(
              child: _CardContent(perfume: widget.perfume, colorDorado: colorDorado),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.perfume,
    required this.colorDorado,
  });

  final Perfume perfume;
  final Color colorDorado;
  static final NumberFormat currencyFormat = NumberFormat('#,##0', 'es_MX');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: perfume.imagenUrl.isNotEmpty
                    ? Image.network(
                        perfume.imagenUrl,
                        fit: BoxFit.contain,                                             
                        cacheWidth: 350,
                        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return AnimatedOpacity(
                            opacity: frame == null ? 0 : 1,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            child: child,
                          );
                        },
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.white.withValues(alpha: 0.3)),
                        ),
                      )
                    : Center(child: Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.white.withValues(alpha: 0.3))),
              ),
              
              // Botón de favorito
              Positioned(
                top: 10,
                right: 10,
                child: Consumer<FavoritesProvider>(
                  builder: (context, provider, child) {
                    final isFavorite = provider.isFavorite(perfume.id);
                    return GestureDetector(
                      onTap: () {
                         if (isFavorite) {
                            provider.removeFavorite(perfume.id);
                          } else {
                            provider.addFavorite(perfume);
                          }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isFavorite ? Colors.redAccent : Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.redAccent : Colors.white,
                          size: 18,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Información
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfume.marca.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: colorDorado,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      perfume.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${currencyFormat.format(perfume.precio)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: colorDorado,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white.withValues(alpha: 0.3)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}