/*
  The MIT License

  Copyright (c) 2019 Frank W. Zammetti

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
*/

import "dart:io";
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "package:path_provider/path_provider.dart";
import "package:path/path.dart";
import "CalendarView.dart";
import "TenantsView.dart";
import "utils.dart" as utils;
import "DataModel.dart" show dataModel;

void main() {
  startMeUp() async {
    utils.docsDir = await getApplicationDocumentsDirectory();
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kReleaseMode) {
        String path = join(utils.docsDir.path, "error_log.txt");
        File errorLog = new File(path);
        if (!errorLog.existsSync()) {
          errorLog.createSync();
        }
        String content = errorLog.readAsStringSync();
        errorLog
            .writeAsString(content + "${details.exceptionAsString()}\n")
            .then((File inErrorLog) {
          _errorDialog(
              "No worries I logged the error into ${inErrorLog.path}.");
        });
        exit(1);
      } else {
        FlutterError.dumpErrorToConsole(details);
      }
    };
    dataModel.checkForAutoRenewal();
    runApp(Locataire());
  }

  startMeUp();
}

Future _errorDialog(String inMessage) {
  return showDialog(
      context: null,
      barrierDismissible: true,
      builder: (BuildContext inAlertContext) {
        return AlertDialog(
            title: Text("Oopsy! Something went wrong!"),
            content:
                Text(inMessage + "\nContact the developer to sort this out."),
            actions: <Widget>[
              FlatButton(
                child: Text("Ok"),
                onPressed: () {
                  Navigator.of(inAlertContext).pop();
                },
              )
            ]);
      });
}

class Locataire extends StatelessWidget {
  Locataire() {
    dataModel.loadDueDates();
    dataModel.loadTenants();
  }

  Widget build(BuildContext inContext) {
    return MaterialApp(
        theme: ThemeData(brightness: Brightness.dark, primaryColor: Colors.red),
        home: DefaultTabController(
            length: 2,
            child: Scaffold(
                appBar: AppBar(
                    title: Text("Locataire"),
                    bottom: TabBar(tabs: <Widget>[
                      Tab(
                        icon: Icon(Icons.date_range),
                        text: "Calendar",
                      ),
                      Tab(
                        icon: Icon(Icons.contacts),
                        text: "Tenants",
                      )
                    ])),
                drawer: Drawer(
                    child: ListView(
                  children: <Widget>[
                    DrawerHeader(),
                    ListTile(
                      leading: Icon(Icons.settings),
                      title: Text("Settings"),
                      onTap: () {},
                    ),
                    AboutListTile(
                      applicationName: "locataire",
                      applicationVersion: "1.0",
                    )
                  ],
                )),
                body: TabBarView(
                    children: <Widget>[CalendarView(), TenantsView()]))));
  }
}
