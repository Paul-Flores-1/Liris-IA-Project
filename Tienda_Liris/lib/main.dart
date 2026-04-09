import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para bloquear la rotación
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Vistas
import 'vistas/catalogo.dart';
import 'vistas/iniciosesion.dart';

// Providers
import 'providers/favorites_provider.dart';

// --- Constantes de Diseño Premium Liris ---
const Color colorFondoPrincipal = Color(0xFF0A0A0A); // Un negro más profundo para móviles OLED
const Color colorDorado = Color(0xFFD9AD00);
const Color colorSuperficie = Color(0xFF1A1A1A);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- BLOQUEO DE ROTACIÓN ---
  // Esto asegura que Liris se mantenga siempre en vertical (Portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
        // Escucha cambios en el estado de autenticación
        StreamProvider<User?>(
          create: (_) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        // Sincroniza el FavoritesProvider con el usuario actual
        ChangeNotifierProxyProvider<User?, FavoritesProvider>(
          create: (context) => FavoritesProvider(null),
          update: (context, user, previous) {
            if (previous == null) return FavoritesProvider(user?.uid);
            previous.updateUser(user?.uid);
            return previous;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Liris IA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: colorDorado,
          scaffoldBackgroundColor: colorFondoPrincipal,
          colorScheme: const ColorScheme.dark(
            primary: colorDorado,
            secondary: colorDorado,
            surface: colorSuperficie,
          ),
          useMaterial3: true,
          // Tipografía global elegante (puedes añadir fuentes personalizadas aquí)
          fontFamily: 'Georgia', 
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
    // El Provider nos dirá si hay una sesión activa o no
    final user = Provider.of<User?>(context);
    
    // Si no hay usuario, mandamos a Login. Si hay, directo al Catálogo.
    return user == null ? const InicioSesionView() : const CatalogoView();
  }
}