import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sniffer/utils/navigation.dart';
import 'dart:async';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../widgets/app_bar.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

// Pantalla de análisis de muestras que gestiona la comunicación Bluetooth
// y la ejecución de modelos de inteligencia artificial para detección de sustancias.
class AnalysisScreen extends StatefulWidget {
  final BluetoothDevice device;
  const AnalysisScreen({super.key, required this.device});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

// Representa un mensaje que aparece en la consola de la pantalla de análisis.
// Se diferencia entre comandos enviados por la aplicación y datos recibidos del dispositivo.
class ConsoleMessage {
  final String text;
  final bool isCommand;

  ConsoleMessage(this.text, this.isCommand);
}

// Almacena la configuración y parámetros estadísticos de un modelo de red neuronal.
// Contiene la información necesaria para normalizar datos antes de la inferencia.
class ModelConfig {
  final String id;
  final String displayName;
  final String fileName;
  final List<double> medias;
  final List<double> desviaciones;

  ModelConfig({
    required this.id,
    required this.displayName,
    required this.fileName,
    required this.medias,
    required this.desviaciones,
  });

  // Convierte los datos JSON en una instancia de ModelConfig.
  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? 'Sin nombre',
      fileName: json['fileName'] ?? '',
      medias: List<double>.from(json['medias'].map((x) => x.toDouble())),
      desviaciones: List<double>.from(json['desviaciones'].map((x) => x.toDouble())),
    );
  }
}

// Estado de la pantalla de análisis que gestiona la lógica de detección y comunicación.
class _AnalysisScreenState extends State<AnalysisScreen> {
  BluetoothCharacteristic? uartChar;
  List<ConsoleMessage> consoleHistory = [];
  String? selectedModel = "modelo_hachis-plus.tflite";
  bool isAnalyzing = false;
  double resultadoIA = 0.0;
  Timer? timeoutTimer;
  DateTime lastCommandTime = DateTime.now();
  Interpreter? _interpreter;
  bool vibracionActiva = true;
  String _rawBuffer = "";
  List<ModelConfig> availableConfigs = [];
  ModelConfig? currentConfig;

  @override
  void initState() {
    super.initState();
    loadJsonConfigs();
    connectToDevice();
  }

  // Carga la configuración de modelos desde el archivo JSON almacenado en assets.
  Future<void> loadJsonConfigs() async {
    try {
      debugPrint("Iniciando carga de JSON...");
      final String response = await rootBundle.loadString('assets/models_config.json');
      final data = json.decode(response);
      
      final List<ModelConfig> loadedConfigs = (data['models'] as List)
          .map((m) => ModelConfig.fromJson(m))
          .toList();

      setState(() {
        availableConfigs = loadedConfigs;
        if (availableConfigs.isNotEmpty) {
          currentConfig = availableConfigs.first;
          // Cargamos el archivo .tflite del primer modelo por defecto
          loadModel(currentConfig!.fileName); 
        }
      });
      debugPrint("Modelos cargados: ${availableConfigs.length}");
    } catch (e) {
      debugPrint("ERROR cargando JSON de modelos: $e");
    }
  }

  // Carga un modelo de red neuronal TFLite especificado por su nombre de archivo.
  Future<void> loadModel(String fileName) async {
    try {
      _interpreter = await Interpreter.fromAsset("assets/$fileName"); 
      debugPrint("Modelo $fileName cargado exitosamente.");
    } catch (e) {
      debugPrint("Error al cargar el archivo TFLite: $e");
      _interpreter = null;
    }
  }

  // Actualiza el modelo seleccionado y carga el archivo TFLite correspondiente.
  void onModelChanged(String? newModel) {
    if (newModel != null) {
      setState(() {
        selectedModel = newModel;
      });
      loadModel(newModel);
    }
  }

