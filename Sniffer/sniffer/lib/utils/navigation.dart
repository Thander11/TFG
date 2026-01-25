import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../screens/settings_screen.dart';
import '../screens/main_screen.dart'; 

// Clase utilitaria que centraliza la navegación entre pantallas de la aplicación.
// Proporciona métodos estáticos para transiciones entre pantallas con parámetros específicos.
class AppNavigation {
  
  // Navega a la pantalla de ajustes del sistema.
  // Retorna un valor booleano que indica si la vibración está habilitada después de confirmar.
  static Future<bool?> goToSettings(
    BuildContext context, 
    BluetoothDevice device, 
    BluetoothCharacteristic? uartChar,
    {required Function(String, bool) onMessageSent}
  ) {
    // Se navega a la pantalla de ajustes con contexto tipo push.
    // El retorno es un valor booleano que indica el estado de vibración.
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

  // Navega a la pantalla principal eliminando todo el historial de navegación.
  // Evita que el usuario pueda volver a pantallas cerradas presionando la tecla atrás del dispositivo.
  static void goToHome(BuildContext context) {
    // Se utiliza pushAndRemoveUntil para reemplazar toda la pila de navegación.
    // Esto asegura que la pantalla principal sea el punto de entrada único.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }
}