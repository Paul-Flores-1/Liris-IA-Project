import 'package:flutter/material.dart';

class SobreNosotrosView extends StatelessWidget {
  const SobreNosotrosView({super.key});

  @override
  Widget build(BuildContext context) {
    // Paleta de colores Premium Liris
    final Color colorFondo = const Color(0xFF0A0A0A);
    final Color colorSuperficie = const Color(0xFF1A1A1A);
    final Color colorDorado = const Color(0xFFD9AD00);
    final Color colorTexto = Colors.white;
    final Color colorTextoSecundario = Colors.white70;

    return Scaffold(
      backgroundColor: colorFondo,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- APP BAR CON LOGO ---
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: colorSuperficie,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'LIRIS PERFUMES',
                style: TextStyle(
                  color: colorDorado,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 3,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colorDorado.withAlpha(30), colorFondo],
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'logo_sobrenosotros',
                    child: Image.asset(
                      'assets/images/logo_paul_floress.png',
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.auto_awesome, size: 80, color: colorDorado),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- CONTENIDO ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  _buildSectionCard(
                    icon: Icons.history,
                    title: 'Nuestra Historia',
                    content: 'Fundada en 2024, Liris Perfumes nace de la pasión por las fragancias de lujo y el deseo de ofrecer piezas exclusivas. '
                        'Nos enorgullece ser el destino favorito de quienes buscan un aroma que cuente su propia historia.',
                    colorSuperficie: colorSuperficie,
                    colorDorado: colorDorado,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    icon: Icons.flag_outlined,
                    title: 'Nuestra Misión',
                    content: 'Inspirar confianza y elegancia a través de fragancias excepcionales. '
                        'Cada perfume en nuestra colección es una extensión de la identidad de nuestros clientes.',
                    colorSuperficie: colorSuperficie,
                    colorDorado: colorDorado,
                  ),
                  const SizedBox(height: 24),
                  
                  // --- SECCIÓN DE VALORES ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'NUESTROS VALORES',
                      style: TextStyle(color: colorDorado, letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildValueItem(Icons.verified_user_outlined, 'Autenticidad', 'Productos 100% originales.', colorDorado),
                  _buildValueItem(Icons.star_outline, 'Calidad', 'Solo las mejores casas de perfumería.', colorDorado),
                  _buildValueItem(Icons.favorite_border, 'Pasión', 'Amamos el arte de la fragancia.', colorDorado),
                  
                  const SizedBox(height: 40),
                  
                  // --- CTA FINAL ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: colorSuperficie,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorDorado.withAlpha(50)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.auto_awesome, color: colorDorado, size: 40),
                        const SizedBox(height: 16),
                        const Text(
                          'Encuentra tu firma personal',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorDorado,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('VOLVER AL CATÁLOGO', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
    required Color colorSuperficie,
    required Color colorDorado,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorSuperficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorDorado, size: 28),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildValueItem(IconData icon, String title, String sub, Color colorDorado) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: colorDorado.withAlpha(30), shape: BoxShape.circle),
          child: Icon(icon, color: colorDorado, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ),
    );
  }
}