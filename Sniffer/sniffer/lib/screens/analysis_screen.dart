import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../widgets/app_bar.dart';
import 'package:flutter/services.dart';

class AnalysisScreen extends StatefulWidget {
  final BluetoothDevice device;
  const AnalysisScreen({super.key, required this.device});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class ConsoleMessage {
  final String text;
  final bool isCommand; // true si lo envía la app, false si viene de la nariz

  ConsoleMessage(this.text, this.isCommand);
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  BluetoothCharacteristic? uartChar;
  List<ConsoleMessage> consoleHistory = [];
  String? selectedModel = "hachis-Plus.tflite"; // Aquí conectarás tus .tflite
  bool isAnalyzing = false;
  double resultadoIA = 0.0; // Resultado de la inferencia de la IA
  Timer? timeoutTimer;
  DateTime lastCommandTime = DateTime.now();
  Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    loadModel(selectedModel!); // Cargamos el primer modelo al entrar
    connectToDevice();
  }

  // Función para cargar el archivo .tflite
  Future<void> loadModel(String modelName) async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/$modelName');
      debugPrint("Modelo $modelName cargado correctamente");
    } catch (e) {
      debugPrint("Error al cargar el modelo: $e");
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
    if (_interpreter == null) return;

    // El modelo espera una lista de 13 valores (forma [1, 13])
    var input = [inputData]; 
    // La salida es la probabilidad (forma [1, 1])
    var output = List<double>.filled(1, 0).reshape([1, 1]);

    try {
      _interpreter!.run(input, output);

      setState(() {
        resultadoIA = output[0][0]; // Probabilidad entre 0.0 y 1.0
      });

      // Nueva lógica: Vibración y parada si supera el 0.7 (70%)
      if (resultadoIA >= 0.7) { 
        // Hacemos que el móvil vibre de forma intermitente (patrón de alerta)
        HapticFeedback.vibrate(); 
        print("¡ALERTA! Probabilidad alta detectada: ${resultadoIA}");
        
        // Detener la detección automáticamente si ya estamos seguros
        stopDetection(true); 
      }
    } catch (e) {
      debugPrint("Error durante la inferencia: $e");
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
                String rawLine = String.fromCharCodes(value).trim();
                
                if (rawLine.isNotEmpty) {
                  // FILTRO: No mostrar si es el eco de un comando o basura del sistema
                  bool esEco = rawLine == "Exper" || rawLine == "Stop" || rawLine.contains("Wrong command");
                  
                  if (!esEco) {
                    addMessage(rawLine, false); // Solo mostramos datos reales
                    
                    // Procesamos para la IA (esto ya aplica el filtro Aire/muestra != 0)
                    List<double>? inputIA = procesarTramaParaIA(rawLine);
                    if (inputIA != null && isAnalyzing) {
                      runInference(inputIA);
                    }
                  }
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
    // Evita enviar el mismo comando si se pulsó hace menos de 500ms
    if (DateTime.now().difference(lastCommandTime).inMilliseconds < 500) return;
    
    if (uartChar != null) {
      lastCommandTime = DateTime.now();
      await uartChar!.write("$cmd\r\n".codeUnits);
      addMessage(">> Enviando: $cmd", true);
    }
  }

  void addMessage(String text, bool isCommand) {
    setState(() {
      // Insertamos al principio para que lo nuevo aparezca arriba
      consoleHistory.insert(0, ConsoleMessage(text, isCommand));
      
      // Limitamos a 100 mensajes para no ralentizar el móvil
      if (consoleHistory.length > 100) consoleHistory.removeLast();
    });
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

  List<double>? procesarTramaParaIA(String rawLine) {
    // 1. Quita el espacio al inicio y al final (Regla: La primera fila de datos tiene un espacio al inicio)
    String cleanLine = rawLine.trim();

    // 2. Elimina la primera fila del archivo (Título: "Cabecera experimento NoseCris")
    // También filtramos otros mensajes decorativos del firmware para evitar errores
    if (cleanLine.isEmpty || 
        cleanLine.contains('Cabecera') || 
        cleanLine.contains('eNOSE v3') || 
        cleanLine.contains('====') ||
        cleanLine.contains('Starting Test') ||
        cleanLine.contains('SW Version')) {
      return null;
    }

    // 3. Ignorar la fila de nombres de columnas (nº, Co2(scd40)...)
    // Es necesario para que el programa no intente convertir texto en números
    if (cleanLine.startsWith('nº')) {
      return null;
    }

    // 4. Separación por comas (Regla: Cambia comas por espacios en Python, aquí las usamos como separador)
    // Nota: Dart usa el punto como decimal por defecto, así que no necesitamos cambiar puntos por comas.
    List<String> tokens = cleanLine.split(',');

    // 5. Verificación de la columna 'Aire/muestra' (Es la última columna, índice 21)
    if (tokens.length >= 22) {
      // Intentamos obtener el valor de la columna 21
      double aireMuestra = double.tryParse(tokens[21]) ?? 0.0;

      // Regla: Elimina las filas cuya columna Aire/muestra es 0
      if (aireMuestra == 0) {
        return null; 
      }

      try {
        // 6. Selección de columnas (Elimina 'nº', 'temp(scd40)', 'hum(scd40)', etc.)
        // Solo devolvemos las 13 columnas que tu script Python mantiene para el entrenamiento:
        return [
          double.parse(tokens[1]),  // Co2(scd40)
          double.parse(tokens[4]),  // raw_signla(sgp40)
          double.parse(tokens[5]),  // aiq(ens160)
          double.parse(tokens[6]),  // tvoc(ens160)
          double.parse(tokens[7]),  // eco2(ens160)
          double.parse(tokens[8]),  // rs1(ens160)
          double.parse(tokens[9]),  // rs3(ens160)
          double.parse(tokens[10]), // rs4(ens160)
          double.parse(tokens[12]), // rmox(zmod4410)
          double.parse(tokens[14]), // tvoc(zmod4410)
          double.parse(tokens[15]), // eco2(zmod4410)
          double.parse(tokens[16]), // iaq(zmod4410)
          double.parse(tokens[20]), // resistencia(bme688)
        ];
      } catch (e) {
        // Si alguna columna no es un número válido (ej. una celda vacía), devolvemos null
        debugPrint("Error al parsear fila de datos: $e");
        return null;
      }
    }

    return null; // Si la línea no tiene suficientes columnas
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
      appBar: CustomSearchAppBar(
        title: "Análisis de Muestra",
        onSettingsPressed: () => Navigator.pop(context),
        onSearchPressed: () async {
          await widget.device.disconnect();
          if (context.mounted) Navigator.pop(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Selector de Modelo (Parte Superior)
            Text("Modelo Detector", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedModel,
                  isExpanded: true,
                  onChanged: onModelChanged,
                  items: ["hachis-Plus.tflite", "modelo.tflite"].map((String val) {
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(val == "hachis-Plus.tflite" ? "Modelo Hachís Plus" : "Modelo Base"),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. Área de Sensores (Ocupa todo el espacio central)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E), // Fondo negro terminal
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade900, width: 2),
                ),
                child: ListView.builder(
                  reverse: true, // Mantiene el scroll abajo o muestra lo nuevo arriba
                  padding: const EdgeInsets.all(10),
                  itemCount: consoleHistory.length,
                  itemBuilder: (context, index) {
                    final msg = consoleHistory[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          // VERDE para datos de sensores, NARANJA/AMARILLO para tus comandos
                          color: msg.isCommand ? Colors.orangeAccent : Colors.greenAccent,
                          fontWeight: msg.isCommand ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                // Ahora cambia a rojo a partir de 0.7
                color: resultadoIA >= 0.7 ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: resultadoIA >= 0.7 ? Colors.red : Colors.green,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    resultadoIA >= 0.7 ? "¡SUSTANCIA DETECTADA!" : "AIRE LIMPIO",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: resultadoIA >= 0.7 ? Colors.red.shade900 : Colors.green.shade900,
                    ),
                  ),
                  Text("Umbral: ${(resultadoIA * 100).toStringAsFixed(1)}%"),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // 3. Botones de Control (Parte Inferior)
            Row(
              children: [
                // Botón Cancelar
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (isAnalyzing) {
                        sendCommand("Stop");
                        setState(() => isAnalyzing = false);
                        timeoutTimer?.cancel();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text("CANCELAR"),
                  ),
                ),
                const SizedBox(width: 15),
                // Botón Iniciar
                Expanded(
                  child: ElevatedButton(
                    onPressed: isAnalyzing ? null : () {
                      startDetection();
                      sendCommand("Exper"); // Comando del manual para iniciar
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(isAnalyzing ? "ANALIZANDO..." : "INICIAR"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Espacio extra para no pegar al borde
          ],
        ),
      ),
    );
  }
}