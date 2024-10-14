import 'dart:convert';
import 'dart:developer';

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:restprinter/printer.dart';
import 'package:restprinter/ticket_preparer.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class Service {
  Handler get handler {
    final router = Router();
    router.get('/hello', (Request request) {
      return Response.ok('world!');
    });

    router.post('/print', (Request request) async {
      var bodyString = await request.readAsString();
      var printBody = json.decode(bodyString);
      print(printBody);
      return Response.ok("success printed");
    });
    return router;
  }

  //https://pub.dev/packages/print_bluetooth_thermal
  Future<void> print(printBody) async {
    List<int> ticket = await TicketPreparer().prepareFromJsonObject(printBody);
    String mac = await ThermalPrinter().find();
    log("printing on $mac");
    await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      // await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 1, text: "test"));
      await PrintBluetoothThermal.writeBytes(ticket);
    }
  }

}