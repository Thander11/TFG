import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../screens/settings_screen.dart';
import '../screens/main_screen.dart'; 

class AppNavigation {
  // Función para ir a AJUSTES
  static Future<bool?> goToSettings(
    BuildContext context, 
    BluetoothDevice device, 
    BluetoothCharacteristic? uartChar,
    {required Function(String, bool) onMessageSent}
  ) {
    // Añadimos el return para que devuelva lo que diga el Navigator
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          device: device,
          uartChar: uartChar,
          onMessageSent: onMessageSent,
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