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
  
test('Login user with valid credentials and check ID', () async {
  final email = 'qwerty';
  final password = 'qwerty'; 
  final loginResponse = await harness.agent?.post('/token', body: {
    'email': email,
    'password': password,
  });

  expect(loginResponse?.statusCode, 200);

  final accessToken = loginResponse?.body.as<Map>()['data']['accessToken'];
  expect(accessToken, isNotNull);

  final userInfoRequest = harness.agent?.request('/user')
    ?..headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
  final userInfoResponse = await userInfoRequest?.get();

  expect(userInfoResponse?.statusCode, 200);
  final userData = userInfoResponse?.body.as<Map>()['data'];

  final loggedInUserId = userData?['id'];

  final expectedUserId = 1;
  expect(loggedInUserId, expectedUserId);
});


test('Login user with invalid password', () async {
  final email = 'qwerty';
  final invalidPassword = 'wrongpassword123';

  final loginResponse = await harness.agent?.post('/token', body: {
    'email': email,
    'password': invalidPassword,
  });

  expect(loginResponse?.statusCode, 401);

  final body = loginResponse?.body.as<Map>();
  expect(body?['error'], isNotNull);
  expect(body?['error'], 'Invalid credentials');
});


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



test('Change user password', () async {
  final patchResponse = await harness.agent?.post('/user', 
    headers: {'authorization': 'Bearer $accessToken'}, 
    body: {'password': mockUser['password'] = 'NewPassword123'}
  );

  expect(patchResponse?.statusCode, 200);
  final data = patchResponse?.body.as<Map>()['data'];
  expect(data, isNotNull);

  final loginWithOldPassword = await harness.agent?.post('/user', body: {
    'email': mockUser['email'],
    'password': mockUser['password'],
  });
  expect(loginWithOldPassword?.statusCode, 401);
  final loginWithNewPassword = await harness.agent?.post('/user', body: {
    'email': mockUser['email'],
    'password': 'newPassword123',
  });
  expect(loginWithNewPassword?.statusCode, 200);
});


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


test('Register, complete profile, like another user, and check match', () async {
  final registrationResponse = await harness.agent?.post('/user', body: {
    'email': 'newuser@example.com',
    'password': 'securepassword123',
  });
  expect(registrationResponse?.statusCode, 201);

  final newUserToken = registrationResponse?.body.as<Map>()['data']['accessToken'];

  final profileResponse = await harness.agent?.post('/user', 
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



// Проверки на дурака

test('Access protected route without authorization', () async {
  final response = await harness.agent?.get('/user');
  expect(response?.statusCode, 400);
  final error = response?.body.as<Map>()['error'];
  expect(error, contains('missing required header \'authorization\''));
});

test('Register with invalid email', () async {
  final response = await harness.agent?.post(
    '/token',
     body: {
    'email': 'not-an-email',
    'password': 'securepassword123',
  });
  expect(response?.statusCode, 400);
  final error = response?.body.as<Map>()['error'];
  expect(error, 'Query failed: User not found. Reason: null');
});

test('Register without password', () async {
  final response = await harness.agent?.post('/token', body: {
    'email': 'validemail@example.com',
  });
  expect(response?.statusCode, 400);
  final error = response?.body.as<Map>()['error'];
  expect(error, '');
});

test('Attempt to delete another user\'s profile', () async {
  final response = await harness.agent?.delete('/user/999', 
    headers: {'authorization': 'Bearer $accessToken'});
  expect(response?.statusCode, 403);
  final error = response?.body.as<Map>()['error'];
  expect(error, contains('You are not authorized to delete this user'));
});

test('Fetch a large number of users', () async {
  final response = await harness.agent?.get('/user/all?page=1&limit=100');
  expect(response?.statusCode, 200);
  final data = response?.body.as<Map>()['data'];
  expect(data.runtimeType, List);
  expect(data.length, lessThanOrEqualTo(100));
});

test('Register with overly long email', () async {
  final longEmail = 'a' * 10000 + '@example.com'; 
  final response = await harness.agent?.post('/token', body: {
    'email': longEmail,
    'password': 'securepassword123',
  });
  expect(response?.statusCode, 400); 
  final error = response?.body.as<Map>()['error'];
  expect(error, 'Query failed: User not found. Reason: null');
});

test('Login with incorrect password', () async {
  final response = await harness.agent?.post('/token', body: {
    'email': mockUser['email'],
    'password': 'wrongpassword',
  });
  expect(response?.statusCode, 401);
  final error = response?.body.as<Map>()['error'];
  expect(error, contains('Invalid credentials'));
});

test('Login with unregistered email', () async {
  final response = await harness.agent?.post('/token', body: {
    'email': 'nonexistent@example.com',
    'password': 'password123',
  });
  expect(response?.statusCode, 404);
  final error = response?.body.as<Map>()['error'];
  expect(error, contains('User not found'));
});

//SQL - инъекции
test('Register with SQL injection in email', () async {
  final sqlInjection = "'; DROP TABLE _user; --";
  final response = await harness.agent?.put('/token', body: {
    'email': sqlInjection,
    'password': 'securepassword123',
  });
  expect(response?.statusCode, 400);
  final error = response?.body.as<Map>()['error'];
  expect(error, 'Invalid email');
});

test('Register with SQL injection in password', () async {
  final sqlInjection = "' OR '1'='1; DROP TABLE _user";
  final response = await harness.agent?.put('/token', body: {
    'email': 'test@example.com',
    'password': sqlInjection,
  });
  expect(response?.statusCode, 400);
  final error = response?.body.as<Map>()['error'];
  expect(error, 'Invalid password format');
});

test('Register with overly long password', () async {
  final longPassword = 'a' * 10000; 
  final response = await harness.agent?.put('/token', body: {
    'email': 'test@example.com',
    'password': longPassword,
  });
  expect(response?.statusCode, 400);
  final error = response?.body.as<Map>()['error'];
  expect(error, contains('Password is too long'));
});


test('Register with special characters in email', () async {
  final specialEmail = "test'; DROP TABLE _user; --@example.com";
  final response = await harness.agent?.put('/token', body: {
    'email': specialEmail,
    'password': 'securepassword123',
  });
  expect(response?.statusCode, 400); 
  final error = response?.body.as<Map>()['error'];
  expect(error, contains('Invalid email format'));
});

}
