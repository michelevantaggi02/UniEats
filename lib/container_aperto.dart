
import 'package:flutter/material.dart';

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

class StatoAperto extends State<StatefulWidget> with TickerProviderStateMixin {
  final String? nomeMensa;
  final List<Map?> listaMenu;
  final String? orario;
  TabController? _controller;
  int sceltaOrario = 0;

  StatoAperto(this.nomeMensa, this.listaMenu, this.orario);

  @override
  void initState() {
    //print(orario?.trim());
    //print(orario?.trim().split(RegExp(r"\s+")).join(" "));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (listaMenu.isNotEmpty &&
        listaMenu[sceltaOrario]?["contenuti"]?.isNotEmpty) {
      _controller = TabController(
          length: listaMenu[sceltaOrario]?["contenuti"].length, vsync: this);
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
                controller: _controller,
                indicatorColor: Colors.amber,
              )
            : null,
        actions: [
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
          )
        ],
      ),
      body: listaMenu.isNotEmpty &&
              listaMenu[sceltaOrario]!["contenuti"].isNotEmpty
          ? TabBarView(
              controller: _controller,
              children: [
                for (final tab in listaMenu[sceltaOrario]!["contenuti"])
                  tab["piatti"]?.isNotEmpty
                      ? ListView(
                          children: [
                            for (final tab2 in tab["piatti"].reversed)
                              ListTile(
                                trailing: tab2["ingredienti"].isNotEmpty
                                    ? IconButton(
                                        onPressed: () => showDialog(
                                              context: context,
                                              builder: (BuildContext context) =>
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
                                        icon: const Icon(Icons.info_outline))
                                    : null,
                                title: Text(tab2["nome"].toLowerCase()),
                              )
                          ],
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
                  if (_controller != null) {
                    _controller?.dispose();
                    _controller = null;
                  }
                  sceltaOrario = i;
                });
              },
              showUnselectedLabels: true,
        unselectedItemColor: Theme.of(context).unselectedWidgetColor,
              selectedItemColor: Colors.amber,
              currentIndex: sceltaOrario,
            )
          : null,
    );
  }
}
