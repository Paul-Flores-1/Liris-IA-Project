import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Vistas
import 'vistas/catalogo.dart';
import 'vistas/iniciosesion.dart';

// Providers
import 'providers/favorites_provider.dart';

// --- Constantes de Diseño ---
const Color colorFondoPrincipal = Color(0xFF181818);
const Color colorAcentoLiris = Color(0xFF8B5A8E);
const Color colorDorado = Color(0xFFD9AD00);

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
          primaryColor: colorAcentoLiris,
          scaffoldBackgroundColor: colorFondoPrincipal,
          colorScheme: const ColorScheme.dark(
            primary: colorAcentoLiris,
            secondary: colorDorado,
            surface: Color(0xFF2A2A2A),
          ),
          useMaterial3: true,
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
    
    
    return user == null ? const InicioSesionView() : const CatalogoView();
  }
}