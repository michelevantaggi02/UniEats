import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'menu.dart';

final MemoryController memoryController = MemoryController();
final SettingsController ts = SettingsController();

class MemoryController {
  List cookies = [];
  String info = "";
  String oggi = "";
  String domani = "";

  Map<String, String> posTranslate = {
    "PG" : "Perugia",
    "NARNI" : "Narni",
    "TR" : "Terni",
    "ASSISI" : "Assisi"
  };

  Future<int> checkPrefs() async {
    /*final CookieManager manager = CookieManager.instance();
  cookies = await manager.getCookies(
      url: Uri.parse("https://intrastudents.adisu.umbria.it"));*/

    SharedPreferences sp = await SharedPreferences.getInstance();
    cookies.clear();
    for (final k in sp.getStringList("biscotti") ?? []) {
      //print("Trovato $k");

      cookies.add(Cookie(name: k, value: sp.getString(k)));
    }

    int data = sp.getInt("bodydate") ?? 0;
    //print(DateTime.fromMillisecondsSinceEpoch(data));
    if (data > DateTime.now().millisecondsSinceEpoch) {
      //print("cache valida");
      List<String> body = sp.getStringList("body") ?? ["", "", ""];
      info = body[0];
      oggi = body[1];
      domani = body[2];
    }

    ts._theme = sp.getInt("colore") ?? 13;
    base = Colors.primaries[ts.getIndex];
    ts.setMode(sp.getInt("tipo_tema") ?? 0);

    //print(cookies);
    return 0;
  }

  Future<List<Mensa>> aggiornaInfo() async {
    await checkPrefs();
    String biscotti = "";

    for (var element in cookies) {
      biscotti += element.name + "=" + element.value + "; ";
    }

    final value = get(
        Uri.parse(
            'https://intrastudents.adisu.umbria.it/servizio-di-ristorazione?_wrapper_format=drupal_ajax'),
        headers: {"Cookie": biscotti});

    final men_odierni = get(
        Uri.parse("https://intrastudents.adisu.umbria.it/men-odierni"),
        headers: {"Cookie": biscotti});
    final men_domani = get(
        Uri.parse("https://intrastudents.adisu.umbria.it/men-domani"),
        headers: {"Cookie": biscotti});
    List<Future<Response>> richieste = [value, men_odierni, men_domani];
    List<Response> risposte = await Future.wait(richieste);

    if (risposte[0].statusCode != 200) {
      //CookieManager.instance().deleteAllCookies();
      SharedPreferences.getInstance().then((value) {
        value.remove("body");
        value.remove("bodydate");
        value.remove("biscotti");
      });
      return [];
    }
    info = jsonDecode(risposte[0].body)[3]["data"];
    oggi = risposte[1].body;
    domani = risposte[2].body;
    //print(info);
    SharedPreferences.getInstance().then((value) {
      //print("salvo le info");
      value.setStringList("body", [info, risposte[1].body, risposte[2].body]);

      value.setInt(
          "bodydate",
          DateTime.now()
              .add(const Duration(minutes: 30))
              .millisecondsSinceEpoch);
    });
    return valuta();
  }

