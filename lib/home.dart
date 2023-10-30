import 'dart:math';

import 'package:flutter/material.dart';

import 'item_lista_posizioni.dart';
import 'login.dart';
import 'memory_controller.dart';
import 'menu.dart';
import 'scheda.dart';
import 'settings.dart';
import 'version_control.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  List<Mensa> listaMense = [];
  List<String> listaPosizioni = [];
  int selectedPlace = 0;


  @override
  void initState() {

    // print("creo lo stato");

    if(ts.checkUpdates) controllaVersione(context);

    listaMense = [];
    ottieni();
    super.initState();
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
              listaPosizioni = listaMense.map((e) => e.posizione).toSet().toList();
              selectedPlace = min(listaPosizioni.length - 1, ts.posto);
              //print("1 - Lista posizioni: $listaPosizioni, posizione selezionata: $selectedPlace");
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
        listaPosizioni = listaMense.map((e) => e.posizione).toSet().toList();
        selectedPlace = min(listaPosizioni.length - 1, ts.posto);
        //print("2 - Lista posizioni: $listaPosizioni, posizione selezionata: $selectedPlace");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Mensa> listaMense = this
        .listaMense
        .where((element) => listaPosizioni[selectedPlace] == element.posizione)
        .toList();

    return Scaffold(

      appBar: AppBar(
        title: Text("Mense Adisu ${listaPosizioni.isNotEmpty ? listaPosizioni[selectedPlace] : ""}"),
        centerTitle: true,
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
      drawer: Drawer(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: listaPosizioni.isNotEmpty ? ListView.separated(
            itemBuilder: (context, index) => ItemListaPosizioni(
                text: listaPosizioni[index],
                selected: index == selectedPlace,
                mense: this.listaMense
                    .where(
                        (element) => element.posizione == listaPosizioni[index])
                    .toList(),
                onTap: () => setState(() {
                      selectedPlace = index;
                      ts.setPosto(index);
                    })),
            itemCount: listaPosizioni.length,
            separatorBuilder: (BuildContext context, int index) => const Divider(),
          ) : null,
        ),
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
                      for (final mensa in listaMense) Scheda(mensa),
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
