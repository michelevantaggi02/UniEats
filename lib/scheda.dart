import 'package:flutter/material.dart';

import 'container_aperto.dart';
import 'menu.dart';

class Scheda extends StatelessWidget {
  final Mensa _mensa;
  const Scheda(this._mensa, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(

        child: Center(
          child: ListTile(
            //style: const ButtonStyle(shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))))),

            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
            onTap: _mensa.attiva
                ? () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContainerAperto(
                        _mensa
                    ),
                  ));
            }
                : null,
            title: Text(_mensa.nome,
                style: TextStyle(
                    color: _mensa.attiva
                        ? Theme.of(context).textTheme.labelLarge?.color
                        : Theme.of(context).disabledColor)),

            subtitle: Text(
              //(_mensa.gestore != null ? "Gestita da: ${_mensa.gestore}" : ""),
              _mensa.attiva ? _mensa.linkMenu.isNotEmpty ? "Menù disponibile" : "Menù non disponibile" : "Mensa chiusa",
              style: TextStyle(color: _mensa.attiva ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor),
            ),
            titleAlignment: ListTileTitleAlignment.center,
            trailing: Icon(_mensa.attiva ? _mensa.linkMenu.isNotEmpty ? Icons.menu_book: Icons.book_outlined : Icons.close_outlined) ,

          ),
        ),
      ),
    );
  }
}
