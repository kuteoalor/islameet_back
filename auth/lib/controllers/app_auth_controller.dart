import 'dart:io';

import 'package:auth/models/response_model.dart';
import 'package:auth/models/user.dart';
import 'package:auth/utils/app_response.dart';
import 'package:auth/utils/app_utils.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

class AppAuthController extends ResourceController {
  final ManagedContext managedContext;

  AppAuthController({required this.managedContext});

  @Operation.post()
  Future<Response> signIn(@Bind.body() User user) async {
    if (user.password == null || user.email == null) {
      return Response.badRequest(
        body: AppResponseModel(
          message: 'Поля password, username обязательны',
        ),
      );
    }

    try {
      final qFindUser = Query<User>(managedContext)
        ..where((table) => table.email).equalTo(user.email)
        ..returningProperties((table) => [
              table.id,
              table.salt,
              table.hashPassword,
            ]);
      final findUser = await qFindUser.fetchOne();
      if (findUser == null) {
        throw QueryException.input('User not found', []);
      }
      final requestHashPassword =
          generatePasswordHash(user.password ?? '', findUser.salt ?? '');
      if (requestHashPassword == findUser.hashPassword) {
        await _updateTokens(findUser.id ?? -1, managedContext);
        final newUser =
            await managedContext.fetchObjectWithID<User>(findUser.id);
        return AppResponse.ok(
          body: newUser?.backing.contents,
          message: "Authorization success",
        );
      } else {
        throw QueryException.input('Wrong password', []);
      }
    } on QueryException catch (err) {
      return AppResponse.serverError(
        err,
        message: 'Authorization error',
      );
    }
  }

  @Operation.put()
  Future<Response> signUp(@Bind.body() User user) async {
    if (user.password == null || user.email == null) {
      return Response.badRequest(
        body: AppResponseModel(
          message: 'Поля password, email обязательны',
        ),
      );
    }
    final salt = generateRandomSalt();
    final hashPassword = generatePasswordHash(user.password ?? '', salt);

    try {
      late final int id;
      await managedContext.transaction((transaction) async {
        final qCreateUser = Query<User>(transaction)
          ..values.email = user.email
          ..values.age = user.age
          ..values.city = user.city
          ..values.birthday = user.birthday
          ..values.description = user.description
          ..values.salt = salt
          ..values.hashPassword = hashPassword;
        final createdUser = await qCreateUser.insert();
        id = createdUser.asMap()['id'];
        await _updateTokens(id, transaction);
      });
      final userData = await managedContext.fetchObjectWithID<User>(id);
      return AppResponse.ok(
        body: userData?.backing.contents,
        message: 'Registration success',
      );
    } on QueryException catch (err) {
      return AppResponse.serverError(
        err,
        message: 'Registration error',
      );
    }
  }

  @Operation.delete()
  Future<Response> deleteUser(@Bind.body() User user) async {
    if (user.email == null && user.id == null) {
      return Response.badRequest(
        body: AppResponseModel(
          message: 'Поле id или email обязательнo',
        ),
      );
    }
    try {
      final qFindUserEmail = Query<User>(managedContext)
        ..where((table) => table.email).equalTo(user.email);
      final qFindUserId = Query<User>(managedContext)
        ..where((table) => table.id).equalTo(user.id);
      final findUserEmail = await qFindUserEmail.fetchOne();
      final findUserId = await qFindUserId.fetchOne();
      if (findUserEmail == null && findUserId == null) {
        throw QueryException.input('User not found', []);
      }
      final rightQuery = findUserEmail == null ? qFindUserId : qFindUserEmail;
      rightQuery.delete();
      return AppResponse.ok(message: 'delete successs');
    } catch (error) {
      return AppResponse.serverError(error, message: 'Delete error');
    }
  }

  @Operation.post('refresh')
  Future<Response> refreshToken(
      @Bind.path('refresh') String refreshToken) async {
    try {
      final id = AppUtils.getIdFromToken(refreshToken);
      final user = await managedContext.fetchObjectWithID<User>(id);
      if (user?.refreshToken != refreshToken) {
        return Response.unauthorized(
          body: AppResponseModel(message: "Token is not valid"),
        );
      }
      await _updateTokens(id, managedContext);

      return AppResponse.ok(
        body: user?.backing.contents,
        message: 'Token refresh success',
      );
    } on QueryException catch (err) {
      return AppResponse.serverError(
        err,
        message: 'Token refresh error',
      );
    }
  }

  Map<String, dynamic> _getTokens(int id) {
    //TODO: remove for release
    final key = Platform.environment['SECRET_KEY'] ?? 'SECRET_KEY';
    final accessClaimSet = JwtClaim(
      maxAge: Duration(hours: 2),
      otherClaims: {'id': id},
    );
    final refreshClaimSet = JwtClaim(
      otherClaims: {'id': id},
    );
    final tokens = <String, dynamic>{};
    tokens['access'] = issueJwtHS256(accessClaimSet, key);
    tokens['refresh'] = issueJwtHS256(refreshClaimSet, key);
    return tokens;
  }

  _updateTokens(int id, ManagedContext transaction) async {
    final Map<String, dynamic> tokens = _getTokens(id);
    final qUpdateTokens = Query<User>(transaction)
      ..where((user) => user.id).equalTo(id)
      ..values.accessToken = tokens['access']
      ..values.refreshToken = tokens['refresh'];
    await qUpdateTokens.updateOne();
  }
}
