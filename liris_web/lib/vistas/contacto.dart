import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Para enviar el correo
import 'dart:convert'; // Para codificar los datos

class ContactView extends StatefulWidget {
  const ContactView({super.key});

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  // --- CONTROLADORES DE TEXTO ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isSending = false; // Estado para mostrar el spinner de carga

  // --- FUNCIÓN DE ENVÍO CON TUS CLAVES REALES ---
  Future<void> _sendEmail() async {
    // 1. Validaciones básicas
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _messageController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor llena todos los campos'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // 2. Activar modo carga
    setState(() {
      _isSending = true;
    });

    // 3. TUS CREDENCIALES EXACTAS (Extraídas de tus imágenes)
    const String serviceId = 'service_9ln3z0n';
    const String templateId = 'template_tyve81a';
    const String userId = 'CRCvQ-n7jCFWwbfTO'; // Tu Public Key

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'from_name': _nameController.text,  // Coincide con tu plantilla
            'from_email': _emailController.text, // Coincide con tu plantilla
            'message': _messageController.text,  // Coincide con tu plantilla
          }
        }),
      );

      if (response.statusCode == 200) {
        // Éxito: Limpiamos campos y mostramos mensaje
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Mensaje enviado con éxito! Te responderemos pronto.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Error al enviar: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hubo un problema al enviar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 4. Desactivar modo carga
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- EXTRACCIÓN DE COLORES (Diseño Original) ---
    final Color colorFondo = Theme.of(context).scaffoldBackgroundColor;
    final Color colorSuperficie = Theme.of(context).cardTheme.color ?? const Color(0xFF2A2A2A);
    final Color colorDorado = const Color(0xFFD9AD00);
    final Color colorTexto = Theme.of(context).colorScheme.onSurface;
    final Color colorTextoSecundario = colorTexto.withAlpha(179);

    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: const Text('Contacto'),
        backgroundColor: colorFondo,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HERO SECTION ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorSuperficie,
                    colorFondo,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.mail_outline, size: 80, color: colorDorado),
                  const SizedBox(height: 24),
                  Text(
                    'Estamos para Ayudarte',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorDorado,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¿Tienes dudas o necesitas asesoría?',
                    style: TextStyle(
                      fontSize: 18,
                      color: colorTextoSecundario,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // --- CONTENIDO PRINCIPAL ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  children: [
                    // --- SECCIÓN ESPECIAL: LIRIS IA ---
                    _buildSectionCard(
                      context,
                      icon: Icons.auto_awesome,
                      iconColor: colorDorado,
                      title: 'Pregúntale a Liris IA',
                      content:
                          'No esperes una respuesta por correo. Nuestra inteligencia artificial experta en perfumería está disponible 24/7 para recomendarte tu fragancia ideal o resolver dudas rápidas.',
                      colorSuperficie: colorSuperficie,
                      colorTexto: colorTexto,
                      colorTextoSecundario: colorTextoSecundario,
                      extraWidget: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context); 
  },
  icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
  label: const Text(
    'Iniciar Chat con Liris',
    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorDorado,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- LAYOUT RESPONSIVO (Info + Formulario) ---
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 700) {
                          // Escritorio/Tablet Horizontal
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: _buildContactInfoCard(
                                    context, colorSuperficie, colorDorado, colorTexto, colorTextoSecundario),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 6,
                                child: _buildFormCard(
                                    context, colorSuperficie, colorDorado, colorTexto, colorTextoSecundario),
                              ),
                            ],
                          );
                        } else {
                          // Móvil
                          return Column(
                            children: [
                              _buildContactInfoCard(
                                  context, colorSuperficie, colorDorado, colorTexto, colorTextoSecundario),
                              const SizedBox(height: 24),
                              _buildFormCard(
                                  context, colorSuperficie, colorDorado, colorTexto, colorTextoSecundario),
                            ],
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildContactInfoCard(
      BuildContext context, Color bg, Color accent, Color text, Color subtext) {
    return _buildSectionCard(
      context,
      icon: Icons.storefront,
      iconColor: accent,
      title: 'Datos de Contacto',
      content: '',
      colorSuperficie: bg,
      colorTexto: text,
      colorTextoSecundario: subtext,
      extraWidget: Column(
        children: [
          _buildValueItem(Icons.email_outlined, 'Email', 'alanpaul380@gmail.com', accent, text, subtext),
          const SizedBox(height: 16),
          _buildValueItem(Icons.phone_outlined, 'Teléfono', '+52 7442299018', accent, text, subtext),
          const SizedBox(height: 16),
          _buildValueItem(Icons.location_on_outlined, 'Ubicación', 'Acapulco, Guerrero', accent, text, subtext),
          const SizedBox(height: 16),
          _buildValueItem(Icons.access_time, 'Horario', 'Lun - Vie: 9:00 AM - 5:00 PM', accent, text, subtext),
        ],
      ),
    );
  }

  Widget _buildFormCard(
      BuildContext context, Color bg, Color accent, Color text, Color subtext) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Envíanos un mensaje',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: text),
          ),
          const SizedBox(height: 20),
          _customTextField('Nombre Completo', text, subtext, accent, controller: _nameController),
          const SizedBox(height: 16),
          _customTextField('Correo Electrónico', text, subtext, accent, controller: _emailController),
          const SizedBox(height: 16),
          _customTextField('Mensaje', text, subtext, accent, maxLines: 4, controller: _messageController),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendEmail, // Desactiva si está enviando
              style: ElevatedButton.styleFrom(
                backgroundColor: accent.withAlpha(51),
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 20),
                side: BorderSide(color: accent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSending
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: accent, strokeWidth: 2),
                    )
                  : const Text(
                      'ENVIAR',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customTextField(String label, Color text, Color subtext, Color accent,
      {int maxLines = 1, required TextEditingController controller}) {
    return TextField(
      controller: controller, // Conectado al controlador
      maxLines: maxLines,
      style: TextStyle(color: text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subtext),
        alignLabelWithHint: true,
        filled: true,
        fillColor: Colors.black.withAlpha(30),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: subtext.withAlpha(50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: subtext.withAlpha(50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required Color colorSuperficie,
    required Color colorTexto,
    required Color colorTextoSecundario,
    Widget? extraWidget,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colorSuperficie,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorTexto,
                  ),
                ),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: colorTextoSecundario,
                height: 1.6,
              ),
            ),
          ],
          if (extraWidget != null) ...[
            const SizedBox(height: 16),
            extraWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildValueItem(
    IconData icon,
    String title,
    String description,
    Color colorDorado,
    Color colorTexto,
    Color colorTextoSecundario,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorDorado.withAlpha(51),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorDorado, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorTexto,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: colorTextoSecundario,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}