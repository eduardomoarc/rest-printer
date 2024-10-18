import 'dart:async';
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
  bool _isServerRunning = false;

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  @override
  void dispose() {
    _stopServer();
    super.dispose();
  }

  Future<void> _startServer() async {
    if (_isServerRunning) return;

    final service = Service();
    final server = await shelf_io.serve(
        service.handler, InternetAddress.anyIPv4, _serverPort);
    final ipAddress = await _getLocalIpAddress();

    setState(() {
      _server = server;
      _ipAddress = ipAddress.toString();
      _serverAccess = '$_ipAddress:$_serverPort';
      _isServerRunning = true;
    });

    print('Servidor iniciado en: http://$_serverAccess');
  }

  Future<void> _stopServer() async {
    if (!_isServerRunning) return;

    await _server?.close();
    setState(() {
      _server = null;
      _serverAccess = 'Servidor detenido';
      _isServerRunning = false;
    });

    print('Servidor detenido');
  }

  Future<void> _refreshServerAccess() async {
    if (_isServerRunning) {
      final ipAddress = await _getLocalIpAddress();
      setState(() {
        _ipAddress = ipAddress;
        _serverAccess = '$_ipAddress:$_serverPort';
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('IP actualizada: $_serverAccess'),
      ),
    );
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
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueAccent,
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
            if (!_isServerRunning)
              IconButton(
                icon: Icon(Icons.play_arrow, color: Colors.green, size: 50),
                onPressed: _startServer,
              )
            else
              IconButton(
                icon: Icon(Icons.stop, color: Colors.red, size: 50),
                onPressed: _stopServer,
              ),
            const SizedBox(height: 20),
            if (_isServerRunning)
              ElevatedButton.icon(
                onPressed: _refreshServerAccess,
                icon: Icon(Icons.refresh),
                label: Text('Actualizar IP'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'SOLICITUDES DISPONIBLES',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
