import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

// Modelo para un mensaje de chat
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
  // Colores originales de Liris
  final Color fondoLiris = const Color(0xFF4A2A4D);
  final Color burbujaLiris = const Color(0xFF3A3A3A);
  final Color burbujaUsuario = const Color(0xFF2A2A2A);
  final Color colorAccent = const Color(0xFF8B5A8E);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingAnimationController;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hola, soy Liris 👋\n¿Qué tipo de perfume estás buscando?",
      isUser: false,
    ),
  ];

  bool _estaCargando = false;
  static const String _errorRespuestaIA = "Lo siento, no estoy disponible en este momento. Por favor, intenta más tarde.";

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
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

    const functionUrl = 'https://liris-ia-predict-604609230277.us-central1.run.app';
    String respuestaTexto = "";

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
        respuestaTexto = data['recommendation'] ?? 'No se pudo interpretar la respuesta.';
      } else {
        respuestaTexto = _errorRespuestaIA;
        debugPrint("Error de Liris API: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      respuestaTexto = _errorRespuestaIA;
      debugPrint("Error de conexión con Liris: $e");
    }

    setState(() {
      _messages.add(ChatMessage(text: respuestaTexto, isUser: false));
      _estaCargando = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: fondoLiris,
        border: Border(
          left: BorderSide(
            color: Colors.white.withAlpha(10),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header minimalista
          _buildHeader(),
          
          Divider(height: 1, color: Colors.white.withAlpha(10)),

          // Lista de mensajes
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildChatBubble(_messages[index], index);
                    },
                  ),
          ),

          // Indicador de escritura
          if (_estaCargando) _buildTypingIndicator(),

          Divider(height: 1, color: Colors.white.withAlpha(10)),

          // Input de texto
          _buildTextInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Column(
        children: [
          // Logo original de Liris
          Image.asset(
            'assets/images/logo_liris.png',
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.auto_awesome, color: Colors.white70, size: 80),
          ),
          
          const SizedBox(height: 12),
          
          // Título
          const Text(
            'Liris',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Subtítulo
          Text(
            'Tu asistente de fragancias',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withAlpha(150),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.white.withAlpha(50),
            ),
            const SizedBox(height: 16),
            Text(
              'Inicia una conversación',
              style: TextStyle(
                color: Colors.white.withAlpha(120),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message, int index) {
    final align = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final isLastMessage = index == _messages.length - 1;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLastMessage ? 8.0 : 16.0,
        left: message.isUser ? 40.0 : 0.0,
        right: message.isUser ? 0.0 : 40.0,
      ),
      child: Column(
        crossAxisAlignment: align,
        children: [
          // Avatar pequeño
          if (!message.isUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A2A4D).withAlpha(100),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Liris',
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          
          // Burbuja de mensaje
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: message.isUser ? burbujaUsuario : burbujaLiris,
              borderRadius: BorderRadius.circular(16).copyWith(
                topLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
                topRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
              ),
              border: message.isUser
                  ? null
                  : Border.all(
                      color: Colors.white.withAlpha(10),
                      width: 1,
                    ),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: Colors.white.withAlpha(message.isUser ? 255 : 230),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          
          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
            child: Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: Colors.white.withAlpha(80),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF4A2A4D).withAlpha(100),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white70,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: burbujaLiris,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withAlpha(10),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final value = (_typingAnimationController.value - (index * 0.2)) % 1.0;
        final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2).clamp(0.3, 1.0);
        
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white70.withAlpha((opacity * 180).toInt()),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  // --- WIDGET MODIFICADO ---
  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Material(
              // Usamos Material para el recorte perfecto
              color: burbujaLiris,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias, // <--- LA SOLUCIÓN
              child: Container(
                decoration: BoxDecoration(
                  // Mantenemos el borde aquí
                  border: Border.all(
                    color: Colors.white.withAlpha(20),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  enabled: !_estaCargando,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent, // Transparente para ver el Material
                    hintText: 'Escribe tu mensaje...',
                    hintStyle: TextStyle(
                      color: Colors.white.withAlpha(100),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _llamarIALiris(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Botón de enviar con colores originales
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF8B5A8E),
              shape: BoxShape.circle,
              boxShadow: _estaCargando
                  ? []
                  : [
                      BoxShadow(
                        color: const Color(0xFF8B5A8E).withAlpha(80),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
            ),
            child: IconButton(
              icon: Icon(
                _estaCargando ? Icons.hourglass_empty : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _estaCargando ? null : _llamarIALiris,
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 60) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}