import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class Service {
  Handler get handler {
    final router = Router();
    router.get('/hello', (Request request) {
      return Response.ok('world!');
    });
    return router;
  }

}