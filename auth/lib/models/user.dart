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
  DateTime? birthday;
  @Column(nullable: true)
  String? photoURL;
  @Column(nullable: true)
  String? description;
  @Column(nullable: true)
  String? city;
  @Column(nullable: true)
  int? age;
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
