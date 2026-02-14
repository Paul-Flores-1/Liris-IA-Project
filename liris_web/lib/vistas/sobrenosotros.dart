import 'package:flutter/material.dart';

class SobreNosotrosView extends StatelessWidget {
  const SobreNosotrosView({super.key});

  @override
  Widget build(BuildContext context) {
    final Color colorFondo = Theme.of(context).scaffoldBackgroundColor;
    final Color colorSuperficie = Theme.of(context).cardTheme.color ?? const Color(0xFF2A2A2A);
    final Color colorDorado = const Color(0xFFD9AD00);
    final Color colorTexto = Theme.of(context).colorScheme.onSurface;
    final Color colorTextoSecundario = colorTexto.withAlpha(179);

    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: const Text('Sobre Nosotros'),
        backgroundColor: colorFondo,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HERO SECTION CON LOGO ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 24.0),
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
                  // Logo
                  Image.asset(
                    'assets/images/logo_paul_floress.png',
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.store, size: 100, color: colorDorado),
                  ),
                  const SizedBox(height: 24),
                  // Título principal
                  Text(
                    'Paul Flores Perfumes',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: colorDorado,
                      letterSpacing: 2.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Subtítulo
                  Text(
                    'Elegancia y Distinción en Cada Fragancia',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- NUESTRA HISTORIA ---
                    _buildSectionCard(
                      context,
                      icon: Icons.history,
                      iconColor: colorDorado,
                      title: 'Nuestra Historia',
                      content:
                          'Fundada en 2024, Paul Flores Perfumes nace de la pasión por las fragancias de lujo y el deseo de ofrecer perfumes exclusivos y de alta calidad. '
                          'Hoy nos enorgullece ser referentes en el mundo de la perfumería.\n\n'
                          'Siempre tratamos que cada cliente encuentre el aroma perfecto que refleje su personalidad y estilo único.',
                      colorSuperficie: colorSuperficie,
                      colorTexto: colorTexto,
                      colorTextoSecundario: colorTextoSecundario,
                    ),

                    const SizedBox(height: 24),

                    // --- NUESTRA MISIÓN ---
                    _buildSectionCard(
                      context,
                      icon: Icons.flag_outlined,
                      iconColor: colorDorado,
                      title: 'Nuestra Misión',
                      content:
                          'Inspirar confianza y elegancia a través de fragancias excepcionales que celebran la individualidad de cada persona. '
                          'Nos comprometemos a ofrecer productos auténticos, un servicio personalizado y una experiencia de compra memorable.\n\n'
                          'Creemos que un perfume es más que un accesorio: es una extensión de tu identidad, un recuerdo inolvidable y una firma personal que te distingue.',
                      colorSuperficie: colorSuperficie,
                      colorTexto: colorTexto,
                      colorTextoSecundario: colorTextoSecundario,
                    ),

                    const SizedBox(height: 24),

                    // --- NUESTROS VALORES ---
                    _buildSectionCard(
                      context,
                      icon: Icons.workspace_premium_outlined,
                      iconColor: colorDorado,
                      title: 'Nuestros Valores',
                      content: '',
                      colorSuperficie: colorSuperficie,
                      colorTexto: colorTexto,
                      colorTextoSecundario: colorTextoSecundario,
                      extraWidget: Column(
                        children: [
                          _buildValueItem(
                            Icons.verified_outlined,
                            'Autenticidad',
                            'Garantizamos productos 100% originales de las mejores casas de perfumería.',
                            colorDorado,
                            colorTexto,
                            colorTextoSecundario,
                          ),
                          const SizedBox(height: 16),
                          _buildValueItem(
                            Icons.star_outline,
                            'Calidad',
                            'Seleccionamos solo fragancias de la más alta calidad y prestigio internacional.',
                            colorDorado,
                            colorTexto,
                            colorTextoSecundario,
                          ),
                          const SizedBox(height: 16),
                          _buildValueItem(
                            Icons.favorite_outline,
                            'Pasión',
                            'Amamos lo que hacemos y nos dedicamos a compartir nuestra pasión por las fragancias.',
                            colorDorado,
                            colorTexto,
                            colorTextoSecundario,
                          ),
                          const SizedBox(height: 16),
                          _buildValueItem(
                            Icons.people_outline,
                            'Atención Personalizada',
                            'Cada cliente es único y merece un servicio excepcional y asesoramiento.',
                            colorDorado,
                            colorTexto,
                            colorTextoSecundario,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- POR QUÉ ELEGIRNOS ---
                    _buildSectionCard(
                      context,
                      icon: Icons.diamond_outlined,
                      iconColor: colorDorado,
                      title: '¿Por Qué Elegirnos?',
                      content: '',
                      colorSuperficie: colorSuperficie,
                      colorTexto: colorTexto,
                      colorTextoSecundario: colorTextoSecundario,
                      extraWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBenefitItem(
                            '-',
                            'Colección Exclusiva',
                            'Acceso a fragancias de las marcas más prestigiosas del mundo.',
                            colorTexto,
                            colorTextoSecundario,
                          ),
                          _buildBenefitItem(
                            '-',
                            'Envío Seguro',
                            'Empaque premium y envío rápido para que tu perfume llegue en perfectas condiciones.',
                            colorTexto,
                            colorTextoSecundario,
                          ),
                          _buildBenefitItem(
                            '-',
                            'Asesoría Experta',
                            'Nuestro equipo te ayuda a encontrar la fragancia perfecta para cada ocasión.',
                            colorTexto,
                            colorTextoSecundario,
                          ),
                          _buildBenefitItem(
                            '-',
                            'Experiencia Premium',
                            'Desde la selección hasta la entrega, cada detalle está cuidado para ofrecerte lo mejor.',
                            colorTexto,
                            colorTextoSecundario,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- NUESTRO EQUIPO (OPCIONAL) ---
                    _buildSectionCard(
                      context,
                      icon: Icons.groups_outlined,
                      iconColor: colorDorado,
                      title: 'Nuestro Equipo',
                      content:
                          'Somos un equipo apasionado de especialistas en perfumería con años de experiencia en el sector. '
                          'Cada miembro de Paul Flores Perfumes está comprometido con brindarte la mejor experiencia, desde el momento en que visitas nuestra tienda hasta que disfrutas tu fragancia favorita.\n\n'
                          'Nos mantenemos constantemente actualizados sobre las últimas tendencias y lanzamientos del mundo de la perfumería para ofrecerte siempre lo más nuevo y exclusivo.',
                      colorSuperficie: colorSuperficie,
                      colorTexto: colorTexto,
                      colorTextoSecundario: colorTextoSecundario,
                    ),

                    const SizedBox(height: 32),

                    // --- LLAMADO A LA ACCIÓN ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorDorado.withAlpha(51),
                            colorSuperficie,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorDorado.withAlpha(102),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 48,
                            color: colorDorado,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Gracias por Elegirnos',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorTexto,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tu confianza es nuestro mayor logro. Estamos aquí para ayudarte a encontrar el perfume perfecto que cuente tu historia.',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorTextoSecundario,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back, color: Colors.black),
                            label: const Text(
                              'Volver al Catálogo',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorDorado,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  // --- WIDGET HELPER: CARD DE SECCIÓN ---
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

  // --- WIDGET HELPER: ITEM DE VALOR ---
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
              Text(
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

  // --- WIDGET HELPER: ITEM DE BENEFICIO ---
  Widget _buildBenefitItem(
    String emoji,
    String title,
    String description,
    Color colorTexto,
    Color colorTextoSecundario,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colorTexto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
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
      ),
    );
  }
}