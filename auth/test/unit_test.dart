import 'dart:ffi';
import 'dart:io';

import 'package:auth/auth.dart';
import 'package:conduit_core/conduit_core.dart';
//import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_test/conduit_test.dart';
import 'package:test/test.dart';

const accessToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MzQ4MTAyMzUsImlhdCI6MTczNDgwMzAzNSwiaWQiOjF9.zCzo41nX9p3AUYe__CEZL5cu0xU3jiURsOdQJ2AwZXI';

final mockUser = {
  'email' : 'qwerty',
  'password' : 'qwerty',
};

void main() {
  final harness = TestHarness<AppService>()..install();

  test("GET /user/all returns list of users", () async {
    final response = await harness.agent?.get("/user/all");
    final body = response?.body.as<Map>();
    final message = body?['message'];
    final data = body?['data'];
    final error = body?['error'];

    expect(response?.statusCode, 200);
    expect(message, "Get profile success");
    expect(error, '');
    expect(data.runtimeType, List);
  });

  test('Get user info', () async {
    final request = harness.agent?.request('/user')
    ?..headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
    final response = await request?.get(); 
    final data = response?.body.as<Map>()['data'];
    final email = data?['email'];
    expect(response?.statusCode, 200);
    expect(email, mockUser['email']);
  });

  test('Create user and then change his email', () async {
    final firstTimeStamp = DateTime.now();
    final putResponse = await harness.agent?.put(
      '/token', 
      body: {
        'email' : '$firstTimeStamp', 
        'password' : 'password'
        }
    );
    expect(putResponse?.statusCode, 200);
    final putData = putResponse?.body.as<Map>()['data'];
    expect(putData['email'], '$firstTimeStamp');
    final userAccessToken = putData?['accessToken'];
    final secondTimeStamp = DateTime.now();
    final postResponse = await harness.agent?.post('/user', 
    headers: {'authorization': 'Bearer $userAccessToken'}, 
    body: {'email' : '$secondTimeStamp'},);
    expect(postResponse?.statusCode, 200);
    final postData = postResponse?.body.as<Map>()['data'];
    expect(postData['email'], '$secondTimeStamp');
  });

  test('Register a new user', () async {
  final firstTimeStamp = DateTime.now();
  final response = await harness.agent?.put(
    '/token',
     body: {
    'email': '$firstTimeStamp',
    'password': 'securepassword123',
  }
  );
  expect(response?.statusCode, 200);
  final putData = response?.body.as<Map>()['data'];
  expect(putData['email'], '$firstTimeStamp');
});
  
  test('Login user with valid credentials', () async {
  final firstTimeStamp = DateTime.now();
  final response = await harness.agent?.put(
    '/token',
     body: {
    'email': '$firstTimeStamp',
    'password': mockUser['password'],
  }
  );
  expect(response?.statusCode, 200);
    final putData = response?.body.as<Map>()['data'];
    expect(putData['email'], '$firstTimeStamp');
});

// test('Login user with invalid password', () async {
//   final request = harness.agent?.request('/user')
//     ?..headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
//     final response = await request?.get(); 
//     final data = response?.body.as<Map>()['data'];
//   final userAccessToken = data?['accessToken'];
//   final postResponse = await harness.agent?.post('/user', 
//     headers: {'authorization': 'Bearer $userAccessToken'});
//   expect(response?.statusCode, 401);
//   final body = response?.body.as<Map>()['data'];
//   expect(body?['password'], body?['hashpassword']);
// });

  test('Delete a user', () async {
  final deleteRequest = harness.agent?.request('/user')
    ?..headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
  final deleteResponse = await deleteRequest?.delete();
  expect(deleteResponse?.body.isEmpty, true);

  final getRequest = harness.agent?.request('/user')
    ?..headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
  final checkResponse = await getRequest?.get();
  expect(checkResponse?.body.isEmpty, true); 

});

// Проверки на дурака

test('Access protected route without authorization', () async {
  final response = await harness.agent?.get('/user');
  expect(response?.statusCode, 400);
  final error = response?.body.as<Map>()['error'];
  expect(error, contains('missing required header \'authorization\''));
});

// test('Change user password', () async {
//   final patchResponse = await harness.agent?.post('/user', 
//     headers: {'authorization': 'Bearer $accessToken'}, 
//     body: {'oldPassword': mockUser['password'], 'newPassword': 'newPassword123'});
//     final Data = patchResponse?.body.as<Map>()['data'];
//   expect(patchResponse?.statusCode, 200);

//   final loginWithOldPassword = await harness.agent?.post('/auth', body: {
//     'email': mockUser['email'],
//     'password': mockUser['password'],
//   });
//   expect(loginWithOldPassword?.statusCode, 401);

//   final loginWithNewPassword = await harness.agent?.post('/auth', body: {
//     'email': mockUser['email'],
//     'password': 'newPassword123',
//   });
//   expect(loginWithNewPassword?.statusCode, 200);
// });

test('Like a user profile', () async {
  final response = await harness.agent?.post('/user/like', 
    headers: {'authorization': 'Bearer $accessToken'}, 
    body: {'targetUserId': 2});
  expect(response?.statusCode, 200);
  final data = response?.body.as<Map>()['data'];
  expect(data['likedUserId'], 2);
});

test('Dislike a user profile', () async {
  final response = await harness.agent?.post('/user/dislike', 
    headers: {'authorization': 'Bearer $accessToken'}, 
    body: {'targetUserId': 2});
  expect(response?.statusCode, 200);
  final data = response?.body.as<Map>()['data'];
  expect(data['dislikedUserId'], 2);
});

test('Get list of matches', () async {
  final response = await harness.agent?.get('/user/matches', 
    headers: {'authorization': 'Bearer $accessToken'});
  expect(response?.statusCode, 200);
  final data = response?.body.as<Map>()['data'];
  expect(data.runtimeType, List);
  expect(data.isNotEmpty, true);
});


test('Get paginated list of users', () async {
  final response = await harness.agent?.get('/user/all?page=1&limit=10');
  expect(response?.statusCode, 200);
  final data = response?.body.as<Map>()['data'];
  expect(data.runtimeType, List);
  expect(data.length, lessThanOrEqualTo(10));
});

test('Register, complete profile, like another user, and check match', () async {
  final registrationResponse = await harness.agent?.post('/user/register', body: {
    'email': 'newuser@example.com',
    'password': 'securepassword123',
  });
  expect(registrationResponse?.statusCode, 201);

  final newUserToken = registrationResponse?.body.as<Map>()['data']['accessToken'];

  final profileResponse = await harness.agent?.post('/user/profile', 
    headers: {'authorization': 'Bearer $newUserToken'},
    body: {
      'name': 'John Doe',
      'age': 30,
      'bio': 'Love hiking and coffee.',
    });
  expect(profileResponse?.statusCode, 200);

  final likeResponse = await harness.agent?.post('/user/like', 
    headers: {'authorization': 'Bearer $newUserToken'},
    body: {'targetUserId': 2}); 
  expect(likeResponse?.statusCode, 200);

  final matchesResponse = await harness.agent?.get('/user/matches', 
    headers: {'authorization': 'Bearer $newUserToken'});
  expect(matchesResponse?.statusCode, 200);
  final matches = matchesResponse?.body.as<Map>()['data'];
  expect(matches.any((match) => match['id'] == 2), true);
});


test('Forgot password and reset it', () async {

  final forgotPasswordResponse = await harness.agent?.post('/auth/forgot-password', body: {
    'email': mockUser['email'],
  });
  expect(forgotPasswordResponse?.statusCode, 200);


  final resetCode = forgotPasswordResponse?.body.as<Map>()['data']['resetCode'];

  final resetPasswordResponse = await harness.agent?.post('/auth/reset-password', body: {
    'resetCode': resetCode,
    'newPassword': 'newSecurePassword123',
  });
  expect(resetPasswordResponse?.statusCode, 200);

  final loginResponse = await harness.agent?.post('/auth/login', body: {
    'email': mockUser['email'],
    'password': 'newSecurePassword123',
  });
  expect(loginResponse?.statusCode, 200);
});

test('Like a user but no match occurs', () async {
  final likeResponse = await harness.agent?.post('/user/like', 
    headers: {'authorization': 'Bearer $accessToken'},
    body: {'targetUserId': 5}); 
  expect(likeResponse?.statusCode, 200);


  final matchesResponse = await harness.agent?.get('/user/matches', 
    headers: {'authorization': 'Bearer $accessToken'});
  expect(matchesResponse?.statusCode, 200);
  final matches = matchesResponse?.body.as<Map>()['data'];
  expect(matches.any((match) => match['id'] == 5), false);
});

test('Filter users by age and interests', () async {
  final response = await harness.agent?.get('/user/all?ageMin=25&ageMax=35&interests=hiking');
  expect(response?.statusCode, 200);

  final users = response?.body.as<Map>()['data'];
  expect(users.every((user) => user['age'] >= 25 && user['age'] <= 35), true);
  expect(users.every((user) => user['interests'].contains('hiking')), true);
});


}
