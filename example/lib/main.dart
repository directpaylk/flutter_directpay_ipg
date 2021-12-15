import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'package:flutter/material.dart';
import 'package:flutter_directpay_ipg/ipg_stage.dart';
import 'package:flutter_directpay_ipg/ipg_view.dart';

void main() {
  runApp(
    MaterialApp(
      home: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _mid = TextEditingController();
  final _secret = TextEditingController();
  final _amount = TextEditingController();
  final _type = TextEditingController();
  final _orderId = TextEditingController();
  final _currency = TextEditingController();
  final _responseUrl = TextEditingController();
  final _fname = TextEditingController();
  final _lname = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _logo = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  createPayload() {
    final String payload = jsonEncode({
      'merchant_id': _mid.text,
      'amount': _amount.text,
      'type': _type.text,
      'order_id': _orderId.text,
      'currency': _currency.text,
      'response_url': _responseUrl.text,
      'first_name': _fname.text,
      'last_name': _lname.text,
      'phone': _phone.text,
      'email': _email.text,
      'logo': _logo.text,
      'interval': 1,
      'start_date': '2021-12-31',
      'end_date': '2022-12-31',
      'do_initial_payment': true,
      'initial_amount': _amount.text,
      'recurring_amount': _amount.text,
    });

    return base64.encode(utf8.encode(payload));
  }

  createSignature(dataString) {
    var key = utf8.encode(_secret.text);
    var bytes = utf8.encode(dataString);
    var hmacSha256 = Hmac(sha256, key);

    final digest = hmacSha256.convert(bytes);
    print("Data String: " + dataString);
    print("Digest: " + digest.toString());

    return digest.toString();
  }

  _textField(String hint, TextEditingController controller, String text) {
    controller.text = text;
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(hintText: hint),
      ),
    );
  }

  _randomOrderId() {
    String number = "";
    var rng = new Random();
    for (var i = 0; i < 5; i++) {
      number = number + rng.nextInt(10).toString();
    }
    return 'FLT-TEST-' + number;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DirectPay IPG example app'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _textField("Merchant ID", _mid, "DP00001"),
                _textField("Secret (Do not share with anyone)", _secret,
                    "u4V376WvJJij"),
                Container(
                  color: Colors.blue,
                  padding: EdgeInsets.all(8),
                  child: Text(
                    "Help: Change Merchant ID, Secret and Order ID to do a test payment.",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                _textField("Amount", _amount, "169.00"),
                _textField(
                    "Type (ONE_TIME, RECURRING, CARD_ADD)", _type, "ONE_TIME"),
                _textField("Order ID", _orderId, _randomOrderId()),
                _textField("Currency (LKR, USD)", _currency, "LKR"),
                _textField("Response URL", _responseUrl,
                    "http://localhost/payment_test_directpay/controllers/serverRes.php"),
                _textField("First Name", _fname, "John"),
                _textField("Last Name", _lname, "Appleseed"),
                _textField("Phone", _phone, "0771105130"),
                _textField("Email", _email, "deeptha@paymedia.lk"),
                _textField("Logo", _logo,
                    "https://is2-ssl.mzstatic.com/image/thumb/Purple124/v4/28/fa/57/28fa57e1-7685-2f11-de16-6dba1d30ea32/AppIcon-1x_U007emarketing-0-10-0-0-85-220.png/1200x630wa.png"),
                TextButton(
                  onPressed: () async {
                    final dataString = this.createPayload();
                    final signature = createSignature(dataString);

                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CheckoutPage(
                          signature: signature,
                          dataString: dataString,
                        ),
                      ),
                    );

                    if (result != null) {
                      showDialog(
                        context: context,
                        builder: (builder) {
                          return SimpleDialog(
                            title: Text("Response"),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  jsonEncode(result),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Text("Continue"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CheckoutPage extends StatelessWidget {
  final signature, dataString;

  CheckoutPage({this.signature, this.dataString});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Page'),
      ),
      body: Center(
        child: IPGView(
          stage: IPGStage.DEV,
          signature: this.signature,
          payload: this.dataString,
          callback: (data) {
            Navigator.of(context).pop(data);
          },
        ),
      ),
    );
  }
}