  List<Mensa> valuta() {
    List<Mensa> mense = [];

    final base = parse(info);
    final men_oggi = parse(oggi);
    final men_domani = parse(domani);

    //print(info);

    //ottengo la selezione di tutte le mense

    base.querySelectorAll("div.views-row").forEach((HTMLmensa) {
      //print(HTMLmensa.innerHtml);
      final checkMensa = HTMLmensa.querySelector("h3");

      if (checkMensa == null) {
        return;
      }

      List<String> nomeAndPos = checkMensa.text.trim().split("-");


      String nomeMensa = nomeAndPos.last.trim();
      String posMensa = posTranslate[nomeAndPos.first.trim()] ?? nomeAndPos.first.trim();
      print(posMensa);

      String? gestoreMensa = HTMLmensa.querySelector(
        "span.views-field-field-gestore-mensa > span.field-content",
      )?.text;

      //contiene informazioni sugli orari e sullo stato del servizio
      final stato = HTMLmensa.querySelector(
          "div.views-field-views-conditional-field > span.field-content");
      bool servizio =
          stato?.querySelector(".w3-btn")?.text.trim() == "Servizio Regolare";

      List giorni = stato?.querySelectorAll(
              ".office-hours > .office-hours__item > .office-hours__item-label") ??
          [];
      List ore = stato?.querySelectorAll(
              ".office-hours > .office-hours__item > .office-hours__item-slots") ??
          [];
      String orario = "";

      //costruisco dinamicamente l'orario di apertura
      for (int i = 0; i < min(giorni.length, ore.length); i++) {
        orario += giorni[i].text + "" + ore[i].text + "\n";
      }

      //creo una nuova mensa con gli elementi appena raccolti
      Mensa mensa = Mensa(
          nome: nomeMensa,
          posizione: posMensa,
          gestore: gestoreMensa,
          attiva: servizio,
          orario: orario);

      men_oggi
          .querySelectorAll("a[href*='/node/']")
          .where((element) => element.text.contains(mensa.nome))
          .forEach((element) {
        if (element.text.contains("Pranzo") || element.text.contains("Cena")) {
          mensa.linkMenu.add(element.attributes["href"] ?? "");
        } else {
          print(
              "ERRORE PARSING MENU\n${element.text} non contiene pranzo o cena");
        }
      });

      men_domani
          .querySelectorAll("a[href*='/node/']")
          .where((element) => element.text.contains(mensa.nome))
          .forEach((element) {
        if (element.text.contains("Pranzo") || element.text.contains("Cena")) {
          mensa.linkMenu.add(element.attributes["href"] ?? "");
        } else {
          print(
              "ERRORE PARSING MENU\n${element.text} non contiene pranzo o cena");
        }
      });
      //print(mensa.linkMenu);

      mense.add(mensa);
    });

    mense.sort((a, b) => b.attiva ? (a.attiva ? 0 : 1) : -1);



    return mense;
  }

  Menu evalMenu(String body) {
    //print("Evaluating: $body");
    final code = parse(body);

    Menu menu = Menu(
        code.querySelector(".field--name-field-turno-pasto > div")?.text ??
            "Pranzo");

    List<dom.Element> portate = code.querySelectorAll("div.w3-leftbar");

    for (dom.Element portata in portate) {
      Portata port = Portata(portata
              .querySelector(".field__label")
              ?.text
              .replaceAll("Selezione", "")
              .replaceAll("piatti", "")
              .trim() ??
          "");

      List<dom.Element> piatti = portata.querySelectorAll("a");

      for (dom.Element piatto in piatti) {
        port.aggiungiPiatto(Piatto(piatto.text, {
          "mucca": false,
          "glutine": false,
          "maiale": false,
          "vegano": false,
          "vegetariano": false
        }));
      }

      //print(port.piatti);

      menu.aggiungiPortata(port);
    }

    return menu;
  }

