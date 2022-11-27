import 'dart:convert';
import 'dart:math';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart';
import "package:html/parser.dart";
import 'package:mensa_adisu/container_aperto.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CookieManager manager = CookieManager.instance();
  cookies = await manager.getCookies(
      url: Uri.parse("https://intrastudents.adisu.umbria.it"));
  //print(cookies);
  validCookie = cookies?.length == 3;
  // print(valid_cookie);
  runApp(const MyApp());
}

List? cookies;
bool validCookie = false;

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Mensa',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),

      home: validCookie ? const MyHomePage() : const LoginPage(),
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
  List<dynamic> listaMense = [];

  void ottieni() {
    String biscotti = "";
    cookies?.forEach((element) {
      biscotti += element.name + "=" + element.value + "; ";
    });

    // print("inizio la richiesta delle mense");
    var risposta = get(
        Uri.parse(
            'https://intrastudents.adisu.umbria.it/prenotazioni-mensa?_wrapper_format=drupal_ajax'),
        headers: {"Cookie": biscotti});

    List<Widget> finale = [];
    List<dynamic> mense = [];

    risposta.then((Response value) {
      String stringa = jsonDecode(value.body)[3]["data"];
      //print(stringa);
      var base = parse(stringa);

      base
          .querySelectorAll("div.flex-container > div[style=\"flex-grow: 1\"]")
          .forEach((element) {
        String? nomeMensa =
            element.querySelector("h4")?.text.replaceAll("Mensa ", "").trim();

        String? gestore = element
            .querySelector(
              "span.views-field-field-gestore-mensa > span.field-content",
            )
            ?.text;

        var stato = element.querySelector(
            "div.views-field-views-conditional-field > span.field-content");
        String? servizio = stato?.querySelector(".w3-btn")?.text.trim();
         List? giorni = stato?.querySelectorAll(".office-hours > .office-hours__item > .office-hours__item-label");
         List? ore = stato?.querySelectorAll(".office-hours > .office-hours__item > .office-hours__item-slots");
         String orario = "";
         for(int i = 0; i< min(giorni!.length, ore!.length); i++){
           orario += giorni[i].text+""+ore[i].text+"\n";

         }
        var menu = element.querySelector(".w3-modal");

        List<Map?> listaMenu = [];

        menu
            ?.querySelectorAll(".w3-container .w3-row-padding .w3-col")
            .forEach((ora) {
          Map<String, dynamic> nuovoMenu = {};
          nuovoMenu["nome"] = ora.querySelector("header > p")?.text;
          nuovoMenu["contenuti"] = [];

          //print(ora.innerHtml);
          // print(ora.querySelectorAll("div.view-content > div.w3-center > .w3-border-bottom"));
          ora.querySelectorAll(
                  "div.view-content > div.w3-center > div.w3-border-bottom")
              .forEach((contenuto) {

            Map listaContenuti = {};
            String? nomeContenuto = contenuto.querySelector("h4")?.text;

            listaContenuti["nome"] = nomeContenuto;
            listaContenuti["piatti"] = [];

            contenuto.querySelectorAll("div[class^='w3-text'], div[class*='w3-text'] > div.node--type-ricetta").forEach((ricetta) {

              Map piatto = {};
              piatto["nome"] = ricetta.querySelector("h4")?.text;
              piatto["ingredienti"] = [];
              ricetta.querySelectorAll("h6").forEach((h6) { piatto["ingredienti"].add(h6.text.replaceAll(" X", "").trim());});

              listaContenuti["piatti"].add(piatto);
            });

            nuovoMenu["contenuti"].add(listaContenuti);

          });
          
          
          
          listaMenu.add(nuovoMenu);
        });
        mense.add({"nome" : nomeMensa, "orario": orario, "menu" : listaMenu, "servizio" : servizio, "gestore" : gestore});

        /*Widget scheda = Padding(
          padding: const EdgeInsets.all(8.0),
          child: OpenContainer(
            tappable: servizio == "Servizio Regolare",
            closedColor: Colors.transparent,
            openBuilder: (BuildContext context,
                void Function({Object? returnValue}) action) {
              return ContainerAperto(
                nomeMensa: nomeMensa,
                listaMenu: listaMenu,
                orario: orario,
              );
            },

            closedBuilder: (BuildContext context, void Function() action) {
              return SizedBox(
                height: 100,
                child: Container(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: servizio == "Servizio Regolare" ? Colors.amber : Colors.transparent, width: 2))),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(nomeMensa!, textScaleFactor: 1.5, style: TextStyle(color: servizio == "Servizio Regolare" ? Colors.amber : Colors.black)),
                        Text((gestore != null ? "Gestita da: $gestore" : "")),

                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );

        finale.add(scheda);*/
      });

      setState(() {
        // print(finale);
        listaMense = mense;
      });
      //var doc = jsonDecode(value)[3].data
    });
  }

  @override
  void initState() {
    // print("creo lo stato");
    listaMense = [
    ];
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
      ),
      body: listaMense.isNotEmpty ? Scrollbar(
        child: Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: [
              for(final mensa in listaMense)
                Scheda(listaMenu: mensa["menu"], orario: mensa["orario"],nomeMensa: mensa["nome"], gestore: mensa["gestore"], servizio: mensa["servizio"],),
            ],

          ),
        )),
      ) : const LinearProgressIndicator(color: Colors.amber,),
    );
  }


}

class Scheda extends StatelessWidget{
  final String? servizio;
  final String? nomeMensa;
  final List<Map?> listaMenu;
  final String? orario;
  final String? gestore;
  const Scheda({Key? key, this.servizio, this.nomeMensa, required this.listaMenu, this.orario, this.gestore}) : super(key: key);

  
  
  
  @override
  Widget build(BuildContext context) {
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: OpenContainer(
        tappable: servizio == "Servizio Regolare",
        closedColor: Colors.transparent,
        openBuilder: (BuildContext context,
            void Function({Object? returnValue}) action) {
          return ContainerAperto(
            nomeMensa: nomeMensa,
            listaMenu: listaMenu,
            orario: orario,
          );
        },

        closedBuilder: (BuildContext context, void Function() action) {
          return SizedBox(
            height: 100,
            child: Container(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: servizio == "Servizio Regolare" ? Colors.amber : Colors.transparent, width: 2))),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(nomeMensa!, textScaleFactor: 1.5, style: TextStyle(color: servizio == "Servizio Regolare" ? Colors.amber : Colors.black)),
                    Text((gestore != null ? "Gestita da: $gestore" : "")),

                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
}