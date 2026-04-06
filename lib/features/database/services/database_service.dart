import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseService {
  static Database? _database;

  // ─── Key derivation ────────────────────────────────────────────────────────

  String deriveKey(String masterPassword) {
    print('🔑 [DatabaseService] Deriving encryption key from master password...');
    final salt = 'focusfin_salt_v1';
    final combined = '$masterPassword$salt';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    print('🔑 [DatabaseService] Key derived successfully.');
    return digest.toString();
  }

  // ─── Open database ─────────────────────────────────────────────────────────

  Future<Database> openEncryptedDatabase(String encryptionKey) async {
    if (_database != null && _database!.isOpen) {
      print('🗄️ [DatabaseService] Database already open, reusing instance.');
      return _database!;
    }

    print('🗄️ [DatabaseService] Opening encrypted SQLCipher database...');
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'focusfin.db');
    print('🗄️ [DatabaseService] DB path: $path');

    _database = await openDatabase(
      path,
      password: encryptionKey,
      version: 3, // 👈 BUMPED TO 3 to trigger onUpgrade for budgets table
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );

    print('🗄️ [DatabaseService] ✅ Database opened successfully.');
    return _database!;
  }

  // ─── Table creation (Fresh Installs) ───────────────────────────────────────

  Future<void> _createTables(Database db, int version) async {
    print('🗄️ [DatabaseService] Creating tables (fresh install)...');

    await db.execute('''
      CREATE TABLE transactions (
        id          TEXT PRIMARY KEY,
        amount      REAL NOT NULL,
        type        TEXT NOT NULL,
        category    TEXT,
        date        TEXT NOT NULL,
        note        TEXT,
        source      TEXT,
        balance     REAL,
        raw_sms     TEXT,
        created_at  TEXT NOT NULL
      )
    ''');
    print('🗄️ [DatabaseService] ✅ transactions table created.');

    // 👈 NEW: Budgets table for fresh installs
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        UNIQUE(category, month, year)
      )
    ''');
    print('🗄️ [DatabaseService] ✅ budgets table created.');
  }

  // ─── Migration for existing installs ───────────────────────────────────────

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🗄️ [DatabaseService] Upgrading DB from v$oldVersion → v$newVersion...');

    if (oldVersion < 2) {
      // Add the two new columns to existing v1 installs
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN balance REAL');
        print('🗄️ [DatabaseService] ✅ Added column: balance');
      } catch (e) {
        print('🗄️ [DatabaseService] ⚠️ balance column may already exist: $e');
      }
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN raw_sms TEXT');
        print('🗄️ [DatabaseService] ✅ Added column: raw_sms');
      } catch (e) {
        print('🗄️ [DatabaseService] ⚠️ raw_sms column may already exist: $e');
      }
    }

    // 👈 NEW: Safely add the budgets table for users upgrading from v1 or v2 to v3
    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS budgets (
            id TEXT PRIMARY KEY,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            month INTEGER NOT NULL,
            year INTEGER NOT NULL,
            UNIQUE(category, month, year)
          )
        ''');
        print('🗄️ [DatabaseService] ✅ Added table: budgets');
      } catch (e) {
        print('🗄️ [DatabaseService] ⚠️ budgets table creation error: $e');
      }
    }
  }

  // ─── Insert transaction ────────────────────────────────────────────────────

  Future<bool> insertTransaction({
    required String id,
    required double amount,
    required String type,
    required String date,
    required String createdAt,
    double? balance,
    String? rawSms,
    String? source,
    String? note,
    String? category,
  }) async {
    if (_database == null || !_database!.isOpen) {
      print('🗄️ [DatabaseService] ❌ insertTransaction failed — DB not open.');
      return false;
    }

    print('🗄️ [DatabaseService] Inserting transaction → type=$type, amount=$amount, balance=$balance, source=$source');

    try {
      await _database!.insert(
        'transactions',
        {
          'id':         id,
          'amount':     amount,
          'type':       type,
          'category':   category,
          'date':       date,
          'note':       note,
          'source':     source,
          'balance':    balance,
          'raw_sms':    rawSms,
          'created_at': createdAt,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      print('🗄️ [DatabaseService] ✅ Transaction inserted. id=$id');
      return true;
    } catch (e, stack) {
      print('🗄️ [DatabaseService] ❌ Insert failed: $e');
      print('🗄️ [DatabaseService] StackTrace: $stack');
      return false;
    }
  }

  // ─── Fetching transactions ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchAllTransactions() async {
    if (_database == null || !_database!.isOpen) {
      print('🗄️ [DatabaseService] ❌ fetchAllTransactions — DB not open.');
      return [];
    }
    print('🗄️ [DatabaseService] Fetching all transactions...');
    final results = await _database!.query(
      'transactions',
      orderBy: 'date DESC',
    );
    print('🗄️ [DatabaseService] ✅ Fetched ${results.length} transactions.');
    return results;
  }

  // ─── Fetch Latest Balance ──────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchLatestBalanceTransaction() async {
    if (_database == null || !_database!.isOpen) {
      print('🗄️ [DatabaseService] ❌ fetchLatestBalance — DB not open.');
      return null;
    }
    print('🗄️ [DatabaseService] Fetching latest transaction with a balance...');
    final results = await _database!.query(
      'transactions',
      where: 'balance IS NOT NULL',
      orderBy: 'date DESC',
      limit: 1,
    );

    if (results.isNotEmpty) {
      print('🗄️ [DatabaseService] ✅ Found latest balance in DB.');
      return results.first;
    }

    print('🗄️ [DatabaseService] ⚠️ No transactions with a balance found.');
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchTransactionsForRange({
    required DateTime from,
    required DateTime to,
  }) async {
    if (_database == null || !_database!.isOpen) return [];
    final results = await _database!.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'date ASC',
    );
    return results;
  }

  Future<List<Map<String, dynamic>>> fetchUncategorizedTransactions() async {
    if (_database == null || !_database!.isOpen) return [];
    print('🗄️ [DatabaseService] Fetching uncategorized transactions...');
    final results = await _database!.query(
      'transactions',
      where: 'category IS NULL',
      orderBy: 'date DESC',
    );
    print('🗄️ [DatabaseService] ✅ Found ${results.length} uncategorized transactions.');
    return results;
  }

  // ─── update category ───────────────────────────────────────────────────────

  Future<bool> updateTransactionCategory({
    required String id,
    required String category,
  }) async {
    if (_database == null || !_database!.isOpen) return false;
    try {
      await _database!.update(
        'transactions',
        {'category': category},
        where: 'id = ?',
        whereArgs: [id],
      );
      print('🗄️ [DatabaseService] ✅ Category updated → id=$id category=$category');
      return true;
    } catch (e) {
      print('🗄️ [DatabaseService] ❌ Category update failed: $e');
      return false;
    }
  }

  // ─── BUDGET METHODS (NEW) ──────────────────────────────────────────────────

  Future<bool> insertOrUpdateBudget({
    required String id,
    required String category,
    required double amount,
    required int month,
    required int year,
  }) async {
    if (_database == null || !_database!.isOpen) return false;

    try {
      await _database!.insert(
        'budgets',
        {
          'id': id,
          'category': category,
          'amount': amount,
          'month': month,
          'year': year,
        },
        conflictAlgorithm: ConflictAlgorithm.replace, // Overwrites if user updates limit
      );
      print('🗄️ [DatabaseService] ✅ Budget saved for $category ($month/$year)');
      return true;
    } catch (e) {
      print('🗄️ [DatabaseService] ❌ Budget insert failed: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchBudgetsForMonth(int month, int year) async {
    if (_database == null || !_database!.isOpen) return [];

    final results = await _database!.query(
      'budgets',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
    return results;
  }

  // ─── DELETE TRANSACTION ──────────────────────────────────────────────────

  Future<bool> deleteTransaction(String id) async {
    if (_database == null || !_database!.isOpen) return false;
    try {
      await _database!.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('🗄️ [DatabaseService] ✅ Transaction deleted: $id');
      return true;
    } catch (e) {
      print('🗄️ [DatabaseService] ❌ Delete failed: $e');
      return false;
    }
  }

  // ─── EDIT TRANSACTION ────────────────────────────────────────────────────

  Future<bool> updateTransactionDetails({
    required String id,
    required double amount,
    required String type,
    required String category,
    String? note,
  }) async {
    if (_database == null || !_database!.isOpen) return false;
    try {
      // Note: We leave the 'date' and 'raw_sms' alone, just updating the user-editable fields.
      await _database!.update(
        'transactions',
        {
          'amount': amount,
          'type': type,
          'category': category,
          'note': note,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      print('🗄️ [DatabaseService] ✅ Transaction updated: $id');
      return true;
    } catch (e) {
      print('🗄️ [DatabaseService] ❌ Update failed: $e');
      return false;
    }
  }

  // ─── Close ─────────────────────────────────────────────────────────────────

  Future<void> closeDatabase() async {
    print('🗄️ [DatabaseService] Closing database...');
    await _database?.close();
    _database = null;
    print('🗄️ [DatabaseService] ✅ Database closed.');
  }

  bool get isOpen => _database != null && _database!.isOpen;
}