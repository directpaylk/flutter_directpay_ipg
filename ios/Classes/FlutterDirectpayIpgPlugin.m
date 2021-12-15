#import "FlutterDirectpayIpgPlugin.h"
#if __has_include(<flutter_directpay_ipg/flutter_directpay_ipg-Swift.h>)
#import <flutter_directpay_ipg/flutter_directpay_ipg-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_directpay_ipg-Swift.h"
#endif

@implementation FlutterDirectpayIpgPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterDirectpayIpgPlugin registerWithRegistrar:registrar];
}
@end
