import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

import 'db.dart';

typedef ProgressCallback = void Function(int donePages, int totalPages);

/// PDF -> 페이지별 텍스트 추출 -> 청킹 -> DB 저장.
/// 페이지 단위로 커밋하므로 앱이 꺼져도 indexed_pages 부터 이어서 처리한다.
class PdfIndexer {
  PdfIndexer(this._appDb);
  final AppDb _appDb;

  static const int chunkSize = 400; // 청크 길이(글자)
  static const int chunkOverlap = 50; // 겹침(경계에 걸린 키워드 보호)

  /// PDF를 등록(또는 이어서 인덱싱)하고 document id를 반환한다.
  Future<int> register(String path, {ProgressCallback? onProgress}) async {
    final db = _appDb.db;
    final hash = (await sha1.bind(File(path).openRead()).first).toString();
    final docId = upsertDocument(path, hash);

    final doc = await PdfDocument.openFile(path);
    try {
      final total = doc.pages.length;
      db.execute('UPDATE document SET page_count = ? WHERE id = ?', [
        total,
        docId,
      ]);

      final start =
          db.select('SELECT indexed_pages AS n FROM document WHERE id = ?', [
                docId,
              ]).first['n']
              as int;

      final insert = db.prepare(
        'INSERT INTO chunk (doc_id, page_no, text, compact) VALUES (?, ?, ?, ?)',
      );
      try {
        for (var pageNo = start + 1; pageNo <= total; pageNo++) {
          final page = doc.pages[pageNo - 1];
          final pageText = await page.loadText();
          final raw = pageText?.fullText ?? '';

          db.execute('BEGIN');
          try {
            for (final c in chunkText(raw)) {
              insert.execute([docId, pageNo, c, AppDb.compact(c)]);
            }
            db.execute('UPDATE document SET indexed_pages = ? WHERE id = ?', [
              pageNo,
              docId,
            ]);
            db.execute('COMMIT');
          } catch (_) {
            db.execute('ROLLBACK');
            rethrow;
          }

          onProgress?.call(pageNo, total);
          // UI 스레드에 숨 쉴 틈을 준다(진행률 갱신용).
          await Future<void>.delayed(Duration.zero);
        }
      } finally {
        insert.dispose();
      }
    } finally {
      doc.dispose();
    }
    return docId;
  }

  /// 해시가 같은 문서가 있으면 그 id를, 없으면 새로 만들어 id를 반환한다.
  /// 같은 파일을 다른 위치에서 다시 등록하면 경로를 새 위치로 갱신한다.
  int upsertDocument(String path, String hash) {
    final db = _appDb.db;
    final existing = db.select('SELECT id FROM document WHERE file_hash = ?', [
      hash,
    ]);
    if (existing.isNotEmpty) {
      final docId = existing.first['id'] as int;
      db.execute('UPDATE document SET file_path = ? WHERE id = ?', [
        path,
        docId,
      ]);
      return docId;
    }
    db.execute(
      'INSERT INTO document (title, file_path, file_hash) VALUES (?, ?, ?)',
      [p.basenameWithoutExtension(path), path, hash],
    );
    return db.lastInsertRowId;
  }

  /// 문서 삭제 (chunk는 ON DELETE CASCADE)
  void remove(int docId) =>
      _appDb.db.execute('DELETE FROM document WHERE id = ?', [docId]);

  /// 페이지 텍스트를 [chunkSize]글자 창으로 자른다.
  /// 테스트하기 쉽도록 순수 함수로 분리.
  static List<String> chunkText(
    String raw, {
    int size = chunkSize,
    int overlap = chunkOverlap,
  }) {
    if (size <= 0 || overlap < 0 || overlap >= size) {
      throw ArgumentError(
        'size는 1 이상, overlap은 0 이상 size 미만이어야 합니다 '
        '(size: $size, overlap: $overlap).',
      );
    }
    final text = raw
        .replaceAll('\r', '')
        .replaceAll(RegExp(r'[ \t\u00A0]+'), ' ')
        .replaceAll(RegExp(r'\s*\n\s*'), ' ')
        .trim();
    if (AppDb.compact(text).length < 3) return const [];
    if (text.length <= size) return [text];

    final out = <String>[];
    final step = size - overlap;
    for (var i = 0; i < text.length; i += step) {
      final end = (i + size < text.length) ? i + size : text.length;
      out.add(text.substring(i, end));
      if (end == text.length) break;
    }
    return out;
  }
}
