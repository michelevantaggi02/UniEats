import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';




class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => LoginState();
}

class LoginState extends State<LoginPage> {

  bool statoPulsante = false;

  final email = TextEditingController();

  final password = TextEditingController();
  HeadlessInAppWebView? headlessWebView;
  InAppWebViewController? controller;
  late ElevatedButton buttonLogin;
  String? url  ="";


  @override
  void initState() {
    super.initState();

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest:
      URLRequest(url: Uri.parse("https://intrastudents.adisu.umbria.it")),

      onWebViewCreated: ( InAppWebViewController controller) {
        setState(() {
          statoPulsante = true;
        });
        this.controller = controller;
      },
      onLoadStart: (InAppWebViewController controller, url) async {
        //print(url);
        CookieManager manager = CookieManager.instance();
        if(url.toString() == "https://intrastudents.adisu.umbria.it/intrastudents?check_logged_in=1" || (await manager.getCookies(
        url: Uri.parse("https://intrastudents.adisu.umbria.it"))).length == 3){
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const MyHomePage()),
                (Route<dynamic> route) => false,
          );
        }
      }
    );

    headlessWebView?.run();
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    headlessWebView?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    buttonLogin = ElevatedButton(

      onPressed: statoPulsante ? () async {


        String mail = email.text;
        String pass = password.text;
        controller?.evaluateJavascript(source: """
        
        document.querySelector("#edit-name").value = "$mail";
        document.querySelector("#edit-pass").value = "$pass";
        document.querySelector("#edit-submit").click();
        
        """);

      } : null,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
      child: const Text("Log In"),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
      ),
      body: Center(
        child: Form(
            child: Column(
              children: [
                SizedBox(
                  width: 500,

                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Email",
                      icon: Icon(Icons.email),


                    ),
                    autofillHints: const [AutofillHints.email],
                    controller: email,
                    keyboardType: TextInputType.emailAddress,

                  ),
                ),

                SizedBox(
                  width: 500,
                  child: TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      icon: Icon(Icons.password),
                    ),
                    validator: (String? val) {
                      if (val == null || val.isEmpty) {
                        return "Insert valid password";
                      }
                      return null;
                    },
                    controller: password,
                    autofillHints: const [AutofillHints.password],
                    onEditingComplete: () => TextInput.finishAutofillContext(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  child: buttonLogin,
                ),
                const Text("Se hai già eseguito il login, chiudi e riapri la app.\n Se questa schermata ricompare rieseguire il login", style: TextStyle(color: Colors.amber), textAlign: TextAlign.center,),
              ],
            )),
        ),

    );
  }
}
