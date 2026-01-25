import 'package:flutter/material.dart';

// Barra de aplicación personalizada con diseño redondeado y acciones dinámicas.
// Se adapta según la pantalla actual mostrando botones de configuración o búsqueda.
class CustomSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onSearchPressed;
  final bool isSettingsScreen;
  final VoidCallback? onBackAction;

  const CustomSearchAppBar({
    super.key,
    required this.title,
    this.onSettingsPressed,
    this.onSearchPressed,
    this.isSettingsScreen = false,
    this.onBackAction,
  });

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 15, right: 15),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.blue.shade800,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            // Se muestra el botón izquierdo según el contexto.
            // En la pantalla de ajustes muestra flecha atrás, en otros casos botón de configuración.
            if (isSettingsScreen)
              // Se muestra un botón de retroceso en la pantalla de ajustes.
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBackAction ?? () => Navigator.pop(context),
              )
            else if (onSettingsPressed != null)
              // Se muestra el botón de configuración si se proporciona callback.
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: onSettingsPressed,
              )
            else
              // Se reserva espacio si no hay botón izquierdo.
              const SizedBox(width: 48),

            // Se muestra el título centrado con formato en mayúsculas.
            Expanded(
              child: Center(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),

            // Se muestra el botón derecho de búsqueda si se proporciona callback.
            if (onSearchPressed != null)
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: onSearchPressed,
              )
            else
              // Se reserva espacio si no hay botón derecho.
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}