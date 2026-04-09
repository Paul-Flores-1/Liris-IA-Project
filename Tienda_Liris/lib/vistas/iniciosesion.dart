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

  // Opciones para personalización
  final List<String> _opcionesGenero = ['Masculino', 'Femenino', 'Unisex'];
  final List<String> _opcionesClima = ['Cálido', 'Templado', 'Frío'];
  final List<String> _opcionesOcasion = ['Diario', 'Escuela', 'Trabajo', 'Formal', 'Casual', 'Cita'];
  final List<String> _opcionesPreferencias = ['Cítrico', 'Dulce', 'Amaderado', 'Floral', 'Fresco'];

  String? _selectedGenero;
  String? _selectedClima;
  final List<String> _selectedOcasion = [];
  final List<String> _selectedPreferencias = [];

  int _pasoDeRegistro = 1;

  // Colores Premium Liris
  final Color colorDorado = const Color(0xFFD9AD00);
  final Color colorFondo = const Color(0xFF0A0A0A);
  final Color colorCard = const Color(0xFF1A1A1A);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _edadController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE NAVEGACIÓN Y AUTH ---
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
        setState(() => _pasoDeRegistro = 2);
        break;
      case 2:
        if (!_formKeyPaso2.currentState!.validate()) return;
        setState(() => _pasoDeRegistro = 3);
        break;
      case 3:
        await _registrarUsuario();
        break;
    }
  }

  Future<void> _registrarUsuario() async {
    setState(() { _estaCargando = true; });
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
          'email': user.email,
          'nombre': _nombreController.text.trim(),
          'edad': int.tryParse(_edadController.text.trim()),
          'clima': _selectedClima ?? '',
          'genero': _selectedGenero ?? '',
          'ocasion': _selectedOcasion,
          'preferencias': _selectedPreferencias,
          'fecha_registro': FieldValue.serverTimestamp(),
        });

        await _auth.signOut();
        if (mounted) {
          _limpiarCamposYResetear();
          _mostrarError("¡Cuenta creada! Inicia sesión para continuar.", esError: false);
        }
      }
    } on FirebaseAuthException catch (e) {
      _mostrarError(_parseErrorDeAuth(e.code));
      setState(() { _pasoDeRegistro = 1; });
    } finally {
      if (mounted) setState(() { _estaCargando = false; });
    }
  }

  void _limpiarCamposYResetear() {
    _emailController.clear();
    _passwordController.clear();
    _nombreController.clear();
    _edadController.clear();
    setState(() {
      _esModoLogin = true;
      _pasoDeRegistro = 1;
      _selectedGenero = null;
      _selectedClima = null;
      _selectedOcasion.clear();
      _selectedPreferencias.clear();
    });
  }

  String _parseErrorDeAuth(String code) {
    switch (code) {
      case 'weak-password': return 'Contraseña muy débil.';
      case 'email-already-in-use': return 'Este correo ya está en uso.';
      case 'invalid-credential': return 'Credenciales incorrectas.';
      default: return 'Error de autenticación.';
    }
  }

  void _mostrarError(String mensaje, {bool esError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
        backgroundColor: esError ? Colors.redAccent : colorDorado,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorFondo, colorDorado.withAlpha(15), colorFondo],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                // Logo de Liris
                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/images/logo_paul_floress.png',
                    height: 140,
                    errorBuilder: (_, __, ___) => Icon(Icons.auto_awesome, size: 80, color: colorDorado),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Card de Formulario
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: colorCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(15)),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(150), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _esModoLogin ? "Bienvenido a Liris" : "Crea tu perfil",
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _esModoLogin ? "Ingresa tus datos" : "Paso $_pasoDeRegistro de 3",
                        style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 14),
                      ),
                      const SizedBox(height: 30),
                      
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildContenidoActual(),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      if (_estaCargando)
                        CircularProgressIndicator(color: colorDorado)
                      else
                        _buildBotonesAccion(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() {
                    _esModoLogin = !_esModoLogin;
                    _pasoDeRegistro = 1;
                  }),
                  child: Text(
                    _esModoLogin ? "¿No tienes cuenta? Regístrate" : "¿Ya tienes cuenta? Inicia sesión",
                    style: TextStyle(color: colorDorado, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContenidoActual() {
    if (_esModoLogin) {
      return Form(key: _formKeyLogin, child: _buildCamposAuth());
    }
    switch (_pasoDeRegistro) {
      case 1: return Form(key: _formKeyPaso1, child: _buildCamposAuth());
      case 2: return Form(key: _formKeyPaso2, child: _buildCamposPerfil());
      case 3: return _buildCamposPreferencias();
      default: return const SizedBox();
    }
  }

  Widget _buildCamposAuth() {
    return Column(
      children: [
        _buildTextField(controller: _emailController, label: "Correo", icon: Icons.email_outlined),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _passwordController, 
          label: "Contraseña", 
          icon: Icons.lock_outline, 
          isPassword: true,
          showPassword: _mostrarPassword,
          onTogglePassword: () => setState(() => _mostrarPassword = !_mostrarPassword),
        ),
      ],
    );
  }

  Widget _buildCamposPerfil() {
    return Column(
      children: [
        _buildTextField(controller: _nombreController, label: "Nombre", icon: Icons.person_outline),
        const SizedBox(height: 15),
        _buildTextField(controller: _edadController, label: "Edad", icon: Icons.cake_outlined, isNumber: true),
        const SizedBox(height: 15),
        _buildDropdown("Género", _selectedGenero, _opcionesGenero, (v) => setState(() => _selectedGenero = v)),
        const SizedBox(height: 15),
        _buildDropdown("Clima de tu ciudad", _selectedClima, _opcionesClima, (v) => setState(() => _selectedClima = v)),
      ],
    );
  }

  Widget _buildCamposPreferencias() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChipGroup("¿Para qué ocasión?", _opcionesOcasion, _selectedOcasion),
        const SizedBox(height: 20),
        _buildChipGroup("Aromas favoritos", _opcionesPreferencias, _selectedPreferencias),
      ],
    );
  }

  Widget _buildBotonesAccion() {
    String label = _esModoLogin ? "INICIAR SESIÓN" : (_pasoDeRegistro < 3 ? "SIGUIENTE" : "REGISTRARME");
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _handleBotonPrincipal,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorDorado,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            child: Text(label),
          ),
        ),
        if (!_esModoLogin && _pasoDeRegistro > 1)
          TextButton(
            onPressed: () => setState(() => _pasoDeRegistro--),
            child: const Text("Atrás", style: TextStyle(color: Colors.white54)),
          ),
      ],
    );
  }

  // --- WIDGETS REUTILIZABLES ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool showPassword = false,
    bool isNumber = false,
    VoidCallback? onTogglePassword,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !showPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withAlpha(100)),
        prefixIcon: Icon(icon, color: colorDorado, size: 20),
        suffixIcon: isPassword ? IconButton(icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38), onPressed: onTogglePassword) : null,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(20))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorDorado)),
        filled: true,
        fillColor: Colors.white.withAlpha(5),
      ),
      validator: (v) => v == null || v.isEmpty ? "Campo requerido" : null,
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: colorCard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withAlpha(100)),
        prefixIcon: Icon(Icons.arrow_drop_down_circle_outlined, color: colorDorado, size: 20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(20))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorDorado)),
        filled: true,
        fillColor: Colors.white.withAlpha(5),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildChipGroup(String title, List<String> options, List<String> selectedList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            final isSelected = selectedList.contains(opt);
            return FilterChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (val) => setState(() => val ? selectedList.add(opt) : selectedList.remove(opt)),
              selectedColor: colorDorado,
              checkmarkColor: Colors.black,
              labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70),
              backgroundColor: colorCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? colorDorado : Colors.white12)),
            );
          }).toList(),
        ),
      ],
    );
  }
}