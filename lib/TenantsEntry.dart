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
import "DataModel.dart" show DataModel, dataModel, Tenant;
import "utils.dart" as utils;

class TenantsEntry extends StatelessWidget {
  // Alias for tenantModel.tenantBeingEdited
  final Tenant _tenant = dataModel.tenantBeingEdited;

  // Key for the form
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controller for TextFields
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _rentCtrl = TextEditingController();
  final TextEditingController _apartmentBuildingCtrl = TextEditingController();
  final TextEditingController _optionalNoteCtrl = TextEditingController();
  final TextEditingController _tenancyDateCtrl = TextEditingController();

  TenantsEntry() {
    _nameCtrl.addListener(() {
      _tenant.name = _nameCtrl.text;
    });
    _rentCtrl.addListener(() {
      _tenant.rent = _rentCtrl.text != "" ? int.parse(_rentCtrl.text) : null;
    });
    _apartmentBuildingCtrl.addListener(() {
      _tenant.apartmentBuilding = _apartmentBuildingCtrl.text;
    });
    _optionalNoteCtrl.addListener(() {
      _tenant.optionalNote = _optionalNoteCtrl.text;
    });
    _tenancyDateCtrl.addListener(() {
      _tenant.tenancyDate = _tenancyDateCtrl.text;
    });
  }

  Widget build(BuildContext inContext) {
    if (_tenant != null) {
      // Set value of controllers.
      _nameCtrl.text = _tenant.name;
      _rentCtrl.text = _tenant.rent == null ? null : _tenant.rent.toString();
      _apartmentBuildingCtrl.text = _tenant.apartmentBuilding;
      _optionalNoteCtrl.text = _tenant.optionalNote;
      _tenancyDateCtrl.text = _tenant.tenancyDate;
    }

    return ScopedModel<DataModel>(
        model: dataModel,
        child: ScopedModelDescendant<DataModel>(builder:
            (BuildContext inContext, Widget inChild, DataModel inModel) {
          return Scaffold(
              body: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    ListTile(
                        leading: Icon(Icons.account_circle),
                        title: TextFormField(
                            keyboardType: TextInputType.multiline,
                            maxLines: 1,
                            decoration:
                                InputDecoration(hintText: "Tenant's name"),
                            controller: _nameCtrl,
                            validator: (String inValue) {
                              if (inValue.length == 0) {
                                return "Please enter a name.";
                              }
                              return null;
                            })),
                    ListTile(
                      leading: Icon(Icons.av_timer),
                      title: TextFormField(
                        keyboardType: TextInputType.datetime,
                        maxLines: 1,
                        decoration: InputDecoration(hintText: "Tenancy Date"),
                        controller: _tenancyDateCtrl,
                        validator: (String inValue) {
                          if (inValue.length == 0) {
                            return "Please enter tenancy date.";
                          }
                          bool isAcceptableDate =
                              utils.checkIfStringIsAcceptableDate(inValue);
                          if (isAcceptableDate == false) {
                            return "Please make sure your date is of format dd/mm/yyyy";
                          }
                          DateTime enteredDate =
                              utils.parseStringToDateTime(inValue);
                          if (enteredDate.year < 2000) {
                            return "Please enter a year >= 2000";
                          }
                          return null;
                        },
                      ),
                    ),
                    ListTile(
                        leading: Icon(Icons.business),
                        title: TextFormField(
                            keyboardType: TextInputType.multiline,
                            maxLines: 1,
                            decoration:
                                InputDecoration(hintText: "Apartment building"),
                            controller: _apartmentBuildingCtrl,
                            validator: (String inValue) {
                              if (inValue.length == 0) {
                                return "Please enter an apartment building.";
                              }
                              return null;
                            })),
                    ListTile(
                        leading: Icon(Icons.monetization_on),
                        title: TextFormField(
                            keyboardType: TextInputType.number,
                            maxLines: 1,
                            decoration: InputDecoration(hintText: "Rent"),
                            controller: _rentCtrl,
                            validator: (String inValue) {
                              if (inValue.length == 0) {
                                return "Please enter rent";
                              }
                              if (int.tryParse(inValue) == null) {
                                return "Please enter an integer";
                              }
                              return null;
                            })),
                    ListTile(
                      leading: Icon(Icons.timelapse),
                      title: DropdownButtonFormField(
                        decoration:
                            InputDecoration(hintText: "Payment interval"),
                        items: [
                          DropdownMenuItem(
                            child: Text("Monthly"),
                            value: 1,
                          ),
                          DropdownMenuItem(
                            child: Text("Every 2 months"),
                            value: 2,
                          ),
                          DropdownMenuItem(
                            child: Text("Every 3 months"),
                            value: 3,
                          ),
                          DropdownMenuItem(
                            child: Text("Every 4 months"),
                            value: 4,
                          ),
                          DropdownMenuItem(
                            child: Text("Every 6 months"),
                            value: 6,
                          ),
                          DropdownMenuItem(
                            child: Text("Annually"),
                            value: 12,
                          )
                        ],
                        onChanged: (inValue) {
                          dataModel.setPaymentInterval(inValue);
                        },
                        value: _tenant == null ? null : _tenant.paymentInterval,
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.note),
                      title: TextFormField(
                          keyboardType: TextInputType.multiline,
                          maxLines: 7,
                          decoration:
                              InputDecoration(hintText: "Note (optional)"),
                          controller: _optionalNoteCtrl,
                          validator: (String inValue) {
                            if (inValue.length == 0) {
                              _tenant.optionalNote = "";
                            }
                            return null;
                          }),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 50),
                  child: Row(children: <Widget>[
                    FlatButton(
                        child: Text("Cancel"),
                        onPressed: () {
                          dataModel.setStackIndex(0);
                        }),
                    Spacer(),
                    FlatButton(
                        child: Text("Save"),
                        onPressed: () {
                          _save(inContext);
                        })
                  ])));
        }));
  }

  void _save(BuildContext inContext) async {
    if (!_formKey.currentState.validate()) {
      return;
    }

    if (_tenant.id == null) {
      await dataModel.create(_tenant);
    } else {
      await dataModel.update(_tenant);
    }

    dataModel.loadTenants();
    dataModel.loadDueDates();

    dataModel.setStackIndex(0);

    Scaffold.of(inContext).showSnackBar(SnackBar(
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
      content: Text("Tenant saved."),
    ));
  }
}
