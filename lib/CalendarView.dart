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
import "package:flutter_calendar_carousel/flutter_calendar_carousel.dart";
import "package:scoped_model/scoped_model.dart";
import "package:intl/intl.dart" as intl;
import "DataModel.dart" show DataModel, dataModel, Tenant;
import "utils.dart" as utils;
import "DataModel.dart" show dataModel, DueDateEvent;

class CalendarView extends StatelessWidget {
  Widget build(BuildContext inContext) {
    return ScopedModel<DataModel>(
      model: dataModel,
      child: ScopedModelDescendant<DataModel>(
        builder: (BuildContext inContext, Widget inChild, DataModel inModel) {
          return Scaffold(
              body: Column(children: <Widget>[
            Expanded(
                child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    child: CalendarCarousel<DueDateEvent>(
                      markedDatesMap: dataModel.markedDateMap,
                      thisMonthDayBorderColor: Colors.grey,
                      daysHaveCircularBorder: false,
                      onDayPressed:
                          (DateTime inDate, List<DueDateEvent> inEvents) {
                        _showDueDate(inDate, inEvents, inContext);
                      },
                      onCalendarChanged: (DateTime dt) {},
                    )))
          ]));
        },
      ),
    );
  }

  void _showDueDate(
      DateTime inDate, List<DueDateEvent> inEvents, BuildContext inContext) {
    dataModel.tempTenantsRepo = [];
    for (int i = 0; i < inEvents.length; i++) {
      dataModel.loadToTempTenantsRepo(inEvents[i].tenantID);
    }

    showModalBottomSheet(
        context: inContext,
        builder: (BuildContext inContext) {
          return ScopedModel<DataModel>(
              model: dataModel,
              child: ScopedModelDescendant<DataModel>(builder:
                  (BuildContext inContext, Widget inChild, DataModel inModel) {
                return Scaffold(
                    body: Container(
                        child: Padding(
                            padding: EdgeInsets.all(10),
                            child: GestureDetector(
                                child: Column(children: <Widget>[
                              Text(
                                  intl.DateFormat.yMMMMd("en_US")
                                      .format(inDate.toLocal()),
                                  style: TextStyle(
                                      color: Theme.of(inContext).accentColor,
                                      fontSize: 24)),
                              Divider(),
                              Expanded(
                                  child: ListView.builder(
                                      itemCount:
                                          dataModel.tempTenantsRepo.length,
                                      itemBuilder: (BuildContext inBuildContext,
                                          int inIndex) {
                                        Tenant tenant =
                                            dataModel.tempTenantsRepo[inIndex];

                                        return ListTile(
                                            title: Text("${tenant.name}",
                                                textDirection:
                                                    TextDirection.rtl,
                                                textAlign: TextAlign.left),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                utils.hasArabicChars(
                                                        tenant.name)
                                                    ? Text(
                                                        "\$${(tenant.rent / tenant.paymentInterval).toStringAsFixed(2)} تدفع "
                                                        "${utils.determineIntervalInArabic(tenant.paymentInterval)}.",
                                                        textDirection:
                                                            TextDirection.rtl,
                                                        textAlign:
                                                            TextAlign.left)
                                                    : Text(
                                                        "\$${(tenant.rent / tenant.paymentInterval).toStringAsFixed(2)} paid "
                                                        "${utils.determineInterval(tenant.paymentInterval)}."),
                                                utils.hasArabicChars(tenant
                                                        .apartmentBuilding)
                                                    ? Text(
                                                        "ساكن في ${tenant.apartmentBuilding}"
                                                        " بـ${tenant.tenancyDate}",
                                                        textDirection:
                                                            TextDirection.rtl,
                                                        textAlign:
                                                            TextAlign.left)
                                                    : Text(
                                                        "Moved in ${tenant.apartmentBuilding} on"
                                                        " ${tenant.tenancyDate}",
                                                        textDirection:
                                                            TextDirection.rtl),
                                                utils.hasArabicChars(
                                                        tenant.optionalNote)
                                                    ? Text(
                                                        "${tenant.optionalNote}",
                                                        textDirection:
                                                            TextDirection.rtl,
                                                        textAlign:
                                                            TextAlign.left)
                                                    : Text(
                                                        "${tenant.optionalNote}"),
                                                Divider()
                                              ],
                                            ));
                                      }))
                            ])))));
              }));
        });
  }
}
