import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_directpay_ipg/ipg_stage.dart';
import 'package:pusher_client/pusher_client.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;


/// A widget that draws IPG view within itself.
///
/// This widget will initiate and display IPG session according to
/// [stage] provided.
/// [signature] is used to authorize the initiated session.
/// [payload] must contain the session data as a [String] which is a
/// JSON string that is [Base64Codec] encoded.
/// If the [callback] is null, event data will not be captured.
class IPGView extends StatefulWidget {
  final String stage;
  final String signature;
  final String payload;
  final Function(dynamic)? callback;

  IPGView({
    required this.stage,
    required this.signature,
    required this.payload,
    this.callback,
  });

  @override
  State<StatefulWidget> createState() => _IPGView();
}

class _IPGView extends State<IPGView> {
  PusherClient? pusher;
  bool isLoading = true;
  String? url;
  String? token;
  late String ch;

  @override
  void initState() {
    this.getSession();
    super.initState();
  }

  getSession() async {
    setState(() {
      url = null;
      token = null;
    });

    final response = await http.post(
      sessionUrl(),
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
        'x-plugin-source': 'FLUTTER',
        'x-plugin-version': '0.0.1',
        'Authorization': 'hmac ' + widget.signature
      },
      body: widget.payload,
    );

    if (response.statusCode == 200) {
      final jsonObject = jsonDecode(response.body);
      final status = jsonObject["status"];
      if (status == 200) {
        setState(() {
          this.url = jsonObject["data"]["link"];
          this.token = jsonObject["data"]["token"];
        });

        final ak = jsonObject["data"]["ak"];
        this.ch = jsonObject["data"]["ch"];

        this.initPusher(ak);
      } else {
        this.callback(data: jsonObject);
      }
    } else {
      this.callback();
    }
  }

  initPusher(ak) async {
    final _options = PusherOptions(
      encrypted: false,
      cluster: 'ap2',
    );
    this.pusher = PusherClient(
      ak,
      _options,
    );

    pusher!.onConnectionStateChange((state) {
      _log(
          "previousState: ${state?.previousState}, currentState: ${state?.currentState}");
    });

    pusher!.onConnectionError((error) {
      _log("error: ${error?.message}");
    });

    final _channel = pusher!.subscribe(this.ch);
    _channel.bind(
      'SDK_' + this.token!,
      (PusherEvent? event) {
        Map jsonMap = json.decode(event?.data ?? '{}');
        if (jsonMap['response'] != null)
          this.callback(data: jsonMap['response']);
      },
    );
  }

  callback({data}) {
    if (data == null) {
      data = {
        'status': 400,
        'data': {
          'code': 'SERVER_ERROR',
          'title': 'Failed proceed payment',
          'message': 'Failed proceed payment',
        },
      };
    }
    if (widget.callback != null) {
      widget.callback!(data);
    }
  }

  sessionUrl() {
    return Uri.parse(widget.stage == IPGStage.PROD
        ? 'https://gateway.directpay.lk/api/v3/create-session'
        : 'https://test-gateway.directpay.lk/api/v3/create-session');
  }

  _log(data) {
    if (widget.stage == IPGStage.DEV) {
      debugPrint(data.toString());
    }
  }

  @override
  void dispose() {
    // Unsubscribe from channel and disconnect
    pusher?.unsubscribe(this.ch);
    pusher?.disconnect();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        this.url != null
            ? WebView(
                javascriptMode: JavascriptMode.unrestricted,
                initialUrl: this.url,
                onPageFinished: (finish) {
                  setState(() {
                    isLoading = false;
                  });
                },
              )
            : Container(),
        isLoading
            ? Center(
                child: CircularProgressIndicator.adaptive(),
              )
            : Stack(),
      ],
    );
  }
}
