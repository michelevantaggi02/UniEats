import 'package:flutter/material.dart';
import 'home.dart';
import 'login.dart';
import 'memory_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await memoryController.checkPrefs();
  // print(valid_cookie);
  runApp(const UniEats());
}

MaterialColor base = Colors.amber;

class UniEats extends StatelessWidget {
  const UniEats({Key? key}) : super(key: key);


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    bool validCookie = memoryController.cookies.length == 3;

    //print(validCookie);
    return AnimatedBuilder(
      animation: ts,
      builder: (context, child) => MaterialApp(
        title: 'UniEats',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: base),
        ),
        darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: base, brightness: Brightness.dark),
            ),
        themeMode: ThemeMode.values[ts.getThemeMode],
        home: validCookie ?  HomePage() : const LoginPage(),
      ),
    );
  }
}

