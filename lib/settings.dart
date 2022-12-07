import 'package:flutter/material.dart';
import "package:flutter_material_color_picker/flutter_material_color_picker.dart";
import 'package:mensa_adisu/main.dart';

class Settings extends StatefulWidget{
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
              title: const Text("Colore principale"), trailing: Icon(Icons.circle, color: Colors.primaries[ts.getIndex]),)
          ],
        ),
      ),
    );
  }

}
