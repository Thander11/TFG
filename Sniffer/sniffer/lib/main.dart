import 'package:flutter/material.dart';
import 'screens/main_screen.dart'; // Importamos la pantalla principal

void main() {
  // Aseguramos que los bindings de Flutter estén listos antes de lanzar la app
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nariz Electrónica UEx',
      debugShowCheckedModeBanner: false, // Quitamos la etiqueta "Debug"
      
      // Personalizamos el tema con el azul de la UEx
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50, // Fondo suave para que resalten las Cards
      ),

      // La pantalla de inicio ahora es la MainScreen que creamos antes
      home: const MainScreen(),
    );
  }
}