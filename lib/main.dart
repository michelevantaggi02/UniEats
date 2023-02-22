import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:mensa_adisu/container_aperto.dart';
import 'package:mensa_adisu/memory_controller.dart';
import 'package:mensa_adisu/settings.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'login.dart';
import 'menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await memoryController.checkPrefs();
  // print(valid_cookie);
  runApp(const MyApp());
}

MaterialColor base = Colors.amber;

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    bool validCookie = memoryController.cookies.length == 3;

    //print(validCookie);
    return AnimatedBuilder(
      animation: ts,
      builder: (context, child) => MaterialApp(
        title: 'UniEats',
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: base,
        ),
        darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primarySwatch: base,
            indicatorColor: base,
            primaryColor: base,
            checkboxTheme:
                CheckboxThemeData(fillColor: MaterialStatePropertyAll(base))),
        themeMode: ThemeMode.values[ts.getThemeMode],
        home: validCookie ? const MyHomePage() : const LoginPage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  List<Mensa> listaMense = [];

  void controllaVersione() async {
    get(Uri.parse(
            "https://api.github.com/repos/michelevantaggi02/mensa_adisu/releases/latest"))
        .then((value) {
      final doc = jsonDecode(value.body);
      int ver =
          int.parse(doc["tag_name"].replaceAll(".", "").replaceAll("v", ""));
      PackageInfo.fromPlatform().then((value2) {
        //print(ver);
        int localVer = int.parse(value2.version.replaceAll(".", ""));
        if (localVer < ver) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await showDialog<String>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: Text("Nuova Versione Disponibile (${doc["tag_name"]})!"),
                //content: const Text("Message"),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        canLaunchUrlString(doc["html_url"]).then((can) {
                          if (can) {
                            launchUrlString(doc["html_url"],
                                mode: LaunchMode.externalApplication);
                          }
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text("Scarica")),
                  TextButton(
                    child: const Text("Non ora"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          });
        }
        //print(localVer < ver);
      });
    });
  }

  void ottieni() {
    //print("inizio la richiesta delle mense");
    if (memoryController.info == "") {
      memoryController.aggiornaInfo().then((value) {
        if (value.isNotEmpty) {
          if (mounted) {
            setState(() {
              // print(finale);
              listaMense = value;
            });
          } else {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
            }
          }
        }
      });
    } else {
      setState(() {
        listaMense = memoryController.valuta();
      });
    }
  }

  @override
  void initState() {
    // print("creo lo stato");
    if (ts.checkUpdates) controllaVersione();

    listaMense = [];
    ottieni();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // print("creo i widget");
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("Mense ADISU"),
        actions: [
          IconButton(
              onPressed: () async {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Settings()));
                //print(col);
                //ts.setTheme(col);
              },
              icon: const Icon(Icons.settings))
        ],
      ),
      body: listaMense.isNotEmpty
          ? Scrollbar(
              child: RefreshIndicator(
                onRefresh: () => memoryController.aggiornaInfo(),
                child: Center(
                    // Center is a layout widget. It takes a single child and positions it
                    // in the middle of the parent.
                    child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView(
                    children: [
                      for (final mensa in listaMense)
                        Scheda(mensa
                        ),
                    ],
                  ),
                )),
              ),
            )
          : LinearProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
    );
  }
}

class Scheda extends StatelessWidget {
  final Mensa _mensa;
  const Scheda(this._mensa, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: SizedBox(
          height: 100,
          /*decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: servizio == "Servizio Regolare"
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      width: 3))),*/
          child: TextButton(
            /*style: ButtonStyle(
                elevation: MaterialStatePropertyAll(
                    servizio == "Servizio Regolare" ? 10.0 : 0),
                backgroundColor:
                    MaterialStatePropertyAll(Theme.of(context).cardColor)),*/
            onPressed: _mensa.attiva
                ? () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContainerAperto(
                            _mensa.listaMenu,
                            nomeMensa: _mensa.nome,
                            orario: _mensa.orario,
                          ),
                        ));
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_mensa.nome,
                      textScaleFactor: 1.4,
                      style: TextStyle(
                          color: _mensa.attiva
                              ? Theme.of(context).textTheme.button?.color
                              : Theme.of(context).disabledColor)),
                  Text(
                    (_mensa.gestore != null ? "Gestita da: ${_mensa.gestore}" : ""),
                    style: TextStyle(color: Theme.of(context).disabledColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
