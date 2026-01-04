import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'package:tflite_flutter/tflite_flutter.dart';

class AnalysisScreen extends StatefulWidget {
  final BluetoothDevice device;
  const AnalysisScreen({super.key, required this.device});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  BluetoothCharacteristic? uartChar;
  String lastData = "Esperando datos...";
  String? selectedModel = "hachis-Plus.tflite"; // Aquí conectarás tus .tflite
  bool isAnalyzing = false;
  Timer? timeoutTimer;

  @override
  void initState() {
    super.initState();
    loadModel(selectedModel!); // Cargamos el primer modelo al entrar
    connectToDevice();
  }

  // Función para cargar el archivo .tflite
  Future<void> loadModel(String modelName) async {
    try {
      await Interpreter.fromAsset('assets/$modelName');
      print("Modelo $modelName cargado correctamente");
    } catch (e) {
      print("Error al cargar el modelo: $e");
    }
  }

  void onModelChanged(String? newModel) {
    if (newModel != null) {
      setState(() {
        selectedModel = newModel;
      });
      loadModel(newModel);
    }
  }

  void runInference(List<double> inputData) {
    // Por ahora, simulamos la IA hasta que carguemos el .tflite
    // Supongamos que el sensor de gas es el índice 4 y sube de 500 cuando hay algo
    double valorGas = inputData[4]; 

    print("Analizando datos con IA...");

    if (valorGas > 800) { // Este umbral lo decidirá tu Red Neuronal
      print("¡SUSTANCIA DETECTADA!");
      stopDetection(true); // Detenemos todo y avisamos
    }
  }

  void stopDetection(bool positivo) {
    timeoutTimer?.cancel(); // Cancelamos el cronómetro de 30s
    
    setState(() {
      isAnalyzing = false;
    });

    // Enviamos comando STOP a la placa para que deje de gastar batería/sensores
    sendCommand("Stop");

    // Mostramos el resultado
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(positivo ? "¡Sustancia Detectada!" : "Fin de tiempo"),
        content: Text(positivo 
          ? "La Red Neuronal ha identificado la sustancia correctamente." 
          : "No se ha detectado nada en el tiempo establecido."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  void connectToDevice() async {
    try {
      // 1. Esperamos a que el dispositivo esté realmente conectado
      // A veces Navigator.push ocurre mientras el estado aún es "connecting"
      await widget.device.connectionState.where((s) => s == BluetoothConnectionState.connected).first;
      
      // 2. Pequeño respiro para el hardware (RN4871)
      await Future.delayed(const Duration(milliseconds: 500));

      print("Estado confirmado: Conectado. Descubriendo servicios...");

      List<BluetoothService> services = await widget.device.discoverServices();
      
      for (var service in services) {
        // UUID del servicio transparente según el manual 
        if (service.uuid.toString() == "49535343-fe7d-4ae5-8fa9-9fafd205e455") {
          for (var char in service.characteristics) {
            if (char.uuid.toString().contains("9616")) { 
              uartChar = char;
              await char.setNotifyValue(true);
              
              char.lastValueStream.listen((value) {
                String rawLine = String.fromCharCodes(value);
                setState(() => lastData = rawLine);
                
                // Pre-procesador para los sensores (BME688, SGP40, etc.) [cite: 44, 48]
                List<String> tokens = rawLine.trim().split(RegExp(r'\s+'));
                if (tokens.length >= 10 && isAnalyzing) {
                  List<double> sensorValues = tokens.map((t) => double.tryParse(t) ?? 0.0).toList();
                  runInference(sensorValues);
                }
              });
            }
          }
        }
      }
    } catch (e) {
      print("Error en la conexión: $e");
    }
  }

  void sendCommand(String cmd) async {
    if (uartChar != null) {
      await uartChar!.write("$cmd\r\n".codeUnits);
    }
  }

  void startDetection() {
    setState(() => isAnalyzing = true);
    // Timer de seguridad (por ejemplo 30 segundos)
    timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (isAnalyzing) {
        setState(() => isAnalyzing = false);
        showDialog(context: context, builder: (_) => const AlertDialog(title: Text("Tiempo agotado"), content: Text("No se detectó la sustancia.")));
      }
    });
  }

  void checkNeuralNetwork(String data) {
    // AQUÍ irá tu lógica de TFLite
    // Si detección > umbral:
    // setState(() => isAnalyzing = false); 
    // timeoutTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Análisis de Sustancia")),
      body: Column(
        children: [
          // Selector de modelo para elegir entre Keras/PyTorch
          DropdownButton<String>(
            value: selectedModel,
            onChanged: onModelChanged,
            items: ["hachis-Plus.tflite", "hachis.tflite"].map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(val == "hachis-Plus.tflite" ? "Hachís Plus" : "Hachís"),
              );
            }).toList(),
          ),
          
          // Visualización de datos crudos de la nariz
          Text("Última lectura: $lastData"),

          const Spacer(),

          // Botón principal de control
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: isAnalyzing ? null : () {
                startDetection(); // Inicia el cronómetro de la app
                sendCommand("Exper"); // Envía el comando de inicio a la placa 
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: Colors.green,
              ),
              child: Text(isAnalyzing ? "DETECTANDO..." : "INICIAR EXPERIMENTO"),
            ),
          ),
          
          // Botón de parada de emergencia
          TextButton(
            onPressed: () => stopDetection(false), 
            child: const Text("CANCELAR", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }
}