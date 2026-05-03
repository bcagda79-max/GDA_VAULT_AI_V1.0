import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/ai_chat/models/chat_state.dart';

class ChatHistoryService {
  static final ChatHistoryService instance = ChatHistoryService._init();
  static Database? _database;
  static const _defaultCategoryIdsKey = 'default_category_ids';

  ChatHistoryService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gda_vault_chat.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Session table
    await db.execute('''
      CREATE TABLE chat_sessions (
        id TEXT PRIMARY KEY,
        title TEXT,
        last_message TEXT,
        updated_at TEXT,
        category_ids TEXT,
        year_from TEXT,
        year_to TEXT
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        session_id TEXT,
        content TEXT,
        is_user INTEGER,
        timestamp TEXT,
        citations_json TEXT,
        FOREIGN KEY (session_id) REFERENCES chat_sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE chat_sessions ADD COLUMN year_from TEXT');
      await db.execute('ALTER TABLE chat_sessions ADD COLUMN year_to TEXT');
    }
  }

  // --- Session Operations ---

  Future<void> saveSession({
    required String id,
    required String title,
    required String lastMessage,
    required List<String> categoryIds,
    String? yearFrom,
    String? yearTo,
  }) async {
    final db = await instance.database;
    await db.insert('chat_sessions', {
      'id': id,
      'title': title,
      'last_message': lastMessage,
      'updated_at': DateTime.now().toIso8601String(),
      'category_ids': jsonEncode(categoryIds),
      'year_from': yearFrom,
      'year_to': yearTo,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllSessions() async {
    final db = await instance.database;
    return await db.query('chat_sessions', orderBy: 'updated_at DESC');
  }

  Future<void> deleteSession(String sessionId) async {
    final db = await instance.database;
    await db.delete('chat_sessions', where: 'id = ?', whereArgs: [sessionId]);
    await db.delete(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> deleteAllSessions() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('chat_messages');
      await txn.delete('chat_sessions');
    });
  }

  Future<void> saveAppSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getAppSetting(String key) async {
    final db = await instance.database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> saveDefaultCategoryIds(List<String> ids) async {
    await saveAppSetting(_defaultCategoryIdsKey, jsonEncode(ids));
  }

  Future<List<String>> getDefaultCategoryIds() async {
    final raw = await getAppSetting(_defaultCategoryIdsKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.map((item) => item.toString()).toList();
  }

  Future<void> deleteAllChats() async {
    await deleteAllSessions();
  }

  // --- Message Operations ---

  Future<void> saveMessage(String sessionId, ChatMessage msg) async {
    final db = await instance.database;

    // Convert citations to JSON
    final citationsJson = jsonEncode(
      msg.citations
          .map(
            (c) => {
              'category_name': c.categoryName,
              'year': c.yearLabel,
              'page_number': c.pageNumber,
              'display_path': c.displayPath,
            },
          )
          .toList(),
    );

    await db.insert('chat_messages', {
      'id': msg.id,
      'session_id': sessionId,
      'content': msg.content,
      'is_user': msg.isUser ? 1 : 0,
      'timestamp': msg.timestamp.toIso8601String(),
      'citations_json': citationsJson,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Update session timestamp and last message
    if (msg.content.isNotEmpty) {
      await db.update(
        'chat_sessions',
        {
          'last_message': msg.content,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    }
  }

  Future<List<ChatMessage>> getMessagesForSession(String sessionId) async {
    final db = await instance.database;
    final result = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return result.map((row) {
      final citationsRaw = jsonDecode(row['citations_json'] as String) as List;
      return ChatMessage(
        id: row['id'] as String,
        content: row['content'] as String,
        isUser: (row['is_user'] as int) == 1,
        timestamp: DateTime.parse(row['timestamp'] as String),
        citations: citationsRaw
            .map((c) => SourceCitation.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
    }).toList();
  }
}
