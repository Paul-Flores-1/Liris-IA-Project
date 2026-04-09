import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ContactView extends StatefulWidget {
  const ContactView({super.key});

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final Color colorFondo = const Color(0xFF121212);
  final Color colorSuperficie = const Color(0xFF1E1E1E);
  final Color colorDorado = const Color(0xFFD9AD00);

  bool _isSending = false;

  // Validar formato de email
  bool _isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _sendEmail() async {
    // 1. Validaciones
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      _showSnackBar('Por favor llena todos los campos', Colors.orange);
      return;
    }

    if (!_isEmailValid(_emailController.text.trim())) {
      _showSnackBar('Por favor ingresa un correo valido', Colors.redAccent);
      return;
    }

    setState(() => _isSending = true);

    const String serviceId = 'service_9ln3z0n';
    const String templateId = 'template_tyve81a';
    const String userId = 'CRCvQ-n7jCFWwbfTO';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'from_name': _nameController.text.trim(),
            'from_email': _emailController.text.trim(),
            'message': _messageController.text.trim(),
          }
        }),
      );

      if (response.statusCode == 200) {
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
        _showSnackBar('Mensaje enviado con exito', Colors.green);
      } else {
        throw Exception('Error en servidor');
      }
    } catch (e) {
      _showSnackBar('Error al enviar mensaje', Colors.red);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: const Text('Contacto', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: colorFondo,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Cabecera estilizada
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30.0),
              child: Column(
                children: [
                  Icon(Icons.alternate_email_rounded, size: 60, color: colorDorado),
                  const SizedBox(height: 15),
                  const Text(
                    'Ponte en contacto',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Responderemos en menos de 24 horas',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildLirisCard(),
                  const SizedBox(height: 25),
                  _buildContactForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLirisCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorSuperficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorDorado.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colorDorado, size: 28),
              const SizedBox(width: 12),
              const Text('Asesoria Instantanea', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Liris IA puede recomendarte perfumes en tiempo real sin esperar un correo.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), height: 1.4),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorDorado,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('IR AL CHAT CON LIRIS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Escribenos directamente', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 15),
        _customField('Tu nombre', _nameController, Icons.person_outline),
        const SizedBox(height: 15),
        _customField('Tu correo', _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 15),
        _customField('Mensaje', _messageController, Icons.chat_bubble_outline, maxLines: 5),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorDorado,
              disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: _isSending
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Text('ENVIAR MENSAJE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }

  Widget _customField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: colorDorado, size: 20),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        filled: true,
        fillColor: colorSuperficie,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: colorDorado)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }
}