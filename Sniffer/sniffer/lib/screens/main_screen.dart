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
          // 1. Obtenemos los IDs de los dispositivos ya conectados
          final existingIds = scanResults.map((r) => r.device.remoteId).toSet();
          
          // 2. Filtramos los nuevos: que tengan nombre Y que no estén repetidos
          final filteredResults = results.where((r) {
            final name = r.device.platformName;
            return name.isNotEmpty && !existingIds.contains(r.device.remoteId);
          });
          
          scanResults.addAll(filteredResults);
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

  Future<void> disconnectAllAndScan() async {
    // 1. Buscamos dispositivos que la App tenga conectados actualmente
    List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
    
    // 2. Los desconectamos todos para liberar el hardware
    for (BluetoothDevice device in connectedDevices) {
      await device.disconnect();
      debugPrint("Dispositivo ${device.platformName} desconectado automáticamente.");
    }

    // 3. Una vez limpio, iniciamos el escaneo normal
    startScan();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Al volver a la pantalla principal, ejecutamos la limpieza automática
    disconnectAllAndScan();
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

  Future<void> startScan() async {
    // 1. Detener escaneo previo por seguridad
    await FlutterBluePlus.stopScan();

    // 2. Obtener los dispositivos que ya están conectados [Importante para tu TFG]
    List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
    
    // 3. Convertirlos a ScanResult para que la interfaz los vea
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
        rssi: -10, // Valor ficticio para dispositivos conectados
        timeStamp: DateTime.now(),
      );
    }).toList();

    setState(() {
      // Inicializamos la lista con los ya conectados
      scanResults = connectedResults;
    });

    // 4. Iniciar escaneo normal para buscar los que NO están conectados
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos tu barra azul personalizada
      appBar: CustomSearchAppBar(
        title: "Dispositivos Disponibles", // <--- Título de inicio
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
                      
                      // 1. Identificación de la Nariz Electrónica
                      bool isENose = deviceName.toUpperCase().contains("NOSE") || 
                                    deviceName.toUpperCase().contains("ESP32");

                      // 2. Comprobación de estado de conexión
                      // Usamos el stream para saber si ya estamos conectados a este dispositivo
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
                                if (!isConnected) {
                                  await FlutterBluePlus.stopScan();
                                  await data.device.connect();
                                }
                                
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