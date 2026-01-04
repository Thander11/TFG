import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Nariz Electrónica - Buscando...')),
        body: StreamBuilder<List<ScanResult>>(
          stream: FlutterBluePlus.scanResults,
          builder: (c, snapshot) {
            // 1. Filtramos los resultados: 
            // Que el nombre no esté vacío y (opcionalmente) que contenga "RN" o "Microchip"
            final filteredResults = (snapshot.data ?? [])
                .where((r) => r.device.platformName.isNotEmpty) 
                .toList();

            return ListView(
              children: filteredResults
                  .map((r) => ListTile(
                        title: Text(r.device.platformName),
                        subtitle: Text(r.device.remoteId.toString()),
                        leading: const Icon(Icons.bluetooth_connected, color: Colors.blue),
                        trailing: Text("${r.rssi} dBm"), // Esto te dice la distancia
                        onTap: () => print("Conectando a: ${r.device.remoteId}"),
                      ))
                  .toList(),
            );
          },
        ),
                floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.search),
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
      ),
    );
  }
}