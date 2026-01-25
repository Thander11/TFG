import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

// Punto de entrada principal de la aplicación.
// Se inicializan los bindings de Flutter y se ejecuta la aplicación.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// Widget principal que configura la aplicación.
// Define el tema visual y establece la pantalla de inicio.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nariz Electrónica UEx',
      debugShowCheckedModeBanner: false,
      
      // Se personaliza el tema con los colores de la Universidad de Extremadura.
      // Utiliza Material Design 3 con un fondo suave para resaltar los elementos.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50,
      ),

      // Se establece MainScreen como la pantalla inicial de la aplicación.
      home: const MainScreen(),
    );
  }
}