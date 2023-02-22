import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart';

import 'memory_controller.dart';
import 'menu.dart';

class ContainerAperto extends StatefulWidget {
  final String? nomeMensa;
  List<Menu> listaMenu;
  final String? orario;
  ContainerAperto(this.listaMenu,
      {Key? key, required this.nomeMensa, this.orario})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => StatoAperto();
}

Map<String, bool> filtroPiatti = {
  "mucca": true,
  "glutine": true,
  "maiale": true,
  "vegano": true,
  "vegetariano": true
};

class StatoAperto extends State<ContainerAperto> with TickerProviderStateMixin {
  Map<String, String> listaImmagini = {};
  TabController? controller;
  int sceltaOrario = 0;
  int sceltaPasto = 0;
  final double _imgSize = 50;

  final SettingsController sc = SettingsController();

  StatoAperto();

  @override
  void initState() {
    if (sc.showImages) {
      getImgSrc();
    }
    //print(orario);
    //print(orario?.trim());
    //print(orario?.trim().split(RegExp(r"\s+")).join(" "));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    if (widget.listaMenu.isNotEmpty &&
        widget.listaMenu[sceltaOrario].portate.isNotEmpty) {
      controller = TabController(
          length: widget.listaMenu[sceltaOrario].portate.length,
          vsync: this,
          initialIndex: min(sceltaPasto,  widget.listaMenu[sceltaOrario].portate.length - 1));
      controller?.addListener(() {
        //print(controller?.index);
        sceltaPasto = controller?.index ?? 0;
      });
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
        title: Text(widget.nomeMensa!),
        bottom: widget.listaMenu.isNotEmpty &&
                widget.listaMenu[sceltaOrario].portate.isNotEmpty
            ? TabBar(
                tabs: [
                  for (Portata portata
                      in widget.listaMenu[sceltaOrario].portate)
                    Tab(text: portata.nome),
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
                        title: Text(widget.nomeMensa ?? ""),
                        content: Text(widget.orario?.trim() ?? ""),
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
      body: widget.listaMenu.isNotEmpty &&
              widget.listaMenu[sceltaOrario].portate.isNotEmpty
          ? TabBarView(
              controller: controller,
              children: [
                for (Portata tab in widget.listaMenu[sceltaOrario].portate)
                  tab.piatti.isNotEmpty
                      ? RefreshIndicator(
                          onRefresh: () async {
                            List<Mensa> mense = await memoryController.aggiornaInfo();
                            //print(mense.firstWhere((element) => element["nome"] == nomeMensa));
                            if (mounted) {
                              setState(() {
                                widget.listaMenu = mense.firstWhere((element) =>
                                    element.nome ==
                                    widget.nomeMensa).listaMenu;
                              });
                            }
                          },
                          child: ListView(
                            padding: const EdgeInsets.all(4.0),
                            children: [
                              for (Piatto piatto in tab.piatti.reversed)
                                if (filtroPiatti.entries
                                    .map((element) {
                                      //print("${tab2["nome"]}-${element.key}:${element.value || (element.value == tab2[element.key])}");
                                      return piatto.allergeni[element.key] == false ||
                                          element.value == piatto.allergeni[element.key];
                                    })
                                    .toList()
                                    .every((element) => element == true))
                                  ListTile(
                                    leading: sc.showImages &&
                                            listaImmagini.containsKey(
                                                piatto.nome.toLowerCase())
                                        ? CachedNetworkImage(
                                            imageUrl: listaImmagini[piatto.nome
                                                    .toLowerCase()] ??
                                                "",
                                            progressIndicatorBuilder: (context,
                                                    url, progress) =>
                                                CircularProgressIndicator(
                                                    value: progress.downloaded /
                                                        (progress.totalSize ??
                                                            1)),
                                            height: _imgSize,
                                            width: _imgSize,
                                            fit: BoxFit.cover,
                                            cacheManager: DefaultCacheManager(),
                                          )
                                        : null,
                                    trailing: piatto.ingredienti.isNotEmpty
                                        ? IconButton(
                                            onPressed: () => showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) =>
                                                          AlertDialog(
                                                    title: Text(
                                                        "Ingredienti ${piatto.nome.toLowerCase()}"),
                                                    content: Text(
                                                        piatto.ingredienti
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
                                    title: Text(piatto.nome.toLowerCase()),
                                    //shape: Border(bottom: BorderSide(color: Theme.of(context).primaryColor)),
                                  )
                            ],
                          ),
                        )
                      : noInfo,
              ],
            )
          : noInfo,
      bottomNavigationBar: widget.listaMenu.length >= 2
          ? BottomNavigationBar(
              items: [
                for (int i = 0; i < widget.listaMenu.length; i++)
                  BottomNavigationBarItem(
                    icon: Icon(i % 2 == 0 ? Icons.sunny : Icons.nights_stay),
                    label: widget.listaMenu[i].nome
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
                  if(sc.showImages){
                    getImgSrc();

                  }
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
    //print("Immagini si");
    if (widget.listaMenu.isNotEmpty) {
      for (Portata portata in widget.listaMenu[sceltaOrario].portate) {
        for (Piatto piatto in portata.piatti) {
          if (!mounted) {
            return;
          }
          String nome = piatto.nome.toLowerCase();
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
                listaImmagini[nome] = body["photos"]?[0]?["src"]?["small"];
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
  State<StatefulWidget> createState() => StatoDialog();
}

class StatoDialog extends State<CustomDialog> {


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
            if (widget.contestoPadre.mounted) {
              widget.contestoPadre.setState(() {
                widget.contestoPadre.sceltaPasto = widget.contestoPadre.controller!.index;
              });
            }
          },
          child: const Text('OK'),
        )
      ],
    );
  }
}
