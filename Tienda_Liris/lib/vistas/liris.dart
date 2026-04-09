import 'package:flutter/material.dart';
import '../services/ia_service.dart';

// IMPORTACIONES VITALES PARA LA NAVEGACIÓN
import '../models/perfume.dart'; 
import 'detalles.dart'; 

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<Map<String, dynamic>>? productos; 
  
  ChatMessage({
    required this.text, 
    required this.isUser,
    this.productos,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class LirisView extends StatefulWidget {
  const LirisView({super.key});

  @override
  State<LirisView> createState() => _LirisViewState();
}

class _LirisViewState extends State<LirisView> with SingleTickerProviderStateMixin {
  final Color colorFondo = const Color(0xFF121212);
  final Color colorSuperficie = const Color(0xFF252525);
  final Color colorDorado = const Color(0xFFD9AD00);
  final Color colorLiris = const Color(0xFF4A2A4D);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hola, soy Liris.\nTu asistente experta en perfumeria.\n¿Que tipo de aroma buscas hoy?",
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

    setState(() {
      _messages.add(ChatMessage(text: prompt, isUser: true));
      _estaCargando = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Aquí mandamos el género de tu perfil. 
    // Idealmente, esto debería venir de tu Provider de Usuario: perfil.genero
    final respuestaServer = await IaService.enviarMensajeALiris(
      prompt, 
      generoUsuario: "masculino" 
    );

    if (mounted) {
      setState(() => _estaCargando = false);
      
      if (respuestaServer['status'] == 'error') {
        _addMessage("Perdona, me confundi un poco. ¿Me podrias dar un poco mas de detalles sobre el aroma que buscas?");
      } else {
        String textoLiris = respuestaServer['respuesta_texto'] ?? "Mira lo que encontré:";
        List<Map<String, dynamic>>? productosEncontrados;

        if (respuestaServer['productos'] != null && (respuestaServer['productos'] as List).isNotEmpty) {
          productosEncontrados = List<Map<String, dynamic>>.from(respuestaServer['productos']);
        }

        setState(() {
          _messages.add(ChatMessage(
            text: textoLiris, 
            isUser: false, 
            productos: productosEncontrados
          ));
        });
      }
      _scrollToBottom();
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colorFondo, colorLiris.withAlpha(10)],
                  ),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final bool isFirst = index == 0;
                    final bool isDifferentSender = !isFirst && _messages[index - 1].isUser != message.isUser;
                    
                    return Padding(
                      padding: EdgeInsets.only(top: isDifferentSender ? 20.0 : 8.0),
                      child: Column(
                        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          _buildPremiumChatBubble(message),
                          if (message.productos != null) _buildProductList(message.productos!),
                        ],
                      ),
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

  Widget _buildProductList(List<Map<String, dynamic>> productos) {
    return Container(
      height: 260, 
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: productos.length,
        itemBuilder: (context, index) {
          final p = productos[index];
          
          return GestureDetector(
            onTap: () {
              // MAPEAMOS EL JSON AL MODELO PERFUME (Con la corrección del String para 'ml')
              final perfumeParaDetalles = Perfume(
                id: p['id']?.toString() ?? '',
                nombre: p['nombre']?.toString() ?? 'Sin nombre',
                marca: p['marca']?.toString() ?? 'Genérico',
                precio: double.tryParse(p['precio'].toString()) ?? 0.0,
                ml: p['ml']?.toString() ?? '', // <--- CORRECCIÓN AQUÍ
                sexo: p['sexo']?.toString() ?? 'Unisex',
                imagenUrl: p['imagen_url']?.toString() ?? '',
                notasOlfativas: p['notas_olfativas'] != null 
                    ? Map<String, dynamic>.from(p['notas_olfativas']) 
                    : {},
              );

              // NAVEGAMOS A LA VISTA DE DETALLES PREMIUM
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetallesView(perfume: perfumeParaDetalles), 
                ),
              );
            },
            child: Container(
              width: 290,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colorSuperficie,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorDorado.withAlpha(40)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['marca'], 
                    style: TextStyle(color: colorDorado, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p['nombre'], 
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                  
                  const SizedBox(height: 14),
                  
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorFondo.withAlpha(150),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorLiris.withAlpha(60), width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome, color: colorDorado, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '"${p['descripcion_ia']}"', 
                              style: TextStyle(
                                color: Colors.white.withAlpha(220), 
                                fontSize: 13, 
                                height: 1.4,
                                fontStyle: FontStyle.italic, 
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 14),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${p['ml']}ml", style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12)),
                          const SizedBox(height: 2),
                          Text("\$${p['precio']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorDorado.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorDorado.withAlpha(50)),
                        ),
                        child: Row(
                          children: [
                            Text("Ver detalles", style: TextStyle(color: colorDorado, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, color: colorDorado, size: 10),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildElegantHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: colorFondo,
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(15), width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
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
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('En linea', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

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
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
            ),
            boxShadow: [
              if (!isUser) BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 5, offset: const Offset(0, 2)),
            ],
          ),
          child: Text(
            message.text, 
            style: TextStyle(color: isUser ? Colors.white : Colors.white.withAlpha(230), fontSize: 15, height: 1.4),
          ),
        ),
      ),
    );
  }

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
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: colorDorado.withAlpha(200))),
              const SizedBox(width: 12),
              Text("Liris esta escribiendo...", style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 13, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTextInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), 
      decoration: BoxDecoration(color: colorFondo, border: Border(top: BorderSide(color: Colors.white.withAlpha(10), width: 1))),
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
                maxLines: 4, 
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Preguntale a Liris...",
                  hintStyle: TextStyle(color: Colors.white.withAlpha(100)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: colorDorado,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: colorDorado.withAlpha(60), blurRadius: 8, offset: const Offset(0, 4))],
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