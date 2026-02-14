import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MiCuentaView extends StatefulWidget {
  const MiCuentaView({super.key});

  @override
  State<MiCuentaView> createState() => _MiCuentaViewState();
}

class _MiCuentaViewState extends State<MiCuentaView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _estaCargando = true;
  bool _estaGuardando = false;
  bool _modoEdicion = false; // ✨ NUEVA VARIABLE: Controla el modo de edición

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Controladores
  final _nombreController = TextEditingController();
  final _edadController = TextEditingController();
  final _emailController = TextEditingController();

  // Variables de estado actuales
  String? _selectedGenero;
  String? _selectedClima;
  List<String> _selectedOcasion = [];
  List<String> _selectedPreferencias = [];

  // Variables para guardar el estado original
  String _originalNombre = '';
  String _originalEdad = '';
  String? _originalGenero;
  String? _originalClima;
  List<String> _originalOcasion = [];
  List<String> _originalPreferencias = [];

  final List<String> _opcionesGenero = ['masculino', 'femenino', 'otro'];
  final List<String> _opcionesClima = ['cálido', 'templado', 'frío'];
  final List<String> _opcionesOcasion = [
    'diario',
    'escuela',
    'trabajo',
    'formal',
    'casual',
    'cita'
  ];
  final List<String> _opcionesPreferencias = [
    'cítrico',
    'dulce',
    'amaderado',
    'floral',
    'fresco'
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    
    // Animación para transiciones suaves
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _edadController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    final user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      try {
        final doc = await _firestore.collection('usuarios').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          
          _originalNombre = data['nombre'] ?? '';
          _originalEdad = data['edad']?.toString() ?? '';
          _originalGenero = data['genero'] == '' ? null : data['genero'];
          _originalClima = data['clima'] == '' ? null : data['clima'];
          _originalOcasion = List<String>.from(data['ocasion'] ?? []);
          _originalPreferencias = List<String>.from(data['preferencias'] ?? []);

          _nombreController.text = _originalNombre;
          _edadController.text = _originalEdad;
          _selectedGenero = _originalGenero;
          _selectedClima = _originalClima;
          _selectedOcasion = List.from(_originalOcasion);
          _selectedPreferencias = List.from(_originalPreferencias);
        }
      } catch (e) {
        _mostrarError("Error al cargar perfil: $e");
      }
    }
    if (mounted) {
      setState(() {
        _estaCargando = false;
      });
    }
  }

  bool _hayCambios() {
    bool listasIguales(List<String> a, List<String> b) {
      if (a.length != b.length) return false;
      final aSorted = List<String>.from(a)..sort();
      final bSorted = List<String>.from(b)..sort();
      for (int i = 0; i < aSorted.length; i++) {
        if (aSorted[i] != bSorted[i]) return false;
      }
      return true;
    }

    return _nombreController.text != _originalNombre ||
        _edadController.text != _originalEdad ||
        _selectedGenero != _originalGenero ||
        _selectedClima != _originalClima ||
        !listasIguales(_selectedOcasion, _originalOcasion) ||
        !listasIguales(_selectedPreferencias, _originalPreferencias);
  }

  // ✨ NUEVA FUNCIÓN: Alternar modo edición
  void _toggleModoEdicion() {
    setState(() {
      _modoEdicion = !_modoEdicion;
      
      // Si cancela la edición, restaurar valores originales
      if (!_modoEdicion && _hayCambios()) {
        _nombreController.text = _originalNombre;
        _edadController.text = _originalEdad;
        _selectedGenero = _originalGenero;
        _selectedClima = _originalClima;
        _selectedOcasion = List.from(_originalOcasion);
        _selectedPreferencias = List.from(_originalPreferencias);
      }
    });
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _estaGuardando = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('usuarios').doc(user.uid).update({
          'nombre': _nombreController.text.trim(),
          'edad': int.tryParse(_edadController.text.trim()),
          'genero': _selectedGenero ?? '',
          'clima': _selectedClima ?? '',
          'ocasion': _selectedOcasion,
          'preferencias': _selectedPreferencias,
        });

        _originalNombre = _nombreController.text.trim();
        _originalEdad = _edadController.text.trim();
        _originalGenero = _selectedGenero;
        _originalClima = _selectedClima;
        _originalOcasion = List.from(_selectedOcasion);
        _originalPreferencias = List.from(_selectedPreferencias);

        _mostrarExito("Perfil actualizado correctamente");
        
        // Salir del modo edición después de guardar
        setState(() {
          _modoEdicion = false;
        });
      }
    } catch (e) {
      _mostrarError("Error al guardar cambios: $e");
    }

    if (mounted) {
      setState(() {
        _estaGuardando = false;
      });
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorFondo = Theme.of(context).scaffoldBackgroundColor;
    final colorSuperficie =
        Theme.of(context).cardTheme.color ?? const Color(0xFF2A2A2A);
    final colorAcento = Theme.of(context).primaryColor;
    final colorDorado = const Color(0xFFD9AD00);
    final colorTexto = Theme.of(context).colorScheme.onSurface;

    if (_estaCargando) {
      return Scaffold(
        backgroundColor: colorFondo,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorDorado),
              const SizedBox(height: 24),
              Text(
                'Cargando perfil...',
                style: TextStyle(color: colorTexto.withAlpha(179)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorFondo,
      body: CustomScrollView(
        slivers: [
          // ✨ APP BAR MODERNO CON EFECTO
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: colorSuperficie,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorSuperficie,
                      colorDorado.withAlpha(51),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar animado
                      Hero(
                        tag: 'user_avatar',
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [colorDorado, colorAcento],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorDorado.withAlpha(77),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _nombreController.text.isNotEmpty
                                  ? _nombreController.text[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 48,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _emailController.text,
                        style: TextStyle(
                          color: colorTexto.withAlpha(179),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              // ✨ BOTÓN DE EDITAR/CANCELAR
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _modoEdicion
                    ? IconButton(
                        key: const ValueKey('cancel'),
                        icon: const Icon(Icons.close),
                        tooltip: 'Cancelar',
                        onPressed: _toggleModoEdicion,
                      )
                    : IconButton(
                        key: const ValueKey('edit'),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar perfil',
                        onPressed: _toggleModoEdicion,
                      ),
              ),
            ],
          ),

          // ✨ CONTENIDO
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Indicador de modo
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _modoEdicion
                                  ? colorDorado.withAlpha(51)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _modoEdicion
                                    ? colorDorado
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _modoEdicion ? Icons.edit : Icons.visibility,
                                  size: 16,
                                  color: _modoEdicion
                                      ? colorDorado
                                      : colorTexto.withAlpha(153),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _modoEdicion
                                      ? 'Modo Edición'
                                      : 'Modo Lectura',
                                  style: TextStyle(
                                    color: _modoEdicion
                                        ? colorDorado
                                        : colorTexto.withAlpha(153),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Información Personal
                          _buildModernCard(
                            colorSuperficie,
                            colorDorado,
                            colorTexto,
                            title: 'Información Personal',
                            icon: Icons.person_outline,
                            child: Column(
                              children: [
                                _buildModernTextField(
                                  controller: _nombreController,
                                  label: 'Nombre Completo',
                                  icon: Icons.badge_outlined,
                                  enabled: _modoEdicion,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildModernTextField(
                                        controller: _edadController,
                                        label: 'Edad',
                                        icon: Icons.cake_outlined,
                                        isNumber: true,
                                        enabled: _modoEdicion,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildModernDropdown(
                                        label: 'Género',
                                        value: _selectedGenero,
                                        items: _opcionesGenero,
                                        icon: Icons.wc_outlined,
                                        enabled: _modoEdicion,
                                        onChanged: (val) {
                                          if (_modoEdicion) {
                                            setState(() => _selectedGenero = val);
                                          }
                                        },
                                        colorTexto: colorTexto,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildModernDropdown(
                                  label: 'Clima de tu ciudad',
                                  value: _selectedClima,
                                  items: _opcionesClima,
                                  icon: Icons.wb_sunny_outlined,
                                  enabled: _modoEdicion,
                                  onChanged: (val) {
                                    if (_modoEdicion) {
                                      setState(() => _selectedClima = val);
                                    }
                                  },
                                  colorTexto: colorTexto,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Preferencias
                          _buildModernCard(
                            colorSuperficie,
                            colorDorado,
                            colorTexto,
                            title: 'Mis Preferencias',
                            icon: Icons.favorite_outline,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildChipSection(
                                  'Ocasiones de uso',
                                  _opcionesOcasion,
                                  _selectedOcasion,
                                  colorAcento,
                                  colorTexto,
                                ),
                                const Divider(height: 32),
                                _buildChipSection(
                                  'Aromas preferidos',
                                  _opcionesPreferencias,
                                  _selectedPreferencias,
                                  colorAcento,
                                  colorTexto,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Botones de acción
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _modoEdicion
                                ? _buildActionButtons(colorDorado)
                                : _buildLogoutButton(),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✨ CARD MODERNA
  Widget _buildModernCard(
    Color colorSuperficie,
    Color colorDorado,
    Color colorTexto, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorSuperficie,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorDorado.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorDorado, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: colorTexto,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // ✨ CAMPO DE TEXTO MODERNO
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(
        color: enabled ? Colors.white : Colors.white.withAlpha(153),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? Colors.white54 : Colors.white24,
        ),
        suffixIcon: !enabled
            ? Icon(Icons.lock_outline, color: Colors.white24, size: 18)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(51)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(51)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD9AD00), width: 2),
        ),
        filled: true,
        fillColor: enabled
            ? Colors.black.withAlpha(51)
            : Colors.black.withAlpha(25),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (label == "Nombre Completo" && (value == null || value.isEmpty)) {
          return "El nombre es requerido";
        }
        return null;
      },
    );
  }

  // ✨ DROPDOWN MODERNO
  Widget _buildModernDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required bool enabled,
    required Function(String?) onChanged,
    required Color colorTexto,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item[0].toUpperCase() + item.substring(1),
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white.withAlpha(153),
                  ),
                ),
              ))
          .toList(),
      onChanged: enabled ? onChanged : null,
      dropdownColor: const Color(0xFF3A3A3A),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? Colors.white54 : Colors.white24,
        ),
        suffixIcon: !enabled
            ? Icon(Icons.lock_outline, color: Colors.white24, size: 18)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(51)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(51)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(25)),
        ),
        filled: true,
        fillColor: enabled
            ? Colors.black.withAlpha(51)
            : Colors.black.withAlpha(25),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildChipSection(
    String title,
    List<String> options,
    List<String> selectedList,
    Color colorAcento,
    Color colorTexto,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colorTexto.withAlpha(179),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: options.map((option) {
            final isSelected = selectedList.contains(option);
            return FilterChip(
              label: Text(option[0].toUpperCase() + option.substring(1)),
              selected: isSelected,
              onSelected: _modoEdicion
                  ? (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedList.add(option);
                        } else {
                          selectedList.remove(option);
                        }
                      });
                    }
                  : null,
              backgroundColor: Colors.black.withAlpha(51),
              selectedColor: colorAcento.withAlpha(204),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : colorTexto.withAlpha(204),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? colorAcento
                    : (_modoEdicion
                        ? Colors.white.withAlpha(51)
                        : Colors.white.withAlpha(25)),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ✨ BOTONES DE ACCIÓN (Modo Edición)
  Widget _buildActionButtons(Color colorDorado) {
    return Column(
      key: const ValueKey('action_buttons'),
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: _estaGuardando
              ? Center(child: CircularProgressIndicator(color: colorDorado))
              : ElevatedButton.icon(
                  onPressed: _hayCambios() ? _guardarCambios : null,
                  icon: const Icon(Icons.save_outlined, color: Colors.black),
                  label: const Text(
                    'Guardar Cambios',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorDorado,
                    disabledBackgroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
        ),
      ],
    );
  }

  // ✨ BOTÓN DE CERRAR SESIÓN (Modo Lectura)
  Widget _buildLogoutButton() {
    return SizedBox(
      key: const ValueKey('logout_button'),
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Theme.of(context).cardTheme.color,
              title: const Text('Cerrar Sesión'),
              content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text('Cerrar Sesión'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await _auth.signOut();
            if (mounted) {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text(
          'Cerrar Sesión',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}