import 'dart:io';

import 'package:flutter/material.dart';
import 'package:restprinter/service.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Printer Server',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _ipAddress = '';
  String _serverAccess = 'Cargando...';
  int _serverPort = 8000;
  HttpServer? _server;

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  @override
  void dispose() {
    _server?.close();
    super.dispose();
  }

  Future<void> _startServer() async {
    final service = Service();
    final server = await shelf_io.serve(
        service.handler, InternetAddress.anyIPv4, _serverPort);
    final ipAddress = await _getLocalIpAddress();

    setState(() {
      _server = server;
      _ipAddress = ipAddress.toString();
      _serverAccess = '$_ipAddress:$_serverPort';
    });

    print('Servidor iniciado en: http://$_serverAccess');
  }

  Future<String> _getLocalIpAddress() async {
    var interfaces = await NetworkInterface.list();
    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return 'No se encontró IP local';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Printer Server"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Acceso al servidor:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              _serverAccess,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'SOLICITUDES DISPONIBLES',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const Text(
              '/hello [GET] (Probar conexion)',
              textAlign: TextAlign.center,
            ),
            const Text(
              '/print [POST] (Imprimir)',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
