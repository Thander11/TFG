import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSearchPressed;
  final VoidCallback onSettingsPressed;

  const CustomSearchAppBar({
    super.key, 
    required this.onSearchPressed, 
    required this.onSettingsPressed
  });

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 15, right: 15),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.blue.shade800,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: onSettingsPressed,
            ),
            const Expanded(
              child: Center(
                child: Text(
                  "NARIZ ELECTRÓNICA UEX", // Nombre del proyecto [cite: 2]
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () async {
              // 1. Pedir permisos antes de escanear
              Map<Permission, PermissionStatus> statuses = await [
                Permission.bluetoothScan,
                Permission.bluetoothConnect,
                Permission.location,
              ].request();

              // 2. Si están concedidos, empezar escaneo
              if (statuses[Permission.bluetoothScan]!.isGranted &&
                  statuses[Permission.location]!.isGranted) {
                FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
              } else {
                print("Permisos denegados por el usuario");
              }
            },
            ),
          ],
        ),
      ),
    );
  }
}