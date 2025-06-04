import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_directpay_ipg/ipg_stage.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_channels/pusher_channels.dart';

/// A widget that draws IPG view within itself.
///
/// This widget will initiate and display IPG session according to
/// [stage] provided.
/// [signature] is used to authorize the initiated session.
/// [payload] must contain the session data as a [String] which is a
/// JSON string that is [Base64Codec] encoded.
/// If the [callback] is null, event data will not be captured.
/// [enableScroll] can be used to enable or disable the scroll of view.
class IPGView extends StatefulWidget {
  final String stage;
  final String signature;
  final String payload;
  final Function(dynamic)? callback;
  final bool enableScroll;
  final Widget? loadingWidget;
  final bool showLoading;
  final Function(bool isLoading)? onLoading;

  IPGView({
    required this.stage,
    required this.signature,
    required this.payload,
    this.callback,
    this.enableScroll = true,
    this.showLoading = true,
    this.loadingWidget,
    this.onLoading,
  });

  @override
  State<StatefulWidget> createState() => _IPGView();
}

class _IPGView extends State<IPGView> {
  Pusher? pusher;
  bool isLoading = false;
  String? url;
  String? token;
  late String ch;

  @override
  void initState() {
    isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.onLoading != null) {
        widget.onLoading?.call(true);
      }
    });
    getSession();
    super.initState();
  }

  Future<void> getSession() async {
    setState(() {
      url = null;
      token = null;
    });

    try {
      final response = await http.post(
        sessionUrl(),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=UTF-8',
          'x-plugin-source': 'FLUTTER',
          'x-plugin-version': '0.0.1',
          'Authorization': 'hmac ${widget.signature}',
        },
        body: widget.payload,
      );

      if (response.statusCode == 200) {
        final jsonObject = jsonDecode(response.body);
        if (jsonObject["status"] == 200) {
          setState(() {
            url = jsonObject["data"]["link"];
            token = jsonObject["data"]["token"];
          });

          initWebView();

          final ak = jsonObject["data"]["ak"];
          ch = jsonObject["data"]["ch"];

          await initPusher(ak);
        } else {
          callback(data: jsonObject);
        }
      } else {
        callback();
      }
    } catch (e) {
      callback();
    } finally {
      // if (widget.onLoading != null) {
      //   widget.onLoading?.call(false);
      // }
      // setState(() {
      //   isLoading = false;
      // });
    }
  }

  Future<void> initPusher(String ak) async {
    pusher = Pusher(key: ak, cluster: 'ap2');
    await pusher!.connect();
    final channel = pusher!.subscribe(ch);
    channel.bind('SDK_$token', (event) {
      if (event['response'] != null) {
        callback(data: event['response']);
      }
    });
  }

  void callback({dynamic data}) {
    data ??= {
      'status': 400,
      'data': {
        'code': 'SERVER_ERROR',
        'title': 'Failed to proceed payment',
        'message': 'Failed to proceed payment',
      },
    };
    widget.callback?.call(data);
  }

  Uri sessionUrl() {
    return Uri.parse(widget.stage == IPGStage.PROD
        ? 'https://gateway.directpay.lk/api/v3/create-session'
        : 'https://test-gateway.directpay.lk/api/v3/create-session');
  }

  void initWebView() {}

  @override
  void dispose() {
    pusher?.unsubscribe(ch);
    pusher?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (null != url) ...[
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(url ?? "")),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              transparentBackground: true,
              mediaPlaybackRequiresUserGesture: true,
              iframeAllowFullscreen: true,
            ),
            onLoadStop: (controller, url) {
              if (widget.onLoading != null) {
                widget.onLoading?.call(false);
              }

              setState(() {
                isLoading = false;
              });
            },
            onReceivedError: (controller, request, error) {
              if (widget.onLoading != null) {
                widget.onLoading?.call(false);
              }
              setState(() {
                isLoading = false;
              });
            },
          )
        ],
        if (widget.showLoading && isLoading) ...[
          Positioned.fill(
            child: widget.loadingWidget ?? CircularProgressIndicator.adaptive(),
          )
        ]
      ],
    );
  }
}
