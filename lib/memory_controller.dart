
import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';



class MemoryController{


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

    //print(cookies);
    return 0;
  }

  Future<List> aggiornaInfo() async {
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
      CookieManager.instance().deleteAllCookies();
      SharedPreferences.getInstance().then((value) => value.clear());
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


  List valuta() {
    List<dynamic> mense = [];

    //print(stringa);
    final base = parse(info);

    //controllo ogni menu
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
      List? giorni = stato?.querySelectorAll(
          ".office-hours > .office-hours__item > .office-hours__item-label");
      List? ore = stato?.querySelectorAll(
          ".office-hours > .office-hours__item > .office-hours__item-slots");
      String orario = "";
      for (int i = 0; i < min(giorni!.length, ore!.length); i++) {
        orario += giorni[i].text + "" + ore[i].text + "\n";
      }
      final menu = element.querySelector(".w3-modal");

      List<Map?> listaMenu = [];

      menu
          ?.querySelectorAll(".w3-container .w3-row-padding .w3-col")
          .forEach((ora) {
        Map<String, dynamic> nuovoMenu = {};
        nuovoMenu["nome"] = ora.querySelector("header > p")?.text;
        nuovoMenu["contenuti"] = [];

        //print(ora.innerHtml);
        // print(ora.querySelectorAll("div.view-content > div.w3-center > .w3-border-bottom"));
        ora
            .querySelectorAll(
            "div.view-content > div.w3-center > div.w3-border-bottom")
            .forEach((contenuto) {
          Map listaContenuti = {};
          String? nomeContenuto = contenuto.querySelector("h4")?.text;

          listaContenuti["nome"] = nomeContenuto;
          listaContenuti["piatti"] = [];

          contenuto
              .querySelectorAll(
              "div[class^='w3-text'] > div.node--type-ricetta, div[class*='w3-text'] > div.node--type-ricetta")
              .forEach((ricetta) {
            Map piatto = {};
            piatto["nome"] = ricetta.querySelector("h4")?.text;
            //print(ricetta.innerHtml);
            piatto["ingredienti"] = [];
            ricetta.querySelectorAll("h6").forEach((h6) {
              piatto["ingredienti"].add(h6.text.replaceAll(" X", "").trim());
            });

            piatto["mucca"] =
                ricetta.querySelector("img[src *= 'no-cow']") == null;
            piatto["glutine"] =
                ricetta.querySelector("img[src *= 'no-gluten']") == null;
            piatto["vegano"] =
                ricetta.querySelector("img[src *= 'vegan']") != null;
            piatto["maiale"] =
                ricetta.querySelector("img[src *= 'no-pig']") == null;
            piatto["vegetariano"] =
                ricetta.querySelector("img[src *= 'vegetarian']") != null;

            listaContenuti["piatti"].add(piatto);
          });

          nuovoMenu["contenuti"].add(listaContenuti);
        });

        listaMenu.add(nuovoMenu);
      });
      mense.add({
        "nome": nomeMensa,
        "orario": orario,
        "menu": listaMenu,
        "servizio": servizio,
        "gestore": gestore
      });
    });

    return mense;
  }
}

class ThemeSettings extends ChangeNotifier {
  int _theme = 13;
  int get getIndex => _theme;
  ThemeMode tm = ThemeMode.system;
  ThemeMode get getThemeMode => tm;

  void setTheme(int theme) {
    _theme = theme;
    base = Colors.primaries[theme];
    SharedPreferences.getInstance()
        .then((value) => value.setInt("colore", theme));
    notifyListeners();
  }

  void notifyListeners() {
    super.notifyListeners();
  }
}