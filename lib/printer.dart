import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class ThermalPrinter {
  final String printerDeviceName = 'InnerPrinter';

  Future<String> find() async {
    final List<BluetoothInfo> pairedDevices = await PrintBluetoothThermal.pairedBluetooths;
    for (BluetoothInfo bluetooth in pairedDevices) {
      if (bluetooth.name == printerDeviceName) {
        return bluetooth.macAdress;
      }
    }
    return '';
  }


}