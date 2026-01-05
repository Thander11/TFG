import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../screens/settings_screen.dart';
import '../screens/main_screen.dart'; 

class AppNavigation {
  // Función para ir a AJUSTES
  static void goToSettings(
    BuildContext context, 
    BluetoothDevice device, 
    BluetoothCharacteristic? uartChar,
    {Function(String, bool)? onMessageSent} // Añade esta línea
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          device: device,
          uartChar: uartChar,
          onMessageSent: onMessageSent, // Pasa la función aquí
        ),
      ),
    );
  }

  // Función para ir (o volver) a la PANTALLA PRINCIPAL
  static void goToHome(BuildContext context) {
    // Usamos pushAndRemoveUntil para que la pantalla principal sea la única en la pila.
    // Esto evita que si el usuario da a "atrás" en el móvil, vuelva a entrar en un análisis ya cerrado.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false, // Elimina todas las rutas anteriores
    );
  }
}