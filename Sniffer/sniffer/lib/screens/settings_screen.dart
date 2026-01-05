import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../widgets/app_bar.dart';

class SettingsScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic? uartChar;
  final Function(String, bool)? onMessageSent;

  const SettingsScreen({super.key, required this.device, this.uartChar, this.onMessageSent});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int numCiclos = 1;
  int tiempoAdsorcion = 60;
  int tiempoDesorcion = 60;
  bool autoStop = true;
  bool vibracionActiva = true;
  String _bufferSettings = "";

  @override
  void initState() {
    super.initState();
    _leerConfiguracionActual();
  }

  void _leerConfiguracionActual() async {
    if (widget.uartChar != null) {
      _bufferSettings = "";
      await widget.uartChar!.write("SETTINGS\r\n".codeUnits);
      
      widget.uartChar!.lastValueStream.listen((value) {
        String textoRecibido = String.fromCharCodes(value);
        _bufferSettings += textoRecibido;

        if (_bufferSettings.contains("Number of cycles in AutoStop Mode:")) {
          _actualizarInterfazConSettings(_bufferSettings);
          _bufferSettings = ""; 
        }
      });
    }
  }

  void _actualizarInterfazConSettings(String data) {
    setState(() {
      try {
        if (data.contains("Desorption time:")) {
          String valor = data.split("Desorption time:")[1].split("s.")[0].trim();
          tiempoDesorcion = int.parse(valor);
        }
        if (data.contains("Adsorption time:")) {
          String valor = data.split("Adsorption time:")[1].split("s.")[0].trim();
          tiempoAdsorcion = int.parse(valor);
        }
        if (data.contains("Number of cycles in AutoStop Mode:")) {
          String valor = data.split("Number of cycles in AutoStop Mode:")[1].split(".")[0].trim();
          numCiclos = int.parse(valor);
        }
        if (data.contains("AutoStop Mode:")) {
          String estado = data.split("AutoStop Mode:")[1].split(".")[0].trim();
          autoStop = (estado.toLowerCase().contains("enabled"));
        }
      } catch (e) {
        debugPrint("Error al sincronizar: $e");
      }
    });
  }

  Future<void> _enviarComando(String cmd) async {
    if (widget.uartChar != null) {
      await widget.uartChar!.write("$cmd\r\n".codeUnits);
      
      // Si pasamos la función desde la otra pantalla, lo escribimos en la consola
      if (widget.onMessageSent != null) {
        widget.onMessageSent!(">> Enviando: $cmd", true);
      }
      
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomSearchAppBar(
        title: "Ajustes del Sistema",
        isSettingsScreen: true,
        // Al volver con la flecha, no se hace nada (cancelar)
        onBackAction: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle("Parámetros de Ciclo"),
          _buildNumberSetting("Número de Ciclos", numCiclos, (val) {
            if (val >= 1) setState(() => numCiclos = val);
          }, paso: 1),
          _buildNumberSetting("Tiempo Adsorción (s)", tiempoAdsorcion, (val) {
            if (val >= 30) setState(() => tiempoAdsorcion = val);
          }, paso: 30), // Múltiplos de 30
          _buildNumberSetting("Tiempo Desorción (s)", tiempoDesorcion, (val) {
            if (val >= 30) setState(() => tiempoDesorcion = val);
          }, paso: 30), // Múltiplos de 30
          const Divider(),
          _buildSectionTitle("Preferencias de la App"),
          SwitchListTile(
            title: const Text("AutoStop Inteligente"),
            value: autoStop,
            onChanged: (val) => setState(() => autoStop = val),
          ),
          SwitchListTile(
            title: const Text("Vibración de Alerta"),
            value: vibracionActiva,
            onChanged: (val) => setState(() => vibracionActiva = val),
          ),
          const SizedBox(height: 30),
          
          // BOTÓN CONFIRMAR
          ElevatedButton(
            onPressed: () async {
              // Ráfaga de comandos según manual v1.5
              await _enviarComando("#NSNC,$numCiclos");
              await _enviarComando("#NSTA,$tiempoAdsorcion");
              await _enviarComando("#NSTD,$tiempoDesorcion");
              await _enviarComando("#NSAS,${autoStop ? 1 : 0}");
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Configuración enviada a la eNOSE"),
                    backgroundColor: Colors.blue,
                  ),
                );
                Navigator.pop(context); // Regresa a AnalysisScreen
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("CONFIRMAR CAMBIOS", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildNumberSetting(String label, int value, Function(int) onChanged, {int paso = 1}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => onChanged(value - paso)),
            Text("$value", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => onChanged(value + paso)),
          ],
        ),
      ],
    );
  }
}