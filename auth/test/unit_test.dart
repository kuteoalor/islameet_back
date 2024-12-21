import 'package:auth/auth.dart';
//import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_test/conduit_test.dart';
import 'package:test/test.dart';

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
}
