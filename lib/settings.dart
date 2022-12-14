import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import "package:flutter_material_color_picker/flutter_material_color_picker.dart";
import "memory_controller.dart";

class Settings extends StatefulWidget{
  const Settings({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SettingsState();

}

class SettingsState extends  State<Settings>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("Impostazioni"),

      ),
      body: Center(
        child: ListView(
          children: [
            ListTile(
              onTap: () => showDialog(context: context, builder: (context) => AlertDialog(
                title: const Text("Scegli il colore principale"),
                content: MaterialColorPicker(
                  allowShades: false,
                  onMainColorChange: (value) {
                    ts.setTheme(Colors.primaries.indexOf(value as MaterialColor));
                  },
                  selectedColor: Colors.primaries[ts.getIndex],
                  colors: Colors.primaries,
                ),
                actions: [
                  TextButton(onPressed: ()=>Navigator.pop(context, "OK"), child: const Text("OK"))
                ],
              ),),
              title: const Text("Colore principale"), trailing: Icon(Icons.circle, color: Colors.primaries[ts.getIndex]),),
            ListTile(
              title: const Text("Stile del tema"),
              trailing: DropdownButton(items: [
                for(ThemeMode tm in ThemeMode.values)
                  DropdownMenuItem(value: tm.index, child: Text(tm.name))
              ], onChanged: (value) {
                ts.setMode(value as int);
              },
                value: ts.getThemeMode,
              ),
            ),
            ListTile(
              title: const Text("Controlla aggiornamenti all'avvio"),
              trailing: Switch(value: ts.checkUpdates, onChanged: (value) => setState(() {
                ts.setUpdates(value);
              }),),
            ),
            ListTile(
              title: const Text("Mostra immagini"),
              trailing: Switch(value: ts.showImages, onChanged: (change) => setState(() {
                ts.updateShow(change);
              }),),
            ),
            ElevatedButton(onPressed: () => DefaultCacheManager().emptyCache(), child: const Text("Svuota immagini salvate"),),

          ],
        ),
      ),
    );
  }

}