  // Detiene el análisis completamente y muestra un diálogo informativo.
  void detenerTodo({required String titulo, required String mensaje, bool enviarStop = true}) {
    if (enviarStop) {
      sendCommand("Stop");
    }

    setState(() {
      isAnalyzing = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  // Muestra un diálogo final con el resultado de la detección.
  void _mostrarDialogoFin(String titulo, String mensaje) {
    setState(() {
      isAnalyzing = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ENTENDIDO", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // Establece la conexión con el dispositivo Bluetooth y descubre sus servicios.
  void connectToDevice() async {
    try {
      // Se espera a que el dispositivo esté completamente conectado.
      await widget.device.connectionState.where((s) => s == BluetoothConnectionState.connected).first;
      
      // Se añade un pequeño retardo para permitir que el hardware se estabilice.
      await Future.delayed(const Duration(milliseconds: 500));

      print("Estado confirmado: Conectado. Descubriendo servicios...");

      // Se descubren todos los servicios disponibles en el dispositivo.
      List<BluetoothService> services = await widget.device.discoverServices();
      
      for (var service in services) {
        // Se busca el servicio UART transparente específico del dispositivo.
        if (service.uuid.toString() == "49535343-fe7d-4ae5-8fa9-9fafd205e455") {
          for (var char in service.characteristics) {
            // Se identifica la característica de comunicación UART.
            if (char.uuid.toString().contains("9616")) { 
              uartChar = char;
              // Se habilitan las notificaciones para recibir datos en tiempo real.
              await char.setNotifyValue(true);

              // Escucha los datos recibidos del dispositivo Bluetooth y los procesa.
              char.lastValueStream.listen((value) {
                // Se acumulan los bytes recibidos en el buffer.
                _rawBuffer += String.fromCharCodes(value);

                // Se procesan solo cuando se recibe un salto de línea completo.
                if (_rawBuffer.contains('\n')) {
                  // Se divide el buffer por saltos de línea en caso de múltiples tramas juntas.
                  List<String> lines = _rawBuffer.split('\n');
                  // Se preserva la última línea incompleta para la siguiente iteración.
                  _rawBuffer = lines.removeLast();

                  for (String line in lines) {
                    String rawLine = line.trim();
                    if (rawLine.isEmpty) continue;

                    // Se detectan señales de finalización automática del experimento.
                    if (rawLine == "STOP" || rawLine.contains("AutoStop Mode enabled")) {
                      if (isAnalyzing) {
                        setState(() => isAnalyzing = false);
                        _mostrarDialogoFin("Experimento Finalizado", "La nariz ha completado los ciclos.");
                      }
                      continue;
                    }

                    // Se filtran los ecos de comandos (líneas que comienzan con #).
                    if (rawLine.startsWith("#")) continue;

                    // Se valida que no sea un comando enviado previamente.
                    if (rawLine != "Exper" && rawLine != "Stop" && rawLine != "SETTINGS") {
                      // Se trata especialmente el mensaje de confirmación OK.
                      if (rawLine == "OK") {
                        addMessage("OK - Comando aceptado", false);
                      } else {
                        // Se procesan los datos de sensores para la inferencia de IA.
                        List<double>? datosLimpios = procesarTramaParaIA(rawLine);
                        if (datosLimpios != null && isAnalyzing) {
                          checkNeuralNetwork(datosLimpios); 
                        }
                        // Se muestran los datos en la consola.
                        addMessage(rawLine, false);
                      }
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

  // Envía un comando al dispositivo Bluetooth.
  // Incluye un sistema de anticebo para evitar envíos duplicados.
  void sendCommand(String cmd) async {
    if (DateTime.now().difference(lastCommandTime).inMilliseconds < 500) return;
    
    if (uartChar != null) {
      lastCommandTime = DateTime.now();
      await uartChar!.write("$cmd\r\n".codeUnits);
      addMessage(">> Enviando: $cmd", true);
    }
  }

  // Añade un mensaje al historial de consola.
  // Limita el historial a 100 mensajes para optimizar el rendimiento.
  void addMessage(String text, bool isCommand) {
    setState(() {
      consoleHistory.insert(0, ConsoleMessage(text, isCommand));
      if (consoleHistory.length > 100) consoleHistory.removeLast();
    });
  }

  // Inicia el proceso de detección y resetea el resultado anterior.
  void startDetection() {
    setState(() {
      isAnalyzing = true;
      resultadoIA = 0.0;
    });
  }

  // Procesa una trama de datos del dispositivo para extraer los valores de sensores.
  // Valida que se encuentre en la fase de muestra y retorna los 13 valores de gas.
  List<double>? procesarTramaParaIA(String rawLine) {
    // Se limpia la trama de prefijos y espacios innecesarios.
    String cleanLine = rawLine.replaceAll('>> Recibido: ', '').trim();
    // Se divide la cadena por comas para extraer los tokens individuales.
    List<String> tokens = cleanLine.split(',');

    // Se valida que la trama contenga suficientes valores.
    if (tokens.length >= 21) {
      // Se definen los índices de los 13 sensores de gas a extraer.
      List<int> indicesGas = [1, 4, 5, 6, 7, 8, 9, 10, 12, 14, 15, 16, 20];
      List<double> sensoresLimpios = [];

      try {
        // Se extraen los valores en los índices especificados y se convierten a double.
        for (int idx in indicesGas) {
          String valorS = tokens[idx].trim().replaceAll(',', '.');
          sensoresLimpios.add(double.parse(valorS));
        }

        // Se obtiene el indicador de fase (Aire=0, Muestra=1) del final de la trama.
        int idxFase = tokens.length - 1; 
        double fase = double.tryParse(tokens[idxFase].trim().replaceAll(',', '.')) ?? 0.0;
        
        // Se retornan los sensores solo si la fase es Muestra (1.0).
        if (fase == 1.0) return sensoresLimpios;
        
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Ejecuta la red neuronal con los datos de sensores normalizados.
  // Normaliza los datos usando las medias y desviaciones del modelo configurado.
  Future<void> checkNeuralNetwork(List<double> inputData) async {
    // Se valida que el intérprete TFLite esté cargado.
    if (_interpreter == null) {
      debugPrint("Inferencia abortada: El intérprete aún no está cargado.");
      return;
    }
    
    // Se valida que exista una configuración de modelo seleccionada.
    if (currentConfig == null) {
      debugPrint("Inferencia abortada: No hay configuración de modelo seleccionada.");
      return;
    }

    final medias = currentConfig!.medias;
    final desviaciones = currentConfig!.desviaciones;
    try {
      // Se normalizan los datos de entrada utilizando la media y desviación estándar.
      List<double> xScaled = [];
      for (int i = 0; i < inputData.length; i++) {
        // Se evita división por cero usando 1.0 como valor por defecto.
        double std = desviaciones[i] == 0 ? 1.0 : desviaciones[i];
        // Se aplica la fórmula de normalización: (valor - media) / desviación.
        xScaled.add((inputData[i] - medias[i]) / std);
      }

      // Se reshape los datos a la forma esperada por el modelo [1, 13].
      var input = xScaled.reshape([1, 13]); 
      // Se prepara el tensor de salida para almacenar la probabilidad.
      var output = List.filled(1, 0.0).reshape([1, 1]);

      // Se ejecuta la inferencia con los datos normalizados.
      _interpreter!.run(input, output);
    
      // Se extrae la probabilidad de resultado.
      double probabilidad = output[0][0];

      // Se actualiza el estado con el nuevo resultado.
      setState(() {
        resultadoIA = probabilidad;
      });

      // Se activa la vibración si la probabilidad supera el umbral y la vibración está habilitada.
      if (resultadoIA >= 0.7 && vibracionActiva) {
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 500);
        }
      }
    } catch (e) {
      debugPrint("Error en inferencia: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomSearchAppBar(
        title: "Análisis de Muestra",
        onSettingsPressed: () async {
          // Seguimos usando tu función original, pero capturando el resultado
          final resultado = await AppNavigation.goToSettings(
            context, 
            widget.device, 
            uartChar,
            onMessageSent: (text, isCommand) => addMessage(text, isCommand),
          );

          // Si el usuario pulsó CONFIRMAR, recibiremos el booleano
          if (resultado != null) {
            setState(() {
              vibracionActiva = resultado;
            });
            debugPrint("Sincronizado: Vibración = $vibracionActiva");
          }
        },
        onSearchPressed: () => AppNavigation.goToHome(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Modelo Detector", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
            const SizedBox(height: 10),
            currentConfig == null 
            ? CircularProgressIndicator()
            : Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ModelConfig>(
                  value: currentConfig,
                  isExpanded: true,
                  items: availableConfigs.map((ModelConfig config) {
                    return DropdownMenuItem<ModelConfig>(
                      value: config,
                      child: Text(config.displayName),
                    );
                  }).toList(),
                  onChanged: (ModelConfig? newValue) {
                    if (newValue != null) {
                      setState(() {
                        currentConfig = newValue;
                        resultadoIA = 0.0;
                      });
                      loadModel(newValue.fileName);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
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
                  Text("Impureza: ${(resultadoIA * 100).toStringAsFixed(1)}%"),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
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
