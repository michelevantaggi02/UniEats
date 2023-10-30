import 'package:flutter/material.dart';

import 'menu.dart';

class ItemListaPosizioni extends StatelessWidget{

  late int _menseAttive;
  late int _menseChiuse;
  late int _menseNoMenu;
  final String text;
  final bool selected;
  final void Function() onTap;

  ItemListaPosizioni({ required this.text, required this.selected, required List<Mensa> mense, required this.onTap}){
    _menseAttive = mense.where((element) => element.attiva && element.linkMenu.isNotEmpty).length;
    _menseNoMenu = mense.where((element) => element.attiva && element.linkMenu.isEmpty).length;
    _menseChiuse = mense.where((element) => !element.attiva).length;

  }

  @override
  Widget build(BuildContext context) {
    return ListTile(

      title: Text(text),
      selected: selected,
      onTap: onTap,
      trailing: selected ? const Icon(Icons.check) : const Icon(null),

      subtitle:Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined),
              Text("$_menseAttive")
            ],
          ),
          Row(
            children: [
              const Icon(Icons.book_outlined),
              Text("$_menseNoMenu")
            ],
          ),
          Row(
            children: [
              const Icon(Icons.close_outlined),
              Text("$_menseChiuse")
            ],
          ),
        ],
      ),

    );
  }

}