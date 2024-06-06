import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;

  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'locations.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE locations(id INTEGER PRIMARY KEY AUTOINCREMENT, latitude REAL, longitude REAL, address TEXT, date_time TEXT)',
        );
      },
    );
  }

  Future<void> insertLocation(double latitude, double longitude, String address, String formattedDateTime) async {
    final db = await database;
    await db.insert(
      'locations',
      {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'date_time': formattedDateTime
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getLocations() async {
    final db = await database;
    return await db.query('locations',
    orderBy: 'Date_Time DESC',
    );
  }
}
