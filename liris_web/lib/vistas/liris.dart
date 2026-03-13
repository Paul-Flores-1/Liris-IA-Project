import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  
  ChatMessage({
    required this.text, 
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class LirisView extends StatefulWidget {
  const LirisView({super.key});

  @override
  State<LirisView> createState() => _LirisViewState();
}

class _LirisViewState extends State<LirisView> with SingleTickerProviderStateMixin {
  // Paleta Premium
  final Color colorFondo = const Color(0xFF121212);
  final Color colorSuperficie = const Color(0xFF252525);
  final Color colorDorado = const Color(0xFFD9AD00);
  final Color colorLiris = const Color(0xFF4A2A4D); // Púrpura oscuro elegante

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hola, soy Liris ✨\nTu asistente experta en perfumería.\n¿Qué tipo de aroma buscas hoy?",
      isUser: false,
    ),
  ];

  bool _estaCargando = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _llamarIALiris() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;

    setState(() {
      _messages.add(ChatMessage(text: prompt, isUser: true));
      _estaCargando = true;
    });
    _controller.clear();
    _scrollToBottom();

    // URL de tu servidor en Cloud Run
    const functionUrl = 'https://liris-ia-predict-604609230277.us-central1.run.app';

    try {
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'userId': userId,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _addMessage(data['recommendation'] ?? 'No se pudo interpretar la respuesta.');
      } else {
        _addMessage("Lo siento, estoy experimentando interrupciones en la red. Inténtalo de nuevo.");
      }
    } catch (e) {
      _addMessage("Parece que hay un error de conexión. Revisa tu internet.");
    } finally {
      if (mounted) {
        setState(() => _estaCargando = false);
        _scrollToBottom();
      }
    }
  }

  void _addMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Column(
          children: [
            _buildElegantHeader(),
            Expanded(
              child: Container(
                // Un ligero gradiente de fondo para no ser 100% negro
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorFondo,
                      colorLiris.withAlpha(10), // Un toque casi invisible de púrpura
                    ],
                  ),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    // Pequeño espacio extra si el mensaje anterior es de otro usuario
                    final bool isFirst = index == 0;
                    final bool isDifferentSender = !isFirst && _messages[index - 1].isUser != message.isUser;
                    
                    return Padding(
                      padding: EdgeInsets.only(top: isDifferentSender ? 20.0 : 8.0),
                      child: _buildPremiumChatBubble(message),
                    );
                  },
                ),
              ),
            ),
            if (_estaCargando) _buildTypingIndicator(),
            _buildPremiumTextInput(),
          ],
        ),
      ),
    );
  }

  // --- HEADER ELEGANTE ---
  Widget _buildElegantHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: colorFondo,
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(15), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar de Liris
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [colorDorado, const Color(0xFFB38B00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: colorDorado.withAlpha(50), blurRadius: 10, spreadRadius: 1),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: colorFondo),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo_paul_floress.png', 
                    height: 24, 
                    errorBuilder: (c, e, s) => Icon(Icons.auto_awesome, color: colorDorado, size: 20)
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Textos
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Liris IA',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('En línea', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- BURBUJAS DE CHAT PREMIUM ---
  Widget _buildPremiumChatBubble(ChatMessage message) {
    final bool isUser = message.isUser;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isUser ? colorDorado.withAlpha(20) : colorSuperficie,
            border: Border.all(
              color: isUser ? colorDorado.withAlpha(50) : Colors.white.withAlpha(15),
              width: 1,
            ),
            // Bordes asimétricos modernos
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
            ),
            boxShadow: [
              if (!isUser) // Sombra sutil solo para Liris
                BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 5, offset: const Offset(0, 2)),
            ],
          ),
          child: Text(
            message.text, 
            style: TextStyle(
              color: isUser ? Colors.white : Colors.white.withAlpha(230), 
              fontSize: 15, 
              height: 1.4, // Interlineado para mejor lectura
            ),
          ),
        ),
      ),
    );
  }

  // --- INDICADOR DE ESCRIBIENDO ---
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, bottom: 16.0, top: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorSuperficie.withAlpha(150),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14, height: 14, 
                child: CircularProgressIndicator(strokeWidth: 2, color: colorDorado.withAlpha(200))
              ),
              const SizedBox(width: 12),
              Text("Liris está escribiendo...", style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 13, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }

  // --- BARRA DE ENTRADA ESTILO PÍLDORA ---
  Widget _buildPremiumTextInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), // Padding inferior extra para SafeArea
      decoration: BoxDecoration(
        color: colorFondo,
        border: Border(top: BorderSide(color: Colors.white.withAlpha(10), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorSuperficie,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                minLines: 1,
                maxLines: 4, // Permite escribir mensajes largos que crecen hacia arriba
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Pregúntale a Liris...",
                  hintStyle: TextStyle(color: Colors.white.withAlpha(100)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Botón de Enviar Elevado
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: colorDorado,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: colorDorado.withAlpha(60), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 24), 
              onPressed: _llamarIALiris,
            ),
          ),
        ],
      ),
    );
  }
}