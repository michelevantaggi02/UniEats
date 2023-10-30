import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

void controllaVersione(BuildContext context) async {
  print("Controllo la versione");
  get(Uri.parse(
          "https://api.github.com/repos/michelevantaggi02/UniEats/releases/latest"))
      .then((value) {
    final doc = jsonDecode(value.body);
    int ver =
        int.parse(doc["tag_name"].replaceAll(".", "").replaceAll("v", ""));
    PackageInfo.fromPlatform().then((value2) {
      //print(ver);
      int localVer = int.parse(value2.version.replaceAll(".", ""));

      if (localVer < ver) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text("Nuova Versione Disponibile (${doc["tag_name"]})!"),
              //content: const Text("Message"),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      canLaunchUrlString(doc["html_url"]).then((can) {
                        if (can) {
                          launchUrlString(doc["html_url"],
                              mode: LaunchMode.externalApplication);
                        }
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text("Scarica")),
                TextButton(
                  child: const Text("Non ora"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        });
      }
      //print(localVer < ver);
    });
  });
}
