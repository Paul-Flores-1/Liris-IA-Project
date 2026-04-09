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
  bool _modoEdicion = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _nombreController = TextEditingController();
  final _edadController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedGenero;
  String? _selectedClima;
  List<String> _selectedOcasion = [];
  List<String> _selectedPreferencias = [];

  // Paleta de colores Premium Liris (Consistente con tu catálogo)
  final Color colorDorado = const Color(0xFFD9AD00);
  final Color colorFondo = const Color(0xFF0A0A0A);
  final Color colorCard = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _animationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
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
          setState(() {
            _nombreController.text = data['nombre'] ?? '';
            _edadController.text = data['edad']?.toString() ?? '';
            _selectedGenero = data['genero'] == '' ? null : data['genero'];
            _selectedClima = data['clima'] == '' ? null : data['clima'];
            _selectedOcasion = List<String>.from(data['ocasion'] ?? []);
            _selectedPreferencias = List<String>.from(data['preferencias'] ?? []);
          });
        }
      } catch (e) {
        _notificar("Error al sincronizar con la nube", esError: true);
      }
    }
    setState(() => _estaCargando = false);
    _animationController.forward();
  }

  void _notificar(String msj, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msj, style: const TextStyle(color: Colors.white)),
      backgroundColor: esError ? Colors.redAccent : colorDorado,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _estaGuardando = true);
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
        _notificar("Perfil actualizado correctamente");
        setState(() => _modoEdicion = false);
      }
    } catch (e) {
      _notificar("Error al guardar cambios", esError: true);
    }
    setState(() => _estaGuardando = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_estaCargando) {
      return Scaffold(
        backgroundColor: colorFondo,
        body: Center(child: CircularProgressIndicator(color: colorDorado)),
      );
    }

    return Scaffold(
      backgroundColor: colorFondo,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(), // Efecto nativo móvil
        slivers: [
          // Header móvil con Avatar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: colorCard,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colorDorado.withAlpha(50), colorFondo],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Hero(
                      tag: 'perfil_avatar',
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: colorDorado,
                        child: Text(
                          _nombreController.text.isNotEmpty ? _nombreController.text[0].toUpperCase() : "U",
                          style: const TextStyle(fontSize: 32, color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(_emailController.text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(_modoEdicion ? Icons.close : Icons.edit_note, color: colorDorado, size: 28),
                onPressed: () => setState(() => _modoEdicion = !_modoEdicion),
              )
            ],
          ),

          // Cuerpo del formulario
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("DATOS PERSONALES"),
                      _buildModernField(
                        controller: _nombreController, 
                        label: "Nombre Completo", 
                        icon: Icons.person_outline
                      ),
                      const SizedBox(height: 15),
                      _buildModernField(
                        controller: _edadController, 
                        label: "Edad", 
                        icon: Icons.cake_outlined, 
                        isNumber: true
                      ),
                      
                      const SizedBox(height: 30),
                      _buildSectionTitle("MIS PREFERENCIAS LIRIS"),
                      _buildChipGroup("¿En qué ocasiones usas perfume?", ['diario', 'trabajo', 'formal', 'cita'], _selectedOcasion),
                      const SizedBox(height: 20),
                      _buildChipGroup("Aromas que te definen", ['cítrico', 'dulce', 'amaderado', 'floral', 'fresco'], _selectedPreferencias),
                      
                      const SizedBox(height: 40),
                      
                      // Botón Adaptativo
                      if (_modoEdicion)
                        _estaGuardando 
                          ? Center(child: CircularProgressIndicator(color: colorDorado))
                          : SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _guardarCambios,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorDorado,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  elevation: 5,
                                ),
                                child: const Text("GUARDAR CAMBIOS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: OutlinedButton.icon(
                            onPressed: () => _auth.signOut(),
                            icon: const Icon(Icons.logout, color: Colors.redAccent),
                            label: const Text("CERRAR SESIÓN", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(
        title, 
        style: TextStyle(color: colorDorado, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2),
      ),
    );
  }

  Widget _buildModernField({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      enabled: _modoEdicion,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _modoEdicion ? colorDorado : Colors.white38),
        prefixIcon: Icon(icon, color: _modoEdicion ? colorDorado : Colors.white24, size: 22),
        filled: true,
        fillColor: _modoEdicion ? Colors.white.withAlpha(10) : colorCard.withAlpha(150),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: colorDorado, width: 2)),
      ),
      validator: (v) => v == null || v.isEmpty ? "Este dato es necesario para Liris IA" : null,
    );
  }

  Widget _buildChipGroup(String title, List<String> options, List<String> selectedList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14, fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((opt) {
            final isSelected = selectedList.contains(opt);
            return FilterChip(
              label: Text(opt[0].toUpperCase() + opt.substring(1)),
              selected: isSelected,
              onSelected: _modoEdicion ? (val) {
                setState(() {
                  val ? selectedList.add(opt) : selectedList.remove(opt);
                });
              } : null,
              selectedColor: colorDorado,
              checkmarkColor: Colors.black,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              ),
              backgroundColor: colorCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: isSelected ? colorDorado : Colors.white12)
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}