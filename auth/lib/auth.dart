import 'dart:convert';
import 'dart:io';

import 'package:auth/controllers/app_auth_controller.dart';
import 'package:auth/controllers/app_chat_controller.dart';
import 'package:auth/controllers/app_token_controller.dart';
import 'package:auth/controllers/app_user_controller.dart';
import 'package:auth/models/user.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';

class AppService extends ApplicationChannel {
  late final ManagedContext managedContext;
  final connections = <int, WebSocket>{};

  @override
  Future prepare() {
    final persistentStore = _initDatabase();
    managedContext = ManagedContext(
      ManagedDataModel.fromCurrentMirrorSystem(),
      persistentStore,
    );
    return super.prepare();
  }

  @override
  Controller get entryPoint => Router()
    ..route("token/[:refresh]").link(
      () => AppAuthController(managedContext: managedContext),
    )
    ..route("user/[:all]")
        .link(() => AppUserController(managedContext: managedContext))!
        .link(() => AppTokenController())
    ..route('chat')
        .link(() => AppChatController(managedContext: managedContext))
    ..route('connect').linkFunction((request) async {
      print(1);
      print(2);
      print(3);
      final socket = await WebSocketTransformer.upgrade(request.raw);
      print(4);
      socket.listen((data) async {
        print('recieved');
        final incoming = json.decode(utf8.decode(data));
        print('after decode');
        if (incoming['handshake'] != null) {
          print('inside handshake: ${incoming['handshake']}');
          connections.putIfAbsent(incoming['handshake'] as int, () => socket);
          print('connections in handshake: $connections');
        } else {
          print('inside party');
          print(connections);
          final outgoing = utf8.encode(
            json.encode({
              'text': incoming['text'] as String,
              'time': incoming['time'] as String,
            }),
          );
          final chatRoom = await managedContext
              .fetchObjectWithID<ChatRoom>(incoming['roomId']);

          final companionId = chatRoom!.user1Id == incoming['senderId']
              ? chatRoom.user2Id
              : chatRoom.user1Id;
          final connection = connections[companionId];
          print('connection: $connection ${connection.runtimeType}');
          print('companion: $companionId');
          print('sender: ${incoming['senderId']}');
          connection?.add(outgoing);
          // var tempConn = connections[incoming['senderId'] as int];
          // tempConn?.add(outgoing);
          //put message in db
        }
      });
      return null;
    });

  PostgreSQLPersistentStore _initDatabase() {
    final username = Platform.environment["DB_USERNAME"] ?? "admin";
    final password = Platform.environment["DB_PASSWORD"] ?? "root";
    final host = Platform.environment["DB_HOST"] ?? "127.0.0.1";
    final port = int.parse(Platform.environment["DB_PORT"] ?? "6101");
    final databaseName = Platform.environment["DB_NAME"] ?? "postgres";
    return PostgreSQLPersistentStore(
      username,
      password,
      host,
      port,
      databaseName,
    );
  }
}
