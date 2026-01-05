import 'package:flutter/material.dart';

class CustomSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onSearchPressed;
  final bool isSettingsScreen; // Nueva variable para saber si estamos en ajustes
  final VoidCallback? onBackAction;

  const CustomSearchAppBar({
    super.key,
    required this.title,
    this.onSettingsPressed,
    this.onSearchPressed,
    this.isSettingsScreen = false, // Por defecto es falso
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
            // Lógica dinámica para el botón izquierdo
            if (isSettingsScreen)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBackAction ?? () => Navigator.pop(context), // Vuelve a la pantalla de análisis e informa del cambio
              )
            else if (onSettingsPressed != null)
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: onSettingsPressed,
              )
            else
              const SizedBox(width: 48),

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

            if (onSearchPressed != null)
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: onSearchPressed,
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}