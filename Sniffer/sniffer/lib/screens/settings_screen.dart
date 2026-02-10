import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../widgets/app_bar.dart';

// Pantalla de configuración del sistema que permite ajustar parámetros
// de ciclos, tiempos y preferencias de la aplicación.
class SettingsScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic? uartChar;
  final Function(String, bool)? onMessageSent;

  const SettingsScreen({super.key, required this.device, this.uartChar, this.onMessageSent});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// Estado que gestiona la configuración y sincronización de parámetros del dispositivo.
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

  // Lee la configuración actual del dispositivo enviando el comando SETTINGS.
  void _leerConfiguracionActual() async {
    if (widget.uartChar != null) {
      // Se limpia el buffer antes de enviar el comando.
      _bufferSettings = "";
      // Se envía el comando SETTINGS para obtener la configuración actual.
      await widget.uartChar!.write("SETTINGS\r\n".codeUnits);
      
      // Se escucha la respuesta del dispositivo.
      widget.uartChar!.lastValueStream.listen((value) {
        // Se convierte la respuesta de bytes a cadena.
        String textoRecibido = String.fromCharCodes(value);
        _bufferSettings += textoRecibido;

        // Se verifica que la respuesta sea completa antes de procesar.
        if (_bufferSettings.contains("Number of cycles in AutoStop Mode:")) {
          _actualizarInterfazConSettings(_bufferSettings);
          _bufferSettings = ""; 
        }
      });
    }
  }

  // Actualiza la interfaz gráfica con los valores de configuración recibidos del dispositivo.
  void _actualizarInterfazConSettings(String data) {
    setState(() {
      try {
        // Se extrae el tiempo de desorción de la respuesta.
        if (data.contains("Desorption time:")) {
          String valor = data.split("Desorption time:")[1].split("s.")[0].trim();
          tiempoDesorcion = int.parse(valor);
        }
        // Se extrae el tiempo de adsorción de la respuesta.
        if (data.contains("Adsorption time:")) {
          String valor = data.split("Adsorption time:")[1].split("s.")[0].trim();
          tiempoAdsorcion = int.parse(valor);
        }
        // Se extrae el número de ciclos de la respuesta.
        if (data.contains("Number of cycles in AutoStop Mode:")) {
          String valor = data.split("Number of cycles in AutoStop Mode:")[1].split(".")[0].trim();
          numCiclos = int.parse(valor);
        }
        // Se extrae el estado de AutoStop de la respuesta.
        if (data.contains("AutoStop Mode:")) {
          String estado = data.split("AutoStop Mode:")[1].split(".")[0].trim();
          autoStop = (estado.toLowerCase().contains("enabled"));
        }
      } catch (e) {
        debugPrint("Error al sincronizar: $e");
      }
    });
  }

  // Envía un comando al dispositivo a través de Bluetooth.
  // Opcionalmente notifica a la pantalla anterior mediante callback.
  Future<void> _enviarComando(String cmd) async {
    if (widget.uartChar != null) {
      // Se envía el comando codificado en formato UART.
      await widget.uartChar!.write("$cmd\r\n".codeUnits);
      
      // Se notifica a la pantalla anterior si se proporcionó el callback.
      if (widget.onMessageSent != null) {
        widget.onMessageSent!(">> Enviando: $cmd", true);
      }
      
      // Se añade un pequeño retardo entre comandos para asegurar procesamiento.
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomSearchAppBar(
        title: "Ajustes del Sistema",
        isSettingsScreen: true,
        // Se retorna sin confirmar al presionar la flecha atrás.
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
          
          // Se envía una ráfaga de comandos para aplicar la nueva configuración.
          ElevatedButton(
            onPressed: () async {
              // Se envían todos los comandos según el manual del dispositivo v1.5.
              // Comando para número de ciclos.
              await _enviarComando("#NSNC,$numCiclos");
              // Comando para tiempo de adsorción.
              await _enviarComando("#NSTA,$tiempoAdsorcion");
              // Comando para tiempo de desorción.
              await _enviarComando("#NSTD,$tiempoDesorcion");
              // Comando para habilitar/deshabilitar AutoStop.
              await _enviarComando("#NSAS,${autoStop ? 1 : 0}");
              
              // Se muestra una confirmación visual de que la configuración fue aplicada.
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      "Configuración aplicada correctamente",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    // Se ajusta el margen para que aparezca en la parte superior.
                    margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height - 160,
                      left: 20,
                      right: 20,
                    ),
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
                // Se retorna a la pantalla anterior enviando el estado de vibración.
                Navigator.pop(context, vibracionActiva);
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

  // Construye el widget de título de una sección.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  // Construye un widget para ajustar valores numéricos con botones incremento/decremento.
  // Permite especificar el paso de incremento entre cambios.
  Widget _buildNumberSetting(String label, int value, Function(int) onChanged, {int paso = 1}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            // Botón para decrementar el valor.
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => onChanged(value - paso)),
            // Se muestra el valor actual con énfasis.
            Text("$value", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // Botón para incrementar el valor.
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => onChanged(value + paso)),
          ],
        ),
      ],
    );
  }
}