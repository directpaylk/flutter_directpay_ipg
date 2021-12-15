import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_directpay_ipg/flutter_directpay_ipg.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_directpay_ipg');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FlutterDirectpayIpg.platformVersion, '42');
  });
}