  Future<void> getMenu(Mensa mensa, bool forceUpdate) async {
    print("Requesting menu");
    SharedPreferences sp = await SharedPreferences.getInstance();

    int lastUpdate = sp.getInt("menudate-${mensa.nome}") ?? 0;

    print("Next update: ${DateTime.fromMillisecondsSinceEpoch(lastUpdate)}");

    if (forceUpdate || lastUpdate < DateTime.now().millisecondsSinceEpoch) {
      List<Future<Response>> requests = [];

      String biscotti = "";

      for (var element in cookies) {
        biscotti += element.name + "=" + element.value + "; ";
      }

      for (String i in mensa.linkMenu) {
        requests.add(get(Uri.parse("https://intrastudents.adisu.umbria.it$i"),
            headers: {"Cookie": biscotti}));
      }

      List<Response> responses = await Future.wait(requests);

      if (responses.every((element) => element.statusCode == 200)) {
        sp.setInt(
            "menudate-${mensa.nome}",
            DateTime.now()
                .add(const Duration(minutes: 30))
                .millisecondsSinceEpoch);
        List<String> menulist = [];

        mensa.listaMenu.clear();

        for (Response i in responses) {
          mensa.aggiungiMenu(evalMenu(i.body));
          menulist.add(i.body);
        }
        //print("Bodies: $menulist");
        sp.setStringList("menubody-${mensa.nome}", menulist);
      } else {
        print("ERRORE RICHIESTA");
      }
    } else {
      List<String> bodies = sp.getStringList("menubody-${mensa.nome}") ?? [];
      mensa.listaMenu.clear();
      if (bodies.isNotEmpty) {
        for (String i in bodies) {
          mensa.aggiungiMenu(evalMenu(i));
        }
      } else {
        getMenu(mensa, true);
      }

      return;
    }

    //tag con tutte le informazioni sui vari menu
    /**
     * OLD
     */
    /*final menu = HTMLmensa.querySelector(".w3-modal");

    menu?.querySelectorAll(".w3-container .w3-row-padding .w3-col").forEach(
          (HTMLmenu) {
        Menu nuovoMenu = Menu(HTMLmenu.querySelector("header > p")!.text);

        HTMLmenu.querySelectorAll(
            "div.view-content > div.w3-center > div.w3-border-bottom")
            .forEach((HTMLportata) {
          Portata nuovaPortata =
          Portata(HTMLportata.querySelector("h4")!.text);

          HTMLportata.querySelectorAll(
              "div[class^='w3-text'] > div.node--type-ricetta, div[class*='w3-text'] > div.node--type-ricetta")
              .forEach((ricetta) {
            Map<String, bool> allergeni = {};
            allergeni["mucca"] =
                ricetta.querySelector("img[src *= 'no-cow']") == null;
            allergeni["glutine"] =
                ricetta.querySelector("img[src *= 'no-gluten']") == null;
            allergeni["vegano"] =
                ricetta.querySelector("img[src *= 'vegan']") != null;
            allergeni["maiale"] =
                ricetta.querySelector("img[src *= 'no-pig']") == null;
            allergeni["vegetariano"] =
                ricetta.querySelector("img[src *= 'vegetarian']") != null;


            Piatto piatto =
            Piatto(ricetta.querySelector("h4")!.text, allergeni);

            ricetta.querySelectorAll("h6").forEach((h6) => piatto
                .aggiungiIngrediente(h6.text.replaceAll(" X", "").trim()));


            nuovaPortata.aggiungiPiatto(piatto);
          });
          nuovoMenu.aggiungiPortata(nuovaPortata);
        });

        mensa.aggiungiMenu(nuovoMenu);
      },
    );*/
  }
}

class SettingsController extends ChangeNotifier {
  int _theme = 13;
  int get getIndex => _theme;
  int _tm = ThemeMode.system.index;
  int get getThemeMode => _tm;

  bool _show = false;
  bool get showImages => _show;

  bool _updates = true;
  bool get checkUpdates => _updates;

  int _posto = 0;
  int get posto => _posto;

  SettingsController() {
    SharedPreferences.getInstance().then((value) {
      _theme = value.getInt("colore") ?? 13;
      _show = value.getBool("immagini") ?? false;

      _tm = value.getInt("tipo_tema") ?? 0;
      _updates = value.getBool("updates") ?? true;
      _posto = value.getInt("posto_selezionato") ?? 0;
    });
  }

  void setUpdates(bool updates) {
    _updates = updates;
    SharedPreferences.getInstance()
        .then((value) => value.setBool("updates", updates));
  }

  void setTheme(int theme) {
    _theme = theme;
    base = Colors.primaries[theme];
    SharedPreferences.getInstance()
        .then((value) => value.setInt("colore", theme));
    notifyListeners();
  }

  void setMode(int mode) {
    _tm = mode;
    SharedPreferences.getInstance()
        .then((value) => value.setInt("tipo_tema", mode));
    notifyListeners();
  }

  void updateShow(bool value) async {
    _show = value;
    SharedPreferences.getInstance().then((sp) => sp.setBool("immagini", value));
  }

  void setPosto(int posto){
    if(posto >= 0){
      _posto = posto;
      SharedPreferences.getInstance().then((value) => value.setInt("posto_selezionato", posto));
    }
  }

}
