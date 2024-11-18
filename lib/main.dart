import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restprinter/service.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart'; // Asegúrate de tener el paquete instalado

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

  final int _serverPort = 8443;
  final String _schema = 'https';
  HttpServer? _server;
  bool _isServerRunning = false;

  // Bluetooth-related variables
  List<BluetoothInfo> _pairedDevices = [];
  String? _selectedDeviceMacAddress;

  @override
  void initState() {
    super.initState();
    _loadPairedDevices().then((e) => {
       _loadSavedDevice()
    });
    _startServer();
  }

  @override
  void dispose() {
    _stopServer();
    super.dispose();
  }

  Future<void> _startServer() async {
    if (_isServerRunning) return;

    final securityContext = await this._getSecurityContext();
    final service = Service(this.showSnackBarMessage);

    final server = await HttpServer.bindSecure(
      InternetAddress.anyIPv4,
      _serverPort, // Puerto
      securityContext,
    );
    shelf_io.serveRequests(server, service.handler);
    final ipAddress = await _getLocalIpAddress();

    setState(() {
      _server = server;
      _ipAddress = ipAddress.toString();
      _serverAccess = '$_schema://$_ipAddress:$_serverPort';
      _isServerRunning = true;
    });

    print('Servidor iniciado en: $_serverAccess');
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

  Future<void> _refresh() async {
    _refreshServerAccess();
    _loadPairedDevices();
  }

  Future<SecurityContext> _getSecurityContext() async {
    final cert = await rootBundle.loadString('assets/cert.pem');
    final key = await rootBundle.loadString('assets/key.pem');

    final securityContext = SecurityContext()
      ..useCertificateChainBytes(cert.codeUnits)
      ..usePrivateKeyBytes(key.codeUnits);
    return securityContext;
  }

  Future<void> _refreshServerAccess() async {
    if (_isServerRunning) {
      final ipAddress = await _getLocalIpAddress();
      setState(() {
        _ipAddress = ipAddress;
        _serverAccess = '$_schema://$_ipAddress:$_serverPort';
      });
    }
    showSnackBarMessage('IP actualizada: $_serverAccess');
  }

  void showSnackBarMessage(message){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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

  Future<void> _loadPairedDevices() async {
    final List<BluetoothInfo> pairedDevices =
    await PrintBluetoothThermal.pairedBluetooths;

    setState(() {
      _pairedDevices = pairedDevices;
    });
  }

  // Save selected Bluetooth device in SharedPreferences
  Future<void> _saveSelectedDevice(BluetoothInfo device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_device_name', device.name);
    await prefs.setString('selected_device_mac_address', device.macAdress);
    setState(() {
      _selectedDeviceMacAddress = device.macAdress;
    });
  }

  // Load the saved Bluetooth device from SharedPreferences
  Future<void> _loadSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    String? macAddress = prefs.getString('selected_device_mac_address');
    if (macAddress != null) {
      bool isExistsSelectedDeviceInCurrentDevices = this._pairedDevices.where((p) => p.macAdress == macAddress).isNotEmpty;
      if (isExistsSelectedDeviceInCurrentDevices) {
        setState(() {
        _selectedDeviceMacAddress = macAddress;
      });
      }
    }
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
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            if (_isServerRunning)
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: Icon(Icons.refresh),
                label: Text('Actualizar'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                ),
              ),
            const SizedBox(height: 20),
            if (_pairedDevices.isNotEmpty)
              DropdownButton<String>(
                value: _selectedDeviceMacAddress,
                hint: Text("Seleccionar dispositivo Bluetooth"),
                onChanged: (String? newAddress) {
                  final selectedDevice = _pairedDevices.firstWhere(
                          (device) => device.macAdress == newAddress);
                  _saveSelectedDevice(selectedDevice);
                },
                items: _pairedDevices.map((BluetoothInfo device) {
                  return DropdownMenuItem<String>(
                    value: device.macAdress, // Use address as the value
                    child: Text(device.name),
                  );
                }).toList(),
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
