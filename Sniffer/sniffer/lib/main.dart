import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
            return ListView(
              children: (snapshot.data ?? [])
                  .map((r) => ListTile(
                        title: Text(r.device.platformName.isEmpty ? "Desconocido" : r.device.platformName),
                        subtitle: Text(r.device.remoteId.toString()),
                        onTap: () => print("Conectando a: ${r.device.remoteId}"),
                      ))
                  .toList(),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.search),
          onPressed: () => FlutterBluePlus.startScan(timeout: const Duration(seconds: 4)),
        ),
      ),
    );
  }
}