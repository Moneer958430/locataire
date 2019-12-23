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
import "DataModel.dart" show Tenant, DueDate;

Directory docsDir;

bool hasArabicChars(String inString) {
  for (int i = 0; i < inString.length; i++) {
    int utf = inString.codeUnitAt(i);
    if (utf >= 0x0600 && utf <= 0x06FF) {
      return true;
    }
  }
  return false;
}

DateTime parseDueDateToDateTime(DueDate inDueDate) {
  return parseStringToDateTime(inDueDate.date);
}

// The string will have to be a date of format day/month/year
DateTime parseStringToDateTime(String inDate) {
  List<String> dateParts = inDate.split("/");
  DateTime date = DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]),
      int.parse(dateParts[0]));
  return date;
}

String parseDateTimeToString(DateTime inDate) {
  return "${inDate.day}/${inDate.month}/${inDate.year}";
}

// Computes the due dates of the payments based on a passed in date, and
// a payments interval.
List<DueDate> computeDueDatesList(
    {int year,
    int month,
    int day,
    int paymentInterval,
    int tenantID,
    bool firstPaymentIsIn = false}) {
  List<DueDate> dates = List<DueDate>();
  int currentYear = DateTime.now().year;

  // If the year entered is equal to this year or before it, we'll compute the
  // DueDates all the way to the current year. However if it is in the future,
  // we'll compute the DueDate to one year only.
  if (year <= currentYear) {
    for (int i = 0; i <= (currentYear - year); i++) {
      for (int j = (firstPaymentIsIn == true ? paymentInterval : 0);
          j < 12;
          j += paymentInterval) {
        DateTime tempDate = new DateTime(year + i, month + j, day);
        DueDate date = new DueDate(
            tenantID: tenantID,
            date: "${tempDate.day}/${tempDate.month}/${tempDate.year}");
        // If this is the last payment we'll flag it so that later when we are
        // close to it and the user hasn't deleted the tenant's record we'll
        // compute another year and add it to the database.
        if (i == (currentYear - year) && j == 11) {
          date.isLastDate = "true";
        }
        dates.add(date);
      }
    }
  } else {
    // If year is more then the current year then we'll compute a single year.
    for (int i = 0; i < 12; i += paymentInterval) {
      DateTime tempDate = new DateTime(year, month + i, day);
      DueDate date = new DueDate(
          tenantID: tenantID,
          date: "${tempDate.day}/${tempDate.month}/${tempDate.year}");
      // If this is the last payment we'll flag it.
      if (i == 11) {
        date.isLastDate = "true";
      }
      dates.add(date);
    }
  }
  return dates;
}

String determineIntervalInArabic(int inPayPerYear) {
  switch (inPayPerYear) {
    case 1:
      return "شهري";
      break;
    case 2:
      return "كل شهرين";
      break;
    case 3:
      return "كل 3 شهور";
      break;
    case 4:
      return "كل 4 شهور";
      break;
    case 6:
      return "كل 6 شهور";
      break;
    case 12:
      return "سنوي";
      break;
  }
  return null;
}

String determineInterval(int inPayPerYear) {
  switch (inPayPerYear) {
    case 1:
      return "monthly";
      break;
    case 2:
      return "every 2 months";
      break;
    case 3:
      return "every 3 months";
      break;
    case 4:
      return "every 4 months";
      break;
    case 6:
      return "every 6 months";
      break;
    case 12:
      return "annually";
      break;
  }
  return null;
}

// checks if inDate conforms to format dd/mm/yyyy
// for purposes of our app the term acceptable date is loosely defined
bool checkIfStringIsAcceptableDate(String inString) {
  RegExp exp =
      new RegExp(r"^(0?[1-9]|[1-2][0-9]|3[0-1])/(0?[1-9]|1[1-2])/\d{4}$");
  RegExpMatch acceptableDate = exp.firstMatch(inString);
  if (acceptableDate == null) {
    return false;
  }
  return acceptableDate.input == inString;
}

Tenant tenantFromMap(Map inMap) {
  Tenant tenant = new Tenant();
  tenant.id = inMap["id"];
  tenant.name = inMap["name"];
  tenant.rent = inMap["rent"];
  tenant.paymentInterval = inMap["paymentInterval"];
  tenant.apartmentBuilding = inMap["apartmentBuilding"];
  tenant.optionalNote = inMap["optionalNote"];
  tenant.tenancyDate = inMap["tenancyDate"];
  return tenant;
}

DueDate dueDateFromMap(Map inMap) {
  DueDate dueDate = new DueDate();
  dueDate.id = inMap["id"];
  dueDate.tenantID = inMap["tenantID"];
  dueDate.date = inMap["date"];
  dueDate.isLastDate = inMap["isLastDate"];
  return dueDate;
}

Map<String, dynamic> tenantToMap(Tenant inTenant) {
  Map<String, dynamic> map = Map<String, dynamic>();
  map["id"] = inTenant.id;
  map["name"] = inTenant.name;
  map["rent"] = inTenant.rent;
  map["paymentInterval"] = inTenant.paymentInterval;
  map["apartmentBuilding"] = inTenant.apartmentBuilding;
  map["optionalNote"] = inTenant.optionalNote;
  map["tenancyDate"] = inTenant.tenancyDate;
  return map;
}

Map<String, dynamic> dueDateToMap(DueDate inDueDate) {
  Map<String, dynamic> map = Map<String, dynamic>();
  map["id"] = inDueDate.id;
  map["tenantID"] = inDueDate.tenantID;
  map["date"] = inDueDate.date;
  map["isLastDate"] = inDueDate.isLastDate;
  return map;
}
