
class Mensa{
  final String nome;
  final String? gestore;
  final bool attiva;
  final String orario;
  final List<Menu> _listaMenu = [];
  get listaMenu => _listaMenu;

  Mensa({required this.nome, this.gestore, required this.attiva, required this.orario});

  void aggiungiMenu(Menu menu) => _listaMenu.add(menu);

}

/// Menu della mensa
/// @nome pasto (Pranzo / Cena) e giorno (oggi / domani)
class Menu{
  final String nome;
  final List<Portata> _portate = [];
  List<Portata> get portate => _portate;

  Menu(this.nome);

  void aggiungiPortata(Portata portata) => _portate.add(portata);

}

/// Primi, secondi, contorni, ecc
class Portata{
  final String nome;
  final List<Piatto> _piatti = [];
  List<Piatto> get piatti => _piatti;

  Portata(this.nome);

  void aggiungiPiatto(Piatto piatto)  => _piatti.add(piatto);
}

/// Elemento del menu del giorno
class Piatto {
  final String nome;
  final List<String> _ingredienti = [];
  final Map<String, bool> _allergeni;
  Map<String, bool> get allergeni => _allergeni;
  List<String> get ingredienti => _ingredienti;

  Piatto(this.nome, this._allergeni);

  void aggiungiIngrediente(String ingrediente) => _ingredienti.add(ingrediente);

}