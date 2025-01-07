import Flutter
import UIKit

public class SwiftFlutterDirectpayIpgPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_directpay_ipg", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterDirectpayIpgPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
