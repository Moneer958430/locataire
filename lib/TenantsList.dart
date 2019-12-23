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

import "package:flutter/material.dart";
import 'package:scoped_model/scoped_model.dart';
import "package:flutter_slidable/flutter_slidable.dart";
import "DataModel.dart" show Tenant, DataModel, dataModel;
import "utils.dart" as utils;

class TenantsList extends StatelessWidget {
  Widget build(BuildContext inContext) {
    return ScopedModel<DataModel>(
        model: dataModel,
        child: ScopedModelDescendant<DataModel>(builder:
            (BuildContext inContext, Widget inChild, DataModel inModel) {
          return Scaffold(
              body: ListView.builder(
                padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
                itemCount: dataModel.tenantsList.length,
                itemBuilder: (BuildContext inBuildContext, int inIndex) {
                  Tenant tenant = dataModel.tenantsList[inIndex];

                  return Slidable(
                    delegate: SlidableBehindDelegate(),
                    actionExtentRatio: .25,
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5.0),
                              bottomLeft: Radius.circular(5.0))),
                      margin: EdgeInsets.only(right: 0),
                      elevation: 10,
                      child: ListTile(
                        title: Text("${tenant.name}",
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.left),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            utils.hasArabicChars(tenant.name)
                                ? Text(
                                    "\$${(tenant.rent / tenant.paymentInterval).toStringAsFixed(2)} تدفع "
                                    "${utils.determineIntervalInArabic(tenant.paymentInterval)}.",
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.left)
                                : Text(
                                    "\$${(tenant.rent / tenant.paymentInterval).toStringAsFixed(2)} paid "
                                    "${utils.determineInterval(tenant.paymentInterval)}."),
                            utils.hasArabicChars(tenant.apartmentBuilding)
                                ? Text(
                                    "ساكن في ${tenant.apartmentBuilding}"
                                    " بـ${tenant.tenancyDate}",
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.left)
                                : Text(
                                    "Moved in ${tenant.apartmentBuilding} on"
                                    " ${tenant.tenancyDate}",
                                    textDirection: TextDirection.rtl),
                            utils.hasArabicChars(tenant.optionalNote)
                                ? Text("${tenant.optionalNote}",
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.left)
                                : Text("${tenant.optionalNote}")
                          ],
                        ),
                        onTap: () async {
                          dataModel.tenantBeingEdited =
                              await dataModel.get(tenant.id);
                          dataModel.setStackIndex(1);
                        },
                      ),
                    ),
                    secondaryActions: <Widget>[
                      Card(
                          margin: EdgeInsets.fromLTRB(0, 10, 0, 5),
                          child: IconSlideAction(
                              caption: "Delete",
                              color: Colors.red,
                              icon: Icons.delete,
                              onTap: () => _deleteTenant(inContext, tenant)))
                    ],
                  );
                },
              ),
              floatingActionButton: FloatingActionButton(
                  child: Icon(Icons.add),
                  onPressed: () {
                    dataModel.tenantBeingEdited = Tenant();
                    dataModel.setStackIndex(1);
                  }));
        }));
  }

  Future _deleteTenant(BuildContext inContext, Tenant inTenant) async {
    return showDialog(
        context: inContext,
        barrierDismissible: false,
        builder: (BuildContext inAlertContext) {
          return AlertDialog(
            title: Text("Delete Tenant"),
            content: Text("Are you sure you want to delete ${inTenant.name}"),
            actions: <Widget>[
              FlatButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.of(inAlertContext).pop();
                },
              ),
              FlatButton(
                child: Text("Delete"),
                onPressed: () async {
                  await dataModel.delete(inTenant.id);
                  Navigator.of(inAlertContext).pop();
                  Scaffold.of(inContext).showSnackBar(SnackBar(
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                    content: Text("Tenant deleted."),
                  ));
                  dataModel.loadTenants();
                  dataModel.loadDueDates();
                },
              )
            ],
          );
        });
  }
}
