import 'dart:convert';
import 'dart:developer';

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:restprinter/ticket_preparer.dart';
import 'package:shared_preferences/shared_preferences.dart'
    as shared_preferences;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class Service {
  final Function(String) messageUpdater;

  Service(this.messageUpdater);

  Handler get handler {
    final router = Router();
    router.get('/hello', (Request request) {
      messageUpdater("world!");
      return Response.ok('world!');
    });

    router.post('/print', (Request request) async {
      bool successPrint = await _receivePrintRequest(request);
      if (successPrint) {
        messageUpdater("Impreso correctamente");
        return Response.ok("success printed");
      }
      return Response.ok("not printed");
    });
    return router;
  }

  Future<bool> _receivePrintRequest(Request request) async {
    try {
      var bodyString = await request.readAsString();
      var printBody = jsonDecode(bodyString);
      log(printBody.toString());
      sendToPrinter(printBody);
    } catch (_) {
      log(_.toString());
      messageUpdater(_.toString());
      return false;
    }
    return true;
  }

  //https://pub.dev/packages/print_bluetooth_thermal
  Future<void> sendToPrinter(printBody) async {
    List<int> ticket = await TicketPreparer().prepareFromJsonObject(printBody);
    String? selectedDeviceMacAddress = await getSelectedDeviceMacAddress();
    String? selectedDeviceName = await getSelectedDeviceName();
    if (selectedDeviceMacAddress != null) {
      await PrintBluetoothThermal.connect(
          macPrinterAddress: selectedDeviceMacAddress);
      bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
      if (connectionStatus) {
        await PrintBluetoothThermal.writeBytes(ticket);
      } else {
        messageUpdater(
            "No se pudo imprimir usando: $selectedDeviceName ($selectedDeviceMacAddress)");
      }
    } else {
      messageUpdater("No se seleccionó un dispositivo");
    }
  }

  Future<String?> getSelectedDeviceMacAddress() async {
    final prefs = await shared_preferences.SharedPreferences.getInstance();
    String? macAddress = prefs.getString('selected_device_mac_address');
    log("printing on $macAddress");
    return macAddress;
  }

  Future<String?> getSelectedDeviceName() async {
    final prefs = await shared_preferences.SharedPreferences.getInstance();
    String? name = prefs.getString('selected_device_name');
    log("printing on $name");
    return name;
  }
}
