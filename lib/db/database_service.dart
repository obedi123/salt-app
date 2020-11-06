// needed for Directory()
import 'dart:io';
// needed for join()
import 'package:path/path.dart';
// needed for SQL database operations
import 'package:sqflite/sqflite.dart';
// needed for getApplicationDocumentsDirectory()
import 'package:path_provider/path_provider.dart';

// database table and column names
final String transactionsTable = 'transactions';
final String columnId = '_id';
final String columnTransactionId = 'transaction_id';
final String columnTimestamp = 'transaction_timestamp';
final String columnDriverId = 'driver_id';
final String columnDriverName = 'driver_name';
final String columnMachineId = 'machine_id';
final String columnFullBucketQuantity = 'full_bucket_quantity';
final String columnFiveGalQuantity = 'five_gal_quantity';
final String columnSaltType = 'salt_type';
final String columnDriverLicense = 'driver_license';
final String columnDriverPlate = 'driver_plate';
final String columnSynced = 'transaction_synced';

// data model class
class Transaction {
  int id;
  // ignore: non_constant_identifier_names
  String driver_id;
  // ignore: non_constant_identifier_names
  String transaction_id;
  // ignore: non_constant_identifier_names
  String transaction_timestamp;
  // ignore: non_constant_identifier_names
  String driver_name;
  // ignore: non_constant_identifier_names
  String machine_id;
  // ignore: non_constant_identifier_names
  String full_bucket_quantity;
  // ignore: non_constant_identifier_names
  String five_gal_quantity;
  // ignore: non_constant_identifier_names
  String salt_type;
  // ignore: non_constant_identifier_names
  String driver_license;
  // ignore: non_constant_identifier_names
  String driver_plate;
  // ignore: non_constant_identifier_names
  int transaction_synced;

  Transaction();

  // convenience constructor to create a Transaction object
  Transaction.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    driver_id = map[columnDriverId];
    transaction_id = map[columnTransactionId];
    transaction_timestamp = map[columnTimestamp];
    driver_name = map[columnDriverName];
    machine_id = map[columnMachineId];
    full_bucket_quantity = map[columnFullBucketQuantity];
    five_gal_quantity = map[columnFiveGalQuantity];
    salt_type = map[columnSaltType];
    driver_license = map[columnDriverLicense];
    driver_plate = map[columnDriverPlate];
    transaction_synced = map[columnSynced];
  }

  // convenience method to create a Map from this Transaction object
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnDriverId: driver_id,
      columnTransactionId: transaction_id,
      columnTimestamp: transaction_timestamp,
      columnDriverName: driver_name,
      columnMachineId: machine_id,
      columnFullBucketQuantity: full_bucket_quantity,
      columnFiveGalQuantity: five_gal_quantity,
      columnSaltType: salt_type,
      columnDriverLicense: driver_license,
      columnDriverPlate: driver_plate,
      columnSynced: transaction_synced,
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }
}

// singleton class to manage the database
class DatabaseHelper {
  // This is the actual database filename that is saved in the docs directory.
  static final _databaseName = "MyDatabase.db";
  // Increment this version when you need to change the schema.
  static final _databaseVersion = 1;

  // Make this a singleton class.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only allow a single open connection to the database.
  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  // open the database
  _initDatabase() async {
    // The path_provider plugin gets the right directory for Android or iOS.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    // Open the database, can also add an onUpdate callback parameter.
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL string to create the database
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $transactionsTable (
            $columnId INTEGER PRIMARY KEY,
            $columnDriverId TEXT NOT NULL,
            $columnTransactionId TEXT NOT NULL,
            $columnTimestamp TEXT NOT NULL,
            $columnDriverName TEXT NOT NULL,
            $columnMachineId TEXT NOT NULL,
            $columnFullBucketQuantity TEXT NOT NULL,
            $columnFiveGalQuantity TEXT NOT NULL,
            $columnSaltType TEXT NOT NULL,
            $columnDriverLicense TEXT NOT NULL,
            $columnDriverPlate TEXT NOT NULL,
            $columnSynced INTEGER NOT NULL
          )
          ''');
  }

  // Database helper methods:

  Future<int> insert(Transaction transaction) async {
    Database db = await database;
    int id = await db.insert(transactionsTable, transaction.toMap());
    return id;
  }

  Future<Transaction> queryTransaction(int id) async {
    Database db = await database;
    List<Map> maps = await db.query(transactionsTable,
        columns: [
          columnId,
          columnDriverId,
          columnTransactionId,
          columnTimestamp,
          columnDriverName,
          columnMachineId,
          columnFullBucketQuantity,
          columnFiveGalQuantity,
          columnSaltType,
          columnDriverLicense,
          columnDriverPlate,
          columnSynced
        ],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return Transaction.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Transaction>> queryAllTransactions(int syncState) async {
    Database db = await database;
    List<Map> maps = await db.query(transactionsTable,
        where: '$columnSynced = ?', whereArgs: [syncState]);
    if (maps.length > 0) {
      List<Transaction> transactions = [];
      maps.forEach((map) => transactions.add(Transaction.fromMap(map)));
      return transactions;
    }
    return null;
  }

  Future<int> deleteTransaction(int id) async {
    Database db = await database;
    return await db
        .delete(transactionsTable, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> update(Transaction updateTransaction) async {
    Database db = await database;
    return await db.update(transactionsTable, updateTransaction.toMap(),
        where: '$columnTransactionId = ?',
        whereArgs: [updateTransaction.transaction_id]);
  }
}
