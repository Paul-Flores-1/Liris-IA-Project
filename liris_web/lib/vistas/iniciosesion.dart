import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InicioSesionView extends StatefulWidget {
  const InicioSesionView({super.key});

  @override
  State<InicioSesionView> createState() => _InicioSesionViewState();
}

class _InicioSesionViewState extends State<InicioSesionView> {
  bool _esModoLogin = true;
  bool _estaCargando = false;
  bool _mostrarPassword = false;
  
  final _formKeyLogin = GlobalKey<FormState>();
  final _formKeyPaso1 = GlobalKey<FormState>();
  final _formKeyPaso2 = GlobalKey<FormState>();

  final _auth = FirebaseAuth.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _edadController = TextEditingController();

  final List<String> _opcionesGenero = ['masculino', 'femenino'];
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

  String? _selectedGenero;
  String? _selectedClima;
  final List<String> _selectedOcasion = [];
  final List<String> _selectedPreferencias = [];

  int _pasoDeRegistro = 1;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _edadController.dispose();
    super.dispose();
  }

  Future<void> _handleBotonPrincipal() async {
    if (_esModoLogin) {
      if (!_formKeyLogin.currentState!.validate()) return;
      
      setState(() { _estaCargando = true; });
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        _mostrarError(_parseErrorDeAuth(e.code));
      } catch (e) {
        _mostrarError("Ocurrió un error inesperado.");
      }
      if (mounted) setState(() { _estaCargando = false; });
      return;
    }

    switch (_pasoDeRegistro) {
      case 1:
        if (!_formKeyPaso1.currentState!.validate()) return;
        setState(() {
          _pasoDeRegistro = 2;
        });
        break;
      case 2:
        if (!_formKeyPaso2.currentState!.validate()) return;
        setState(() {
          _pasoDeRegistro = 3;
        });
        break;
      case 3:
        await _registrarUsuario();
        break;
    }
  }

  Future<void> _registrarUsuario() async {
    setState(() { _estaCargando = true; });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .set({
          'email': user.email,
          'nombre': _nombreController.text.trim(),
          'edad': int.tryParse(_edadController.text.trim()),
          'clima': _selectedClima ?? '',
          'genero': _selectedGenero ?? '',
          'ocasion': _selectedOcasion,
          'preferencias': _selectedPreferencias,
        });

        await _auth.signOut();

        if (mounted) {
          _limpiarCamposYResetear();
          _mostrarError("¡Cuenta creada! Por favor, inicia sesión.", esError: false);
        }
      }
    } on FirebaseAuthException catch (e) {
      _mostrarError(_parseErrorDeAuth(e.code));
      setState(() { _pasoDeRegistro = 1; });
    } catch (e) {
      _mostrarError("Ocurrió un error inesperado.");
    }
    if (mounted) {
      setState(() { _estaCargando = false; });
    }
  }

  void _limpiarCamposYResetear() {
    _emailController.clear();
    _passwordController.clear();
    _nombreController.clear();
    _edadController.clear();
    _selectedGenero = null;
    _selectedClima = null;
    _selectedOcasion.clear();
    _selectedPreferencias.clear();
    _esModoLogin = true;
    _pasoDeRegistro = 1;
  }

  void _irPasoAtras() {
    if (_pasoDeRegistro > 1) {
      setState(() {
        _pasoDeRegistro--;
      });
    }
  }

  String _parseErrorDeAuth(String code) {
    switch (code) {
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado. Intenta iniciar sesión.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      default:
        return 'Ocurrió un error.';
    }
  }

  void _mostrarError(String mensaje, {bool esError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.redAccent : Colors.green[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color colorFondo = const Color(0xFF0A0A0A);
    final Color colorCard = const Color(0xFF1A1A1A);
    final Color colorAccent = const Color(0xFF4A2A4D);
    final Color colorTexto = Colors.white;

    return Scaffold(
      backgroundColor: colorFondo,
      body: Stack(
        children: [
          // Fondo con gradiente sutil
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  colorAccent.withAlpha(20),
                  colorFondo,
                ],
              ),
            ),
          ),
          
          // Contenido
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- LOGO (Sin panel/borde) ---
                      Image.asset(
                        'assets/images/logo_paul_floress.png',
                        height: 170,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.store_outlined, size: 80, color: colorTexto.withAlpha(150)),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Card principal
                      Container(
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: colorCard,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withAlpha(10),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(100),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título
                              // Título Centrado
Center(
  child: Text(
    _esModoLogin ? 'Bienvenido' : 'Crear Cuenta',
    textAlign: TextAlign.center, // Importante por si el texto salta a 2 líneas
    style: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: colorTexto,
      letterSpacing: -0.5,
    ),
  ),
),

const SizedBox(height: 8),

// Subtítulo Centrado
Center(
  child: Text(
    _esModoLogin 
      ? 'Ingresa a tu cuenta'
      : 'Paso $_pasoDeRegistro de 3',
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: 15,
      color: colorTexto.withAlpha(120),
      fontWeight: FontWeight.w400,
    ),
  ),
),
                              
                              const SizedBox(height: 32),

                              // Formulario
                              _buildFormulario(colorTexto, colorAccent),
                              
                              const SizedBox(height: 28),

                              // Botón principal
                              if (_estaCargando)
                                Center(
                                  child: CircularProgressIndicator(
                                    color: colorAccent,
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                _buildBotonesDeNavegacion(colorAccent, colorTexto),

                              const SizedBox(height: 24),
                              
                              // Cambiar entre Login y Registro
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      if (_esModoLogin) {
                                        _esModoLogin = false;
                                      } else {
                                        _limpiarCamposYResetear();
                                      }
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: colorTexto.withAlpha(150),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(
                                    _esModoLogin
                                        ? '¿No tienes cuenta? Créala aquí'
                                        : '¿Ya tienes cuenta? Inicia sesión',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesDeNavegacion(Color colorAccent, Color colorTexto) {
    String textoBotonPrincipal = 'Iniciar Sesión';
    if (!_esModoLogin) {
      if (_pasoDeRegistro == 1 || _pasoDeRegistro == 2) {
        textoBotonPrincipal = 'Siguiente';
      } else {
        textoBotonPrincipal = 'Crear Cuenta';
      }
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _handleBotonPrincipal,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              textoBotonPrincipal,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        
        if (!_esModoLogin && _pasoDeRegistro > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: TextButton(
              onPressed: _irPasoAtras,
              style: TextButton.styleFrom(
                foregroundColor: colorTexto.withAlpha(150),
              ),
              child: const Text('← Atrás'),
            ),
          ),
      ],
    );
  }

  Widget _buildFormulario(Color colorTexto, Color colorAccent) {
    if (_esModoLogin) {
      return Form(
        key: _formKeyLogin,
        child: _buildPaso1(colorTexto, colorAccent),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_pasoDeRegistro),
        child: _buildPasosDeRegistro(colorTexto, colorAccent),
      ),
    );
  }

  Widget _buildPasosDeRegistro(Color colorTexto, Color colorAccent) {
    switch (_pasoDeRegistro) {
      case 1:
        return Form(key: _formKeyPaso1, child: _buildPaso1(colorTexto, colorAccent));
      case 2:
        return Form(key: _formKeyPaso2, child: _buildPaso2(colorTexto, colorAccent));
      case 3:
      default:
        return _buildPaso3(colorTexto, colorAccent);
    }
  }

  Widget _buildPaso1(Color colorTexto, Color colorAccent) {
    return Column(
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Correo Electrónico',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          colorTexto: colorTexto,
          colorAccent: colorAccent,
          validator: (value) {
            if (value == null || value.trim().isEmpty || !value.contains('@')) {
              return 'Por favor, ingresa un correo válido.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Contraseña',
          icon: Icons.lock_outline,
          obscureText: !_mostrarPassword,
          colorTexto: colorTexto,
          colorAccent: colorAccent,
          suffixIcon: IconButton(
            icon: Icon(
              _mostrarPassword ? Icons.visibility_off : Icons.visibility,
              color: colorTexto.withAlpha(100),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _mostrarPassword = !_mostrarPassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, ingresa tu contraseña.';
            }
            if (!_esModoLogin && value.trim().length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPaso2(Color colorTexto, Color colorAccent) {
    return Column(
      children: [
        _buildTextField(
          controller: _nombreController,
          label: 'Nombre Completo',
          icon: Icons.person_outline,
          colorTexto: colorTexto,
          colorAccent: colorAccent,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, ingresa tu nombre.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _edadController,
          label: 'Edad (Opcional)',
          icon: Icons.cake_outlined,
          keyboardType: TextInputType.number,
          colorTexto: colorTexto,
          colorAccent: colorAccent,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Género',
          value: _selectedGenero,
          items: _opcionesGenero,
          icon: Icons.wc_outlined,
          colorTexto: colorTexto,
          colorAccent: colorAccent,
          onChanged: (value) {
            setState(() => _selectedGenero = value);
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Clima de tu ciudad',
          value: _selectedClima,
          items: _opcionesClima,
          icon: Icons.wb_sunny_outlined,
          colorTexto: colorTexto,
          colorAccent: colorAccent,
          onChanged: (value) {
            setState(() => _selectedClima = value);
          },
        ),
      ],
    );
  }

  Widget _buildPaso3(Color colorTexto, Color colorAccent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChipGroup(
          'Ocasión de uso',
          _opcionesOcasion,
          _selectedOcasion,
          colorTexto,
          colorAccent,
        ),
        const SizedBox(height: 24),
        _buildChipGroup(
          'Aromas preferidos',
          _opcionesPreferencias,
          _selectedPreferencias,
          colorTexto,
          colorAccent,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color colorTexto,
    required Color colorAccent,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(color: colorTexto, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: colorTexto.withAlpha(120),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: colorTexto.withAlpha(100), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withAlpha(5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Color colorTexto,
    required Color colorAccent,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorTexto.withAlpha(120), fontSize: 14),
        prefixIcon: Icon(icon, color: colorTexto.withAlpha(100), size: 20),
        filled: true,
        fillColor: Colors.white.withAlpha(5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dropdownColor: const Color(0xFF1A1A1A),
      style: TextStyle(color: colorTexto, fontSize: 15),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item[0].toUpperCase() + item.substring(1)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildChipGroup(
    String title,
    List<String> options,
    List<String> selectedList,
    Color colorTexto,
    Color colorAccent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colorTexto.withAlpha(180),
            fontSize: 14,
            fontWeight: FontWeight.w600,
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
              backgroundColor: Colors.white.withAlpha(5),
              selectedColor: colorAccent.withAlpha(50),
              checkmarkColor: colorAccent,
              labelStyle: TextStyle(
                color: isSelected ? colorAccent : colorTexto.withAlpha(150),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isSelected ? colorAccent : Colors.white.withAlpha(20),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    selectedList.add(option);
                  } else {
                    selectedList.remove(option);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}