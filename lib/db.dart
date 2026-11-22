import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// SQLite 래퍼. 356페이지 규모(청크 수천 개)에서는 FTS5 없이
/// 단순 테이블 + LIKE + Dart 스코어링으로 충분하다.
class AppDb {
  AppDb._(this.db);
  final Database db;

  static Future<AppDb> open() async {
    final dir = await getApplicationDocumentsDirectory();
    return AppDb.forDatabase(sqlite3.open(p.join(dir.path, 'pdf_search.db')));
  }

  /// 메모리 DB. 테스트용.
  factory AppDb.inMemory() => AppDb.forDatabase(sqlite3.openInMemory());

  /// 이미 열린 [db]에 스키마를 만들고 감싼다.
  factory AppDb.forDatabase(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS document (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        title         TEXT NOT NULL,
        file_path     TEXT NOT NULL,
        file_hash     TEXT NOT NULL UNIQUE,
        page_count    INTEGER NOT NULL DEFAULT 0,
        indexed_pages INTEGER NOT NULL DEFAULT 0   -- 중단/재개용
      );
      CREATE TABLE IF NOT EXISTS chunk (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        doc_id   INTEGER NOT NULL REFERENCES document(id) ON DELETE CASCADE,
        page_no  INTEGER NOT NULL,                 -- 1부터 시작
        text     TEXT NOT NULL,                    -- 원문 (미리보기용)
        compact  TEXT NOT NULL                     -- 공백 제거 + 소문자 (검색용)
      );
      CREATE INDEX IF NOT EXISTS idx_chunk_doc ON chunk(doc_id, page_no);
    ''');
    db.execute('PRAGMA foreign_keys = ON;');
    return AppDb._(db);
  }

  /// 공백을 모두 제거하고 소문자로 만든다.
  /// "융합 계열" / "융합계열" 같은 띄어쓰기 차이를 없애는 핵심 함수.
  static String compact(String s) =>
      s.replaceAll(RegExp(r'\s+'), '').toLowerCase();
}
