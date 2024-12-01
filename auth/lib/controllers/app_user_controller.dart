import 'dart:io';

import 'package:auth/models/response_model.dart';
import 'package:auth/models/user.dart';
import 'package:auth/utils/app_response.dart';
import 'package:auth/utils/app_utils.dart';
import 'package:conduit_core/conduit_core.dart';

class AppUserController extends ResourceController {
  final ManagedContext managedContext;

  AppUserController({required this.managedContext});

  @Operation.get()
  Future<Response> getProfile(
      @Bind.header(HttpHeaders.authorizationHeader) String header) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final user = await managedContext.fetchObjectWithID<User>(id);
      user?.removePropertiesFromBackingMap(['accessToken', 'refreshToken']);
      return AppResponse.ok(
          message: "Get profile success", body: user?.backing.contents);
    } catch (error) {
      return AppResponse.serverError(error, message: 'Get profile error');
    }
  }

  @Operation.get('all')
  Future<Response> getAllProfiles() async {
    try {
      final users = await Query<User>(managedContext).fetch();
      final usersBackings = users.map((user) => user.backing.contents).toList();
      return AppResponse.ok(
          message: "Get profile success", body: usersBackings);
    } catch (error) {
      return AppResponse.serverError(error, message: 'Get profile error');
    }
  }

  @Operation.post()
  Future<Response> updateProfile(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() User user,
  ) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final fUser = await managedContext.fetchObjectWithID<User>(id);
      final qUpdateUser = Query<User>(managedContext)
        ..where((x) => x.id).equalTo(id)
        ..values.birthday = user.birthday ?? fUser?.birthday
        ..values.city = user.city ?? fUser?.city
        ..values.name = user.name ?? fUser?.name
        ..values.description = user.city ?? fUser?.description
        ..values.email = user.email ?? fUser?.email
        ..values.photoURL = user.photoURL ?? fUser?.photoURL;
      await qUpdateUser.updateOne();
      final uUser = await managedContext.fetchObjectWithID<User>(id);
      uUser?.removePropertiesFromBackingMap([
        "accessToken",
        "refreshToken",
      ]);
      return AppResponse.ok(
        message: 'Update profile success',
        body: uUser?.backing.contents,
      );
    } catch (error) {
      return AppResponse.serverError(error, message: "Update user error");
    }
  }

  @Operation.put()
  Future<Response> updatePassword(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.query("oldPassword") String oldPassword,
    @Bind.query("newPassword") String newPassword,
  ) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final qFindUser = Query<User>(managedContext)
        ..where((x) => x.id).equalTo(id)
        ..returningProperties((table) => [table.salt, table.hashPassword]);
      final findUser = await qFindUser.fetchOne();
      final salt = findUser?.salt ?? '';
      final oldPasswordHash = generatePasswordHash(oldPassword, salt);
      if (oldPasswordHash != findUser?.hashPassword) {
        return Response.badRequest(
            body: AppResponseModel(message: "Wrong old password"));
      }
      final newPasswordHash = generatePasswordHash(newPassword, salt);
      final qUpdateUser = Query<User>(managedContext)
        ..where((x) => x.id).equalTo(id)
        ..values.hashPassword = newPasswordHash;
      await qUpdateUser.updateOne();
      return AppResponse.ok(message: 'Update password success');
    } catch (error) {
      return AppResponse.serverError(error, message: 'Password update error');
    }
  }
}
