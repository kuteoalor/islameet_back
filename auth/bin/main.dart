import 'dart:io';
import 'package:auth/auth.dart';
import 'package:conduit_core/conduit_core.dart';

void main(List<String> arguments) async {
  final int port = int.parse(Platform.environment['PORT'] ?? "6100");
  final service = Application<AppService>()..options.port = port;
  await service.start(
    numberOfInstances: 1,
    consoleLogging: true,
  );
}
