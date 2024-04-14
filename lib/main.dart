// ignore_for_file: avoid_unnecessary_containers, prefer_const_constructors, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? webUrl;
  String? webUrlString;
  bool isLoading = true;
  double progressV = 0.0;

  final _formKey = GlobalKey<FormState>();

  InAppWebViewController? webViewController;

  // InAppWebViewSettings settings = InAppWebViewSettings(
  //     isInspectable: kDebugMode,
  //     mediaPlaybackRequiresUserGesture: false,
  //     allowsInlineMediaPlayback: true,
  //     iframeAllow: "camera; microphone",
  //     iframeAllowFullscreen: true);

  PullToRefreshController? pullToRefreshController;

  late ContextMenu contextMenu;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  bool searchPerformed = false;

  List<String> urlList = [];
  bool isFirstTime = true;
  bool isBackPressed = false;
  final GlobalKey webViewKey = GlobalKey();
  TextEditingController searchController = TextEditingController();

  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: true,
      javaScriptEnabled: true,
      supportZoom: true,
      disableVerticalScroll: false,
      disableHorizontalScroll: false,
      verticalScrollBarEnabled: true,
      horizontalScrollBarEnabled: true,
      cacheEnabled: true,
      clearCache: false,
    ),
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
      sharedCookiesEnabled: true,
    ),
    // android: AndroidInAppWebViewOptions(
    //   defaultTextEncodingName: "UTF-8",
    // ),
  );

  @override
  void initState() {
    super.initState();
  }

//  String urlPattern = r"^(https?|ftp):\/\/[^\s/$.?#].[^\s]*$";
// RegExp regExp = RegExp(urlPattern);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.only(left: 10.0, right: 10, top: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: urlController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32.0),
                        ),
                        hintText: "Search or enter website",
                        alignLabelWithHint: false,
                        prefixIcon: IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            // Handle icon tap behavior here
                          },
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (value) {
                        setState(() {
                          searchPerformed = true;
                          urlController.text = value;
                          isLoading = true;
                        });
                        webViewController!.loadUrl(
                            urlRequest:
                                URLRequest(url: Uri.parse('https://$value')));
                      },
                      validator: (value) {
                        String urlPattern =
                            r"/^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,6}$/i;";
                        RegExp regExp = RegExp(urlPattern);
                        if (value == "") {
                          return "Please enter a website";
                        } else if (regExp.hasMatch(value!)) {
                          return null; // Valid URL
                        } else {
                          return "Please enter a valid website without http//";
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: urlController.text == ""
                          ? Container(
                              alignment: Alignment.topLeft,
                              child: Text(
                                "Hello User \n\nLets Go",
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w700),
                              ),
                            )
                          : Container(
                              child: Stack(
                                children: [
                                  // if (_formKey.currentState!.validate())
                                  InAppWebView(
                                    key: webViewKey,
                                    initialUrlRequest: URLRequest(
                                      url: Uri.tryParse(
                                        '${urlController.text}',
                                      ),
                                    ),
                                    initialOptions: options,
                                    pullToRefreshController:
                                        pullToRefreshController,
                                    onWebViewCreated: (controller) async {
                                      webViewController = controller;
                                    },
                                    onLoadStart: (controller, url) async {
                                      setState(() {
                                        isLoading = true;
                                        this.url = url.toString();
                                        urlController.text = this.url;
                                      });
                                    },
                                    shouldOverrideUrlLoading:
                                        (controller, navigationAction) async {
                                      var uri = navigationAction.request.url!;
                                      if (![
                                        "http",
                                        "https",
                                        "file",
                                        "chrome",
                                        "data",
                                        "javascript",
                                        "about"
                                      ].contains(uri.scheme)) {
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(
                                            uri,
                                          );
                                          return NavigationActionPolicy.CANCEL;
                                        }
                                      }
                                      return NavigationActionPolicy.ALLOW;
                                    },
                                    onLoadStop: (controller, url) async {
                                      pullToRefreshController?.endRefreshing();
                                      setState(() {
                                        isLoading = false;
                                        this.url = url.toString();
                                        urlController.text = this.url;
                                      });
                                    },
                                    onProgressChanged: (controller, progress) {
                                      if (progress == 100) {
                                        pullToRefreshController
                                            ?.endRefreshing();
                                      }
                                      setState(() {
                                        this.progress = progress / 100;
                                        urlController.text = this.url;
                                      });
                                    },
                                    onUpdateVisitedHistory:
                                        (controller, url, isReload) {
                                      setState(() {
                                        this.url = url.toString();
                                        urlController.text = this.url;
                                      });
                                    },
                                    onConsoleMessage:
                                        (controller, consoleMessage) {
                                      print(consoleMessage);
                                    },
                                    onLoadError:
                                        (controller, url, code, message) {
                                      urlController.clear();
                                    },
                                  ),
                                  if (progress < 1.0)
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      child: LinearProgressIndicator(
                                          value: progress),
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
