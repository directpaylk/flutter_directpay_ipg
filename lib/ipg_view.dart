import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_directpay_ipg/ipg_stage.dart';
import 'package:pusher_channels/pusher_channels.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class IPGView extends StatefulWidget {
  final String stage;
  final String signature;
  final String payload;
  final Function(dynamic)? callback;

  IPGView(
      {required this.stage,
      required this.signature,
      required this.payload,
      this.callback});

  @override
  State<StatefulWidget> createState() => _IPGView();
}

class _IPGView extends State<IPGView> {
  Pusher? pusher;
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
      sessionUrl(widget.stage),
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
        final ch = jsonObject["data"]["ch"];

        this.initPusher(ak, ch);
      } else {
        this.callback(data: jsonObject);
      }
    } else {
      this.callback();
    }
  }

  initPusher(ak, ch) async {
    this.ch = ch;
    this.pusher = Pusher(key: ak, cluster: 'ap2');
    await this.pusher!.connect();
    final channel = pusher!.subscribe(this.ch);
    channel.bind('SDK_' + this.token!, (event) {
      if (event['response'] != null) this.callback(data: event['response']);
    });
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

  sessionUrl(stage) {
    return Uri.parse(stage == IPGStage.PROD
        ? 'https://gateway.directpay.lk/api/v3/create-session'
        : 'https://test-gateway.directpay.lk/api/v3/create-session');
  }

  @override
  void dispose() {
    if (this.pusher != null) {
      this.pusher!.unsubscribe(this.ch);
      this.pusher!.disconnect();
    }

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
