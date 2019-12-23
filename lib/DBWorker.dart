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

import 'package:locataire/DataModel.dart';
import "package:path/path.dart";
import "package:sqflite/sqflite.dart";
import "utils.dart" as utils;
import "DataModel.dart" show Tenant, DueDate;

class DBWorker {
  // Singleton patter through a private constructor.
  DBWorker._();

  static final DBWorker db = DBWorker._();

  Database _db;

  Future get database async {
    if (_db == null) {
      _db = await init();
    }
    return _db;
  }

  Future<Database> init() async {
    String path = join(utils.docsDir.path, "locataire.db");
    Database db = await openDatabase(path, version: 1, onOpen: (db) {},
        onCreate: (Database inDB, inVersion) async {
      await inDB.transaction((txn) async {
        try {
          await txn.execute("CREATE TABLE IF NOT EXISTS tenants ("
              "id INTEGER PRIMARY KEY,"
              "name TEXT,"
              "rent INTEGER,"
              "paymentInterval INTEGER,"
              "apartmentBuilding TEXT,"
              "optionalNote TEXT,"
              "tenancyDate TEXT"
              ")");
          await txn.execute("CREATE TABLE IF NOT EXISTS dueDates ("
              "id INTEGER PRIMARY KEY,"
              "tenantID INTEGER,"
              "date TEXT,"
              "isLastDate TEXT,"
              "CONSTRAINT FK_tenantID FOREIGN KEY (tenantID) REFERENCES tenants(id)"
              ")");
        } catch (e) {
          throw e;
        }
      });
    });
    return db;
  }

  Future create(Tenant inTenant) async {
    Database db = await database;
    var tenantIDQuery =
        await db.rawQuery("SELECT MAX(id) + 1 AS id FROM tenants");
    int tenantID = tenantIDQuery.first["id"];
    if (tenantID == null) {
      tenantID = 1;
    }

    DateTime tenancyDate = utils.parseStringToDateTime(inTenant.tenancyDate);
    List<DueDate> dueDates = utils.computeDueDatesList(
      tenantID: tenantID,
      year: tenancyDate.year,
      month: tenancyDate.month,
      day: tenancyDate.day,
      paymentInterval: inTenant.paymentInterval,
    );
    return db.transaction((txn) async {
      try {
        await txn.rawInsert(
            "INSERT INTO tenants (id, name, rent, paymentInterval, "
            "apartmentBuilding, optionalNote, tenancyDate) "
            "VALUES (?, ?, ?, ?, ?, ?, ?)",
            [
              tenantID,
              inTenant.name,
              inTenant.rent,
              inTenant.paymentInterval,
              inTenant.apartmentBuilding,
              inTenant.optionalNote,
              inTenant.tenancyDate
            ]);
        await insertDueDateList(txn, dueDates);
      } catch (e) {
        throw e;
      }
    });
  }

  Future insertDueDateList(
      Transaction txn, List<DueDate> inDueDatesList) async {
    for (int i = 0; i < inDueDatesList.length; i++) {
      await insertDueDate(txn, inDueDatesList[i]);
    }
  }

  Future insertDueDate(Transaction txn, DueDate inDueDate) async {
    var val = await txn.rawQuery("SELECT MAX(id) + 1 AS id FROM dueDates");
    int id = val.first["id"];
    if (id == null) {
      id = 1;
    }
    await txn.rawInsert(
        "INSERT INTO dueDates (id, tenantID, date, isLastDate)"
        "VALUES (?, ?, ?, ?)",
        [id++, inDueDate.tenantID, inDueDate.date, inDueDate.isLastDate]);
  }

  Future<Tenant> get(int inID) async {
    Database db = await database;
    var rec = await db.query("tenants", where: "id = ?", whereArgs: [inID]);
    return utils.tenantFromMap(rec.first);
  }

  Future<List> getAll() async {
    Database db = await database;
    var recs = await db.query("tenants");
    var list =
        recs.isNotEmpty ? recs.map((m) => utils.tenantFromMap(m)).toList() : [];
    return list;
  }

  Future<List> getDueDates() async {
    Database db = await database;
    var recs = await db.query("dueDates");
    var list = recs.isNotEmpty
        ? recs.map((m) => utils.dueDateFromMap(m)).toList()
        : [];
    return list;
  }

  // This function gets the DueDates records with the isLastDate flag
  // turned true. This flag indicated that the date is the last date in
  // the computed DueDates.
  Future<List> getLastDates() async {
    Database db = await database;
    var recs = await db
        .query("dueDates", where: "isLastDate = ?", whereArgs: ["true"]);
    print(recs);
    var list = recs.isNotEmpty
        ? recs.map((m) => utils.dueDateFromMap(m)).toList()
        : [];
    return list;
  }

  Future insertAutoRenewal(DueDate inDueDate, List<DueDate> inDueDates) async {
    Database db = await database;

    return db.transaction((txn) async {
      try {
        await updateDueDate(txn, inDueDate);
        await insertDueDateList(txn, inDueDates);
      } catch (e) {
        throw e;
      }
    });
  }

  // We are only gonna need this function to update the isLastDate of a DueDate,
  // but we'll leave it to sqlite to figure out what changed about the record
  // and update it.
  Future updateDueDate(Transaction txn, DueDate inDueDate) async {
    return await txn.update("dueDates", utils.dueDateToMap(inDueDate),
        where: "id = ?", whereArgs: [inDueDate.id]);
  }

  Future update(Tenant inTenant) async {
    Database db = await database;
    DateTime tenancyDate = utils.parseStringToDateTime(inTenant.tenancyDate);
    List<DueDate> dueDates = utils.computeDueDatesList(
        tenantID: inTenant.id,
        year: tenancyDate.year,
        month: tenancyDate.month,
        day: tenancyDate.day,
        paymentInterval: inTenant.paymentInterval);
    return await db.transaction((txn) async {
      try {
        await txn.update("tenants", utils.tenantToMap(inTenant),
            where: "id = ?", whereArgs: [inTenant.id]);
        await deleteDueDates(txn, inTenant.id);
        await insertDueDateList(txn, dueDates);
      } catch (e) {
        throw e;
      }
    });
  }

  Future delete(int inID) async {
    Database db = await database;
    return await db.transaction((txn) async {
      await txn.delete("tenants", where: "id = ?", whereArgs: [inID]);
      deleteDueDates(txn, inID);
    });
  }

  Future deleteDueDates(Transaction txn, int inTenantID) async {
    return await txn
        .delete("dueDates", where: "tenantID = ?", whereArgs: [inTenantID]);
  }
}
