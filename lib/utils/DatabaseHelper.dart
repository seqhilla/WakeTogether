import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:waketogether/data/AlarmItem.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('alarms.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const boolType = 'BOOLEAN NOT NULL';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
          CREATE TABLE $tableAlarms (
            ${AlarmFields.id} $idType,
            ${AlarmFields.name} $textType,
            ${AlarmFields.time} $textType,
            ${AlarmFields.daysActive} $textType,
            ${AlarmFields.isActive} $boolType,
            ${AlarmFields.isSingleAlarm} $boolType,
            ${AlarmFields.soundLevel} $intType,
            ${AlarmFields.isVibration} $boolType
          )
        ''');
  }

  Future<AlarmItem> create(AlarmItem alarm) async {
    final db = await instance.database;
    final id = await db.insert(tableAlarms, alarm.toJson());
    return alarm.copy(id: id);
  }

  Future<AlarmItem?> readAlarm(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      tableAlarms,
      columns: AlarmFields.values,
      where: '${AlarmFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return AlarmItem.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<List<AlarmItem>> readAllAlarms() async {
    final db = await instance.database;
    const orderBy = '${AlarmFields.time} ASC';
    final result = await db.query(tableAlarms, orderBy: orderBy);
    return result.map((json) => AlarmItem.fromJson(json)).toList();
  }

  Future<int> update(AlarmItem alarm) async {
    final db = await instance.database;
    return db.update(
      tableAlarms,
      alarm.toJson(),
      where: '${AlarmFields.id} = ?',
      whereArgs: [alarm.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableAlarms,
      where: '${AlarmFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAll() async {
    final db = await instance.database;
    return await db.delete(
      tableAlarms,
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  Future<AlarmItem?> findAlarmItem(int id) async {
    final db = await instance.database;
    final result = await db.query(
      tableAlarms,
      where: '${AlarmFields.id} = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return AlarmItem.fromJson(result.first);
    } else {
      return null;
    }
  }
}
