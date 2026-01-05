import 'package:flutter/material.dart';

class CustomSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title; // <--- Nueva variable
  final VoidCallback onSearchPressed;
  final VoidCallback onSettingsPressed;

  const CustomSearchAppBar({
    super.key,
    required this.title, // <--- Obligatorio pasar el título
    required this.onSearchPressed,
    required this.onSettingsPressed,
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
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: onSettingsPressed,
            ),
            Expanded(
              child: Center(
                child: Text(
                  title.toUpperCase(), // <--- Usamos el título aquí
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 13,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: onSearchPressed,
            ),
          ],
        ),
      ),
    );
  }
}