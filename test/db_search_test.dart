import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_search_app/db.dart';
import 'package:pdf_search_app/indexer.dart';
import 'package:pdf_search_app/search.dart';

void main() {
  late AppDb appDb;
  late PdfIndexer indexer;
  late SearchEngine engine;

  setUp(() {
    appDb = AppDb.inMemory();
    indexer = PdfIndexer(appDb);
    engine = SearchEngine(appDb);
  });

  tearDown(() => appDb.db.dispose());

  void addChunk(int docId, int pageNo, String text) {
    appDb.db.execute(
      'INSERT INTO chunk (doc_id, page_no, text, compact) VALUES (?, ?, ?, ?)',
      [docId, pageNo, text, AppDb.compact(text)],
    );
  }

  group('PdfIndexer.upsertDocument', () {
    test('새 파일이면 문서를 만든다', () {
      final id = indexer.upsertDocument('/a/강의자료.pdf', 'h1');
      final row = appDb.db.select('SELECT * FROM document WHERE id = ?', [
        id,
      ]).first;
      expect(row['title'], '강의자료');
      expect(row['file_path'], '/a/강의자료.pdf');
    });

    test('같은 파일을 다른 위치에서 다시 등록하면 같은 id에 경로만 갱신한다', () {
      final first = indexer.upsertDocument('/download/a.pdf', 'h1');
      final second = indexer.upsertDocument('/documents/a.pdf', 'h1');

      expect(second, first);
      expect(
        appDb.db.select('SELECT COUNT(*) AS n FROM document').first['n'],
        1,
      );
      expect(
        appDb.db.select('SELECT file_path FROM document').first['file_path'],
        '/documents/a.pdf',
      );
    });
  });

  group('SearchEngine.search', () {
    test('어순과 띄어쓰기가 달라도 찾는다', () {
      final doc = indexer.upsertDocument('/a.pdf', 'h1');
      addChunk(doc, 3, '이번 학기 공학 융합계열 학생은 실습실을 씁니다.');
      addChunk(doc, 4, '관계없는 내용');

      final hits = engine.search('융합 공학 계열');
      expect(hits.map((h) => h.pageNo), [3]);
    });

    test('docId를 주면 그 문서에서만 찾는다', () {
      final d1 = indexer.upsertDocument('/a.pdf', 'h1');
      final d2 = indexer.upsertDocument('/b.pdf', 'h2');
      addChunk(d1, 1, '공학 융합계열');
      addChunk(d2, 1, '공학 융합계열');

      expect(engine.search('공학 융합계열').length, 2);
      expect(engine.search('공학 융합계열', docId: d2).map((h) => h.docId), [d2]);
    });

    test('LIKE 특수문자(%, _)는 글자 그대로 찾는다', () {
      final doc = indexer.upsertDocument('/a.pdf', 'h1');
      addChunk(doc, 1, '전 품목 100% 할인');
      addChunk(doc, 2, '파일명은 a_b 형식');
      addChunk(doc, 3, '특수문자 없는 평범한 문장');

      expect(engine.search('%').map((h) => h.pageNo), [1]);
      expect(engine.search('_').map((h) => h.pageNo), [2]);
    });

    test('같은 페이지의 청크는 최고점 하나만 남긴다', () {
      final doc = indexer.upsertDocument('/a.pdf', 'h1');
      addChunk(doc, 1, '공학 그리고 아주 먼 곳의 융합계열');
      addChunk(doc, 1, '공학융합계열');

      final hits = engine.search('공학 융합계열');
      expect(hits.length, 1);
      expect(hits.single.snippet, '공학융합계열');
    });

    test('점수가 높은 결과가 먼저 온다', () {
      final doc = indexer.upsertDocument('/a.pdf', 'h1');
      addChunk(doc, 1, '공학${'x' * 100}융합계열');
      addChunk(doc, 2, '융합계열공학');

      expect(engine.search('공학 융합계열').map((h) => h.pageNo), [2, 1]);
    });
  });
}
