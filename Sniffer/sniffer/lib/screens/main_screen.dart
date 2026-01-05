import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/app_bar.dart';
import 'analysis_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    // Iniciamos el flujo automático de permisos y escaneo
    initBluetoothFlow();

    // Escuchamos los resultados del escaneo
    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          // Filtramos para no mostrar dispositivos sin nombre (opcional)
          scanResults = results.where((r) => r.device.platformName.isNotEmpty).toList();
        });
      }
    });

    // Escuchamos si está escaneando para mostrar el indicador de carga
    FlutterBluePlus.isScanning.listen((scanning) {
      if (mounted) {
        setState(() => isScanning = scanning);
      }
    });
  }

  Future<void> initBluetoothFlow() async {
    // 1. Pedir permisos necesarios para Android
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted) {
      startScan();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Se necesitan permisos para buscar la nariz")),
      );
    }
  }

  void startScan() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      print("Error al iniciar escaneo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos tu barra azul personalizada
      appBar: CustomSearchAppBar(
        title: "Dispositivos Disponibles", // <--- Título de inicio
        onSearchPressed: () => startScan(),
        onSettingsPressed: () => print("Ajustes"),
      ),

      body: Column(
        children: [
          if (isScanning)
            const SizedBox(height: 5),
            const LinearProgressIndicator(backgroundColor: Colors.blue),

          const SizedBox(height: 5),

          Expanded(
            child: scanResults.isEmpty
                ? const Center(child: Text("Buscando nariz electrónica..."))
                : ListView.builder(
                    itemCount: scanResults.length,
                    itemBuilder: (context, index) {
                      final data = scanResults[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth, color: Colors.blue),
                          title: Text(data.device.platformName),
                          subtitle: Text(data.device.remoteId.toString()),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            // Detener escaneo antes de conectar
                            await FlutterBluePlus.stopScan();
                            
                            // Conectar y navegar
                            await data.device.connect();
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnalysisScreen(device: data.device),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}