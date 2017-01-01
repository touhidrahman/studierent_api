import 'dart:io';
import 'package:logging/logging.dart';
import 'package:rpc/rpc.dart';
import '../lib/api.dart';
final ApiServer apiServer = new ApiServer(prettyPrint: true);

main() async {
  Logger.root
    ..level = Level.INFO
    ..onRecord.listen(print);

  apiServer.addApi(new Api());
  HttpServer server =
  await HttpServer.bind(
      InternetAddress.ANY_IP_V4,
      4040
  );
  server.listen(apiServer.httpRequestHandler);
  print("Server running at ${server.address.host} : ${server.port}");
}