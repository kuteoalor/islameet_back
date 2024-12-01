import 'dart:io';

import 'package:auth/models/response_model.dart';
import 'package:auth/models/user.dart';
import 'package:auth/utils/app_response.dart';
import 'package:conduit_core/conduit_core.dart';

class AppChatController extends ResourceController {
  final ManagedContext managedContext;

  AppChatController({required this.managedContext});

  @Operation.get()
  Future<Response> getChats(@Bind.query('id') int id) async {
    try {
      var qChats = Query<ChatRoom>(managedContext)
        ..where((x) => x.user1Id).equalTo(id);
      var chats1 = await qChats.fetch();
      qChats = Query<ChatRoom>(managedContext)
        ..where((x) => x.user2Id).equalTo(id);
      var chats2 = await qChats.fetch();
      chats1.addAll(chats2);
      final chatsBackings = <Map<String, dynamic>>[];
      for (var chat in chats1) {
        final contents = chat.backing.contents;
        final companionId = contents['user1Id'] == id
            ? contents['user2Id']
            : contents['user1Id'];
        final companion =
            await managedContext.fetchObjectWithID<User>(companionId);
        contents['companionName'] = companion?.name ?? '';
        if (contents['lastMessage'] == null) contents['lastMessage'] = '';
        chatsBackings.add(contents);
      }
      return AppResponse.ok(message: "Get chats success", body: chatsBackings);
    } catch (error) {
      return AppResponse.serverError(error, message: 'Get profile error');
    }
  }
}
