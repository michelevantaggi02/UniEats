import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'menu.dart';

final MemoryController memoryController = MemoryController();
final SettingsController ts = SettingsController();

class MemoryController {
  List cookies = [];
  String info = "";

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
      info = sp.getString("body") ?? "";
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
    Response value = await get(
        Uri.parse(
            'https://intrastudents.adisu.umbria.it/prenotazioni-mensa?_wrapper_format=drupal_ajax'),
        headers: {"Cookie": biscotti});

    if (value.statusCode != 200) {
      //CookieManager.instance().deleteAllCookies();
      SharedPreferences.getInstance().then((value) {
        value.remove("body");
        value.remove("bodydate");
        value.remove("biscotti");
      });
      return [];
    }
    info = jsonDecode(value.body)[3]["data"];
    SharedPreferences.getInstance().then((value) {
      //print("salvo le info");
      value.setString("body", info);

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

    //ottengo la selezione di tutte le mense

    base
        .querySelectorAll("div.flex-container > div[style=\"flex-grow: 1\"]")
        .forEach((HTMLmensa) {
      String nomeMensa =
          HTMLmensa.querySelector("h4")!.text.replaceAll("Mensa ", "").trim();

      String? gestoreMensa = HTMLmensa.querySelector(
        "span.views-field-field-gestore-mensa > span.field-content",
      )?.text;

      //contiene informazioni sugli orari e sullo stato del servizio
      final stato = HTMLmensa.querySelector(
          "div.views-field-views-conditional-field > span.field-content");
      bool servizio =
          stato?.querySelector(".w3-btn")?.text.trim() == "Servizio Regolare";

      List giorni = stato?.querySelectorAll(
          ".office-hours > .office-hours__item > .office-hours__item-label") ?? [];
      List ore = stato?.querySelectorAll(
          ".office-hours > .office-hours__item > .office-hours__item-slots") ?? [];
      String orario = "";

      //costruisco dinamicamente l'orario di apertura
      for (int i = 0; i < min(giorni.length, ore.length); i++) {
        orario += giorni[i].text + "" + ore[i].text + "\n";
      }

      //creo una nuova mensa con gli elementi appena raccolti
      Mensa mensa = Mensa(
          nome: nomeMensa,
          gestore: gestoreMensa,
          attiva: servizio,
          orario: orario);

      //tag con tutte le informazioni sui vari menu
      final menu = HTMLmensa.querySelector(".w3-modal");

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
      );

      mense.add(mensa);

    });

    mense.sort(
        (a,b) => b.attiva ? (a.attiva ? 0 : 1 ): -1
    );

    return mense;
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

  SettingsController() {
    SharedPreferences.getInstance().then((value) {
      _theme = value.getInt("colore") ?? 13;
      _show = value.getBool("immagini") ?? false;

      _tm = value.getInt("tipo_tema") ?? 0;
      _updates = value.getBool("updates") ?? true;
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
}
