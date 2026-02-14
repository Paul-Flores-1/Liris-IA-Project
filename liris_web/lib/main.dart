import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
// Importamos las vistas
import 'vistas/catalogo.dart';
import 'vistas/liris.dart';
import 'vistas/iniciosesion.dart';
// Importamos los providers
import 'providers/favorites_provider.dart';

// --- Constantes de Colores ---
const Color colorFondoPrincipal = Color(0xFF181818);
const Color colorSuperficie = Color(0xFF2A2A2A);
const Color colorAcento = Color(0xFF4A2A4D);
const Color colorTexto = Colors.white;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<User?>(
          create: (_) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        ChangeNotifierProxyProvider<User?, FavoritesProvider>(
          create: (context) => FavoritesProvider(null),
          update: (context, user, previousFavorites) {
            if (previousFavorites == null) {
              return FavoritesProvider(user?.uid);
            }
            previousFavorites.updateUser(user?.uid);
            return previousFavorites;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Recomendador de Perfumes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: colorFondoPrincipal,
          primaryColor: colorAcento,
          colorScheme: ColorScheme.dark(
            primary: colorAcento,
            secondary: colorAcento,
            surface: colorSuperficie,
            onSurface: colorTexto,
            onPrimary: colorTexto,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: colorFondoPrincipal,
            elevation: 0,
            titleTextStyle: TextStyle(color: colorTexto, fontSize: 20, fontWeight: FontWeight.bold),
            iconTheme: IconThemeData(color: colorTexto),
          ),
          cardTheme: CardThemeData(
            color: colorSuperficie,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: colorSuperficie,
            labelStyle: const TextStyle(color: colorTexto),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide.none,
            selectedColor: colorAcento,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: colorSuperficie,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            labelStyle: const TextStyle(color: Colors.white70),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorAcento,
              foregroundColor: colorTexto,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: colorSuperficie,
            thickness: 1,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) {
      return const InicioSesionView();
    } else {
      return const MainScreen();
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  bool mostrarIA = true;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 1.0, // Iniciar visible
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleLiris() {
    setState(() {
      mostrarIA = !mostrarIA;
      if (mostrarIA) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double lirisWidth = MediaQuery.of(context).size.width * 0.25;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Catálogo siempre visible
          Positioned.fill(
            child: const CatalogoView(),
          ),
          
          // Panel de Liris con slide animation
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: lirisWidth,
            child: SlideTransition(
              position: _slideAnimation,
              child: const LirisView(),
            ),
          ),
          
          // Botón toggle
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Positioned(
                top: (screenHeight / 2) - 40,
                right: lirisWidth * _animationController.value,
                child: _buildToggleTab(),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildToggleTab() {
    final Color colorAcento = Theme.of(context).primaryColor;
    final Color colorTexto = Theme.of(context).colorScheme.onPrimary;

    return Container(
      width: 28,
      height: 80,
      decoration: BoxDecoration(
        color: colorAcento,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          onTap: _toggleLiris,
          child: Center(
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: mostrarIA ? 0 : 0.5,
              child: Icon(
                Icons.chevron_right_rounded,
                color: colorTexto,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}