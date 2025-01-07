
import 'dart:async';

import 'package:flutter/services.dart';

class FlutterDirectpayIpg {
  static const MethodChannel _channel =
      const MethodChannel('flutter_directpay_ipg');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
