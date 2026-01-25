import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/app_bar.dart';
import 'analysis_screen.dart';

// Pantalla principal que gestiona la búsqueda y conexión de dispositivos Bluetooth.
// Permite al usuario escanear dispositivos disponibles e identificar la nariz electrónica.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// Estado que gestiona el escaneo de dispositivos Bluetooth y la UI de selección.
class _MainScreenState extends State<MainScreen> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    // Se inicia el flujo de permisos y escaneo automáticamente.
    initBluetoothFlow();

    // Se escuchan los resultados del escaneo en tiempo real.
    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          // Se obtienen los IDs de los dispositivos ya mostrados.
          final existingIds = scanResults.map((r) => r.device.remoteId).toSet();
          
          // Se filtran solo dispositivos nuevos con nombre que no estén duplicados.
          final filteredResults = results.where((r) {
            final name = r.device.platformName;
            return name.isNotEmpty && !existingIds.contains(r.device.remoteId);
          });
          
          // Se agregan los dispositivos nuevos a la lista.
          scanResults.addAll(filteredResults);
        });
      }
    });

    // Se escucha el estado de escaneo para mostrar indicador de carga.
    FlutterBluePlus.isScanning.listen((scanning) {
      if (mounted) {
        setState(() => isScanning = scanning);
      }
    });
  }

  // Desconecta todos los dispositivos activos y reinicia el escaneo.
  // Útil para limpiar conexiones previas antes de buscar nuevos dispositivos.
  Future<void> disconnectAllAndScan() async {
    // Se obtienen todos los dispositivos actualmente conectados.
    List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
    
    // Se desconectan todos para liberar recursos.
    for (BluetoothDevice device in connectedDevices) {
      await device.disconnect();
      debugPrint("Dispositivo ${device.platformName} desconectado automáticamente.");
    }

    // Se inicia un nuevo escaneo después de la limpieza.
    startScan();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se ejecuta la limpieza automática al volver a esta pantalla.
    disconnectAllAndScan();
  }

  // Solicita permisos necesarios para Bluetooth en Android.
  // Incluye permisos de escaneo, conexión y ubicación.
  Future<void> initBluetoothFlow() async {
    // Se solicitan los tres permisos requeridos para Bluetooth.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Se verifica que ambos permisos Bluetooth hayan sido otorgados.
    if (statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted) {
      // Se procede con el escaneo si los permisos están disponibles.
      startScan();
    } else {
      // Se notifica al usuario si falta algún permiso.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Se necesitan permisos para buscar la nariz")),
      );
    }
  }

  // Inicia el escaneo de dispositivos Bluetooth disponibles.
  // Incluye dispositivos ya conectados y busca nuevos durante 15 segundos.
  Future<void> startScan() async {
    // Se detiene cualquier escaneo previo por seguridad.
    await FlutterBluePlus.stopScan();

    // Se obtienen los dispositivos ya conectados.
    List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
    
    // Se convierten los dispositivos conectados a ScanResult para mostrarlos en la UI.
    List<ScanResult> connectedResults = connectedDevices.map((device) {
      return ScanResult(
        device: device,
        advertisementData: AdvertisementData(
          advName: device.platformName,
          txPowerLevel: null,
          connectable: true,
          serviceUuids: [],
          manufacturerData: {},
          serviceData: {},
          appearance: 0,
        ),
        rssi: -10,
        timeStamp: DateTime.now(),
      );
    }).toList();

    setState(() {
      // Se inicializa la lista con los dispositivos ya conectados.
      scanResults = connectedResults;
    });

    // Se inicia el escaneo normal para buscar dispositivos no conectados.
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomSearchAppBar(
        title: "Dispositivos Disponibles",
        onSearchPressed: () => startScan(),
        onSettingsPressed: null,
      ),

      body: Column(
        children: [
          const SizedBox(height: 5),
          if (isScanning)
            const LinearProgressIndicator(backgroundColor: Colors.blue),

          const SizedBox(height: 5),

          Expanded(
            child: scanResults.isEmpty
                ? const Center(child: Text("Buscando nariz electrónica..."))
                : ListView.builder(
                    itemCount: scanResults.length,
                    itemBuilder: (context, index) {
                      final data = scanResults[index];
                      final deviceName = data.device.platformName;
                      
                      // Se identifica si es la nariz electrónica buscando palabras clave.
                      bool isENose = deviceName.toUpperCase().contains("NOSE") || 
                                    deviceName.toUpperCase().contains("ESP32");

                      // Se monitorea el estado de conexión en tiempo real con StreamBuilder.
                      return StreamBuilder<BluetoothConnectionState>(
                        stream: data.device.connectionState,
                        initialData: BluetoothConnectionState.disconnected,
                        builder: (c, snapshot) {
                          final isConnected = snapshot.data == BluetoothConnectionState.connected;

                          return Card(
                            elevation: isENose ? 4 : 1,
                            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: isENose ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none,
                            ),
                            color: isENose ? Colors.blue.shade50 : Colors.white,
                            child: ListTile(
                              leading: Icon(
                                isENose ? Icons.psychology : Icons.bluetooth,
                                color: isENose ? Colors.blue.shade700 : Colors.grey,
                              ),
                              title: Text(
                                isENose ? "NARIZ ELECTRÓNICA: $deviceName" : deviceName,
                                style: TextStyle(
                                  fontWeight: isENose ? FontWeight.bold : FontWeight.normal,
                                  color: isENose ? Colors.blue.shade900 : Colors.black87,
                                ),
                              ),
                              subtitle: Text(isConnected ? "CONECTADO" : data.device.remoteId.toString()),

                              onTap: () async {
                                // Se detiene el escaneo si el dispositivo aún no está conectado.
                                if (!isConnected) {
                                  await FlutterBluePlus.stopScan();
                                  // Se establece la conexión.
                                  await data.device.connect();
                                }
                                
                                // Se navega a la pantalla de análisis.
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AnalysisScreen(device: data.device),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}