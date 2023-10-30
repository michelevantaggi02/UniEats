import 'package:flutter/material.dart';
import 'scheda.dart';
import 'settings.dart';
import 'login.dart';
import 'memory_controller.dart';
import 'menu.dart';
import 'version_control.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  List<Mensa> listaMense = [];



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
    //if (ts.checkUpdates) controllaVersione();

    if(ts.checkUpdates) controllaVersione(context);

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

