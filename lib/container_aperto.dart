import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart';

import 'memory_controller.dart';

class ContainerAperto extends StatefulWidget {
  final String? nomeMensa;
  final List<Map?> listaMenu;
  final String? orario;
  const ContainerAperto(
      {Key? key, required this.nomeMensa, required this.listaMenu, this.orario})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      StatoAperto(nomeMensa, listaMenu, orario);
}

Map<String, bool> filtroPiatti = {
  "mucca": true,
  "glutine": true,
  "maiale": true,
  "vegano": true,
  "vegetariano": true
};

class StatoAperto extends State<StatefulWidget> with TickerProviderStateMixin {
  final String? nomeMensa;
  List<Map?> listaMenu;
  Map<String, String> listaImmagini = {};
  final String? orario;
  TabController? controller;
  int sceltaOrario = 0;
  int sceltaPasto = 0;
  final double _imgSize = 50;

  SettingsController sc = SettingsController();

  StatoAperto(this.nomeMensa, this.listaMenu, this.orario);

  @override
  void initState() {
    if(sc.showImages){
      getImgSrc();
    }
    //print(orario);
    //print(orario?.trim());
    //print(orario?.trim().split(RegExp(r"\s+")).join(" "));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

      controller?.animateTo(sceltaPasto);

    if (listaMenu.isNotEmpty &&
        listaMenu[sceltaOrario]?["contenuti"]?.isNotEmpty) {
      controller = TabController(
          length: listaMenu[sceltaOrario]?["contenuti"].length,
          vsync: this,
          initialIndex: sceltaPasto
      );
      controller?.addListener(() {sceltaPasto = controller?.index ?? 0;});
    }
    

    Center noInfo = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Icon(Icons.broken_image_outlined),
          Text("Nessuna informazione")
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(nomeMensa!),
        bottom: listaMenu.isNotEmpty &&
                listaMenu[sceltaOrario]!["contenuti"].isNotEmpty
            ? TabBar(
                tabs: [
                  for (final tab in listaMenu[sceltaOrario]!["contenuti"])
                    Tab(text: tab!["nome"] ?? "none"),
                ],
                controller: controller,
                labelColor: Theme.of(context).textTheme.bodyText2?.color,
                labelPadding: const EdgeInsets.symmetric(horizontal: 5),

                //indicatorColor: Theme.of(context).indicatorColor,
              )
            : null,
        actions: [
          Tooltip(
            message: "Filtro",
            child: IconButton(
                onPressed: () => showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => CustomDialog(
                          contestoPadre: this,
                        )),
                icon: const Icon(Icons.filter_list)),
          ),
          Tooltip(
            message: "Info",
            child: IconButton(
                onPressed: () => showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: Text(nomeMensa ?? ""),
                        content: Text(orario?.trim() ?? ""),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'OK'),
                            child: const Text('OK'),
                          )
                        ],
                      ),
                    ),
                icon: const Icon(Icons.info_outlined)),
          ),
        ],
      ),
      body: listaMenu.isNotEmpty &&
              listaMenu[sceltaOrario]!["contenuti"].isNotEmpty
          ? TabBarView(
              controller: controller,
              children: [
                for (final tab in listaMenu[sceltaOrario]!["contenuti"])
                  tab["piatti"]?.isNotEmpty
                      ? RefreshIndicator(
                          onRefresh: () async {
                            List mense = await memoryController.aggiornaInfo();
                            //print(mense.firstWhere((element) => element["nome"] == nomeMensa));
                            if (mounted) {
                              setState(() {
                                listaMenu = mense.firstWhere((element) =>
                                    element["nome"] == nomeMensa)["menu"];
                              });
                            }
                          },
                          child: ListView(
                            padding: const EdgeInsets.all(4.0),
                            children: [
                              for (final tab2 in tab["piatti"].reversed)
                                if (filtroPiatti.entries
                                    .map((element) {
                                      //print("${tab2["nome"]}-${element.key}:${element.value || (element.value == tab2[element.key])}");
                                      return tab2[element.key] == false ||
                                          element.value == tab2[element.key];
                                    })
                                    .toList()
                                    .every((element) => element == true))
                                  ListTile(
                                    minVerticalPadding: 4.0,

                                    leading: sc.showImages && listaImmagini.containsKey(
                                            tab2["nome"].toLowerCase())
                                        ? CachedNetworkImage(
                                            imageUrl: listaImmagini[tab2["nome"]
                                                    .toLowerCase()] ??
                                                "",
                                            progressIndicatorBuilder: (context,
                                                    url, progress) =>
                                                CircularProgressIndicator(
                                                    value: progress
                                                                .downloaded /
                                                        (progress.totalSize ??
                                                            1)),
                                            height: _imgSize,
                                            width: _imgSize,
                                            fit: BoxFit.cover,
                                      cacheManager: DefaultCacheManager(),
                                          )
                                        : null,
                                    trailing: tab2["ingredienti"].isNotEmpty
                                        ? IconButton(
                                            onPressed: () => showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) =>
                                                          AlertDialog(
                                                    title: Text(
                                                        "Ingredienti ${tab2["nome"].toLowerCase()}"),
                                                    content: Text(
                                                        tab2["ingredienti"]
                                                            .join("\n")),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, 'OK'),
                                                        child: const Text('OK'),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                            icon:
                                                const Icon(Icons.info_outline))
                                        : null,
                                    title: Text(tab2["nome"].toLowerCase()),
                                    //shape: Border(bottom: BorderSide(color: Theme.of(context).primaryColor)),
                                  )
                            ],
                          ),
                        )
                      : noInfo,
              ],
        
            )
          : noInfo,
      bottomNavigationBar: listaMenu.length >= 2
          ? BottomNavigationBar(
              items: [
                for (int i = 0; i < listaMenu.length; i++)
                  BottomNavigationBarItem(
                    icon: Icon(i % 2 == 0 ? Icons.sunny : Icons.nights_stay),
                    label: listaMenu[i]!["nome"]
                        .toLowerCase()
                        .replaceAll("pranzo", "")
                        .replaceAll("cena", "")
                        .trim(),
                  )
              ],
              onTap: (i) {
                setState(() {
                  if (controller != null) {
                    controller?.dispose();
                    controller = null;
                  }
                  sceltaOrario = i;
                  getImgSrc();
                });
              },
              showUnselectedLabels: true,
              unselectedItemColor: Theme.of(context).unselectedWidgetColor,
              selectedItemColor: Theme.of(context).indicatorColor,
              currentIndex: sceltaOrario,
            )
          : null,
    );
  }

  void getImgSrc() async {
    if(listaMenu.isNotEmpty){
      for (final cont in listaMenu[sceltaOrario]?["contenuti"]) {
        for (final piatto in cont["piatti"]) {
          if (!mounted) {
            return;
          }
          String? nome = piatto["nome"].toLowerCase();
          if (!listaImmagini.containsKey(nome)) {
            //print(nome);

            String response = "";
            FileInfo? cached =
                await DefaultCacheManager().getFileFromCache(nome ?? "");
            if (cached != null) {
              response = cached.file.readAsStringSync();
            } else {
              await Future.delayed(const Duration(seconds: 1));
              Response r = await get(
                  Uri.parse(
                      "https://api.pexels.com/v1/search?query=$nome&per_page=1&locale=it-IT"),
                  headers: {
                    "Authorization":
                        "563492ad6f917000010000012a34583236804f59a9a56097bc8cdf38",
                  });
              if (r.statusCode == 200) {
                await DefaultCacheManager().putFile(
                  nome ?? "",
                  r.bodyBytes,
                  key: nome,
                  maxAge: const Duration(days: 1000),
                  eTag: nome,
                );
                response = r.body;
              }
            }

            var body = jsonDecode(response);
            if (mounted && body["error"] == null) {
              setState(() {
                listaImmagini[nome!] = body["photos"]?[0]?["src"]?["small"];
                //print(listaImmagini[nome]);
              });
            }
          }
        }
      }
    }
  }
}

class CustomDialog extends StatefulWidget {
  final StatoAperto contestoPadre;
  const CustomDialog({Key? key, required this.contestoPadre}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StatoDialog(contestoPadre);
}

class StatoDialog extends State<StatefulWidget> {
  final StatoAperto contestoPadre;
  StatoDialog(this.contestoPadre);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Filtra i risultati"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: filtroPiatti.entries.map((e) {
          return CheckboxListTile(
            title: Text(e.key),
            value: e.value,
            onChanged: (bool? value) {
              setState(() {
                //print(value);
                filtroPiatti[e.key] = value!;
              });
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, 'OK');
            if (contestoPadre.mounted) {
              contestoPadre.setState(() {
                contestoPadre.sceltaPasto = contestoPadre.controller!.index;
              });
            }
          },
          child: const Text('OK'),
        )
      ],
    );
  }
}
