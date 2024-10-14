import 'dart:developer';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class TicketPreparer {
  Future<List<int>> prepareFromJsonObject(jsonObject) async {
    try {
      return await _prepare(jsonObject);
    } on Exception catch (_) {
      log(_.toString());
      rethrow;
    }
  }

  _prepare(jsonObject) async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    bytes += generator.reset();
    for (var item in jsonObject) {
      if (item['type'] == 'text') {
        PosStyles styles = PosStyles(
          align: item['styles']?['align'] == 'center'
              ? PosAlign.center
              : item['styles']?['align'] == 'right'
              ? PosAlign.right
              : PosAlign.left,
          bold: item['styles']?['bold'] ?? false,
        );
        bytes += generator.text(item['text'], styles: styles);
      } else if (item['type'] == 'rows') {
        List<PosColumn> columns = [];
        for (var column in item['columns']) {
          PosStyles styles = PosStyles(
            align: column['styles']?['align'] == 'center'
                ? PosAlign.center
                : column['styles']?['align'] == 'right'
                ? PosAlign.right
                : PosAlign.left,
            bold: column['styles']?['bold'] ?? false,
          );

          columns.add(PosColumn(
            text: column['text'],
            width: column['width'],
            styles: styles
          ));
        }
        bytes += generator.row(columns);
      }
    }
    bytes += generator.feed(2);
    return bytes;
  }
}
