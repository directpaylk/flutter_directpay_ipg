# flutter_directpay_ipg

Flutter plugin for [DirectPay IPG](https://directpay.lk/ipg, "DirectPay IPG")

## Installation

```yaml
flutter_directpay_ipg:
    git:
      url: https://github.com/directpaylk/flutter_directpay_ipg.git
```

## Usage

```dart
import 'package:flutter_directpay_ipg/ipg_stage.dart';
import 'package:flutter_directpay_ipg/ipg_view.dart';

// ...

IPGView(
    stage: IPGStage.DEV,
    signature: this.signature,
    payload: this.payload,
    callback: (data) {
            //todo: handle data
        },
    ),
```

### How to make a payment?

1. first select stage - ```IPGStage.DEV / IPGStage.PROD```
2. Create payment **payload** & **signature** from Server-side and parse signature and base64 encoded payload to *IPGComponent*

    *Note: it's the best practice to create payload and signature from server side. otherwise the data will be compromised.*

#### payload
Payload is a base64 encoded string that created from JSON payload string. Here is a sample object,
```dart
payload = {
   'merchant_id' : "xxxxxx",
   'amount' : "10.00",
   'type' : "ONE_TIME",
   'order_id' : "CP123456789",
   'currency' : "LKR",
   'response_url' : "https://test.com/response-endpoint",
   'first_name' : "Sam",
   'last_name' : "Perera",
   'email' : "user@email.com",
   'phone' : "0712345678",
   'logo' : "",
};
```
#### signature
Signature is HmacSHA256 hash of the base64 encoded payload string. The **secret** for HmacSHA256 can be found at developer portal.

```dart
createHmacSha256Hash(base64jsonPayload, secret);
```

Provide these two arguments to IPGComponent and you'll receive the reponse from *callback* function.

---

Read more at [Documentation](https://doc.directpay.lk/, "DirectPay Documentation")