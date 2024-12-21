import 'package:conduit_core/conduit_core.dart';

class User extends ManagedObject<_User> implements _User {}

class _User {
  @primaryKey
  int? id;
  //@Column(unique: true, indexed: true)
  //String? username;
  @Column(unique: true, indexed: true)
  String? email;
  @Column(nullable: true)
  int? birthdayStamp;
  @Column(nullable: true)
  String? photoURL;
  @Column(nullable: true)
  String? description;
  @Column(nullable: true)
  String? city;
  @Column(nullable: true)
  bool? isMale;
  @Column(nullable: true)
  String? name;
  @Serialize(input: true, output: false)
  String? password;
  @Column(nullable: true)
  String? accessToken;
  @Column(nullable: true)
  String? refreshToken;
  @Column(omitByDefault: true)
  String? salt;
  @Column(omitByDefault: true)
  String? hashPassword;
}

class Message extends ManagedObject<_Message> implements _Message {}

class _Message {
  @primaryKey
  int? id;
  @Column(nullable: false)
  int? chatRoomId;
  @Column(nullable: false)
  int? senderId;
  @Column(nullable: false)
  String? text;
  @Column(nullable: false)
  String? time;
}

class ChatRoom extends ManagedObject<_ChatRoom> implements _ChatRoom {}

class _ChatRoom {
  @primaryKey
  int? id;
  @Column(nullable: false)
  int? user1Id;
  @Column(nullable: false)
  int? user2Id;
  @Column(nullable: true)
  String? lastMessage;
}
