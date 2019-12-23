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
import "package:scoped_model/scoped_model.dart";
import 'package:flutter_calendar_carousel/classes/event_list.dart';
import "utils.dart" as utils;
import "DBWorker.dart";

// This constant describes the period (in days) between the last DueDate
// and the the current date that we'll check against. If DueDate is within this
// period we'll compute a new year of DueDates.
const int DAYS_UNTIL_AUTORENEWAL = 31;
// Alias for DBWorker.db
dynamic _db = DBWorker.db;

class Tenant {
  int id;
  String name;
  int rent;
  int paymentInterval;
  String apartmentBuilding;
  String optionalNote;
  String tenancyDate;

  @override
  String toString() {
    return "[id= ${id}, name= ${name}, rent= ${rent}, paymentInterval= ${paymentInterval}, "
        "apartmentBuilding= ${apartmentBuilding}, optionalNote= ${optionalNote}, "
        "tenancyDate= ${tenancyDate}]";
  }
}

class DueDate {
  int id;
  int tenantID;
  String date;
  String isLastDate = "false";

  DueDate({this.tenantID, this.date, this.isLastDate});
}

class DueDateEvent {
  final DateTime date;
  final Widget icon;
  final int tenantID;

  DueDateEvent({this.date, this.icon, this.tenantID});
}

class DataModel extends Model {
  int stackIndex = 0;
  List tenantsList = [];
  List tempTenantsRepo = [];
  Tenant tenantBeingEdited;
  EventList<DueDateEvent> markedDateMap;

  void loadToTempTenantsRepo(int inTenantID) async {
    tempTenantsRepo.add(await _db.get(inTenantID));
    notifyListeners();
  }

  void loadTenants() async {
    tenantsList = await _db.getAll();
    notifyListeners();
  }

  void loadDueDates() async {
    markedDateMap = EventList();
    List dueDatesList = await _db.getDueDates();
    for (int i = 0; i < dueDatesList.length; i++) {
      DateTime date = utils.parseDueDateToDateTime(dueDatesList[i]);
      markedDateMap.add(
          date, DueDateEvent(date: date, tenantID: dueDatesList[i].tenantID));
    }
    notifyListeners();
  }

  void checkForAutoRenewal() async {
    List lastDueDates = await _db.getLastDates();

    for (int i = 0; i < lastDueDates.length; i++) {
      DateTime lastDate = utils.parseStringToDateTime(lastDueDates[i].date);

      // If the difference is not negative, and is less then DAYS_UTIL_COMPUTE.
      if ((DateTime.now().difference(lastDate).inDays > 0) &&
          (DateTime.now().difference(lastDate).inDays <
              DAYS_UNTIL_AUTORENEWAL)) {
        Tenant tenant = await _db.get(lastDueDates[i].tenantID);
        int paymentInterval = tenant.paymentInterval;

        List<DueDate> dueDates = utils.computeDueDatesList(
            year: lastDate.year,
            month: lastDate.month,
            day: lastDate.day,
            paymentInterval: paymentInterval,
            tenantID: lastDueDates[i].tenantID,
            firstPaymentIsIn: true);

        lastDueDates[i].isLastDate = "false";

        await _db.insertAutoRenewal(lastDueDates[i], dueDates);
        loadDueDates();
      }
    }
  }

  void setStackIndex(int inStackIndex) {
    stackIndex = inStackIndex;
    notifyListeners();
  }

  void setPaymentInterval(int inPaymentInterval) {
    tenantBeingEdited.paymentInterval = inPaymentInterval;
    notifyListeners();
  }

  Future create(Tenant inTenant) async {
    return await _db.create(inTenant);
  }

  Future update(Tenant inTenant) async {
    return await _db.update(inTenant);
  }

  Future<Tenant> get(int inID) async {
    return await _db.get(inID);
  }

  Future delete(int inID) async {
    return await _db.delete(inID);
  }
}

DataModel dataModel = new DataModel();
