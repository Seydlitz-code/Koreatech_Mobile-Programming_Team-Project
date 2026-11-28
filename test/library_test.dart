import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_search_app/db.dart';
import 'package:pdf_search_app/library.dart';

void main() {
  late AppDb appDb;
  late Directory storage;
  late PdfLibrary library;

  setUp(() async {
    appDb = AppDb.inMemory();
    storage = await Directory.systemTemp.createTemp('pdf_library_test');
    library = PdfLibrary(appDb, storageDir: storage);
  });

  tearDown(() async {
    appDb.db.dispose();
    if (await storage.exists()) await storage.delete(recursive: true);
  });

  int insertDoc(String path, {int pages = 3, int indexed = 3}) {
    appDb.db.execute(
      'INSERT INTO document (title, file_path, file_hash, page_count, indexed_pages) '
      'VALUES (?, ?, ?, ?, ?)',
      [p.basenameWithoutExtension(path), path, path, pages, indexed],
    );
    return appDb.db.lastInsertRowId;
  }

  test('documents()는 최근 등록 순으로 색인 상태와 함께 돌려준다', () {
    insertDoc('/a/첫번째.pdf');
    insertDoc('/a/두번째.pdf', pages: 10, indexed: 4);

    final docs = library.documents();
    expect(docs.map((d) => d.title), ['두번째', '첫번째']);
    expect(docs.first.isIndexed, isFalse);
    expect(docs.last.isIndexed, isTrue);
  });

  test('페이지 수를 아직 모르면 색인 완료가 아니다', () {
    insertDoc('/a/x.pdf', pages: 0, indexed: 0);
    expect(library.documents().single.isIndexed, isFalse);
  });

  test('remove()는 보관 폴더의 사본과 청크까지 지운다', () async {
    final dir = await Directory(p.join(storage.path, '1')).create();
    final file = await File(p.join(dir.path, 'a.pdf')).writeAsString('pdf');
    final id = insertDoc(file.path);
    appDb.db.execute(
      "INSERT INTO chunk (doc_id, page_no, text, compact) VALUES (?, 1, 't', 't')",
      [id],
    );

    await library.remove(library.documents().single);

    expect(library.documents(), isEmpty);
    expect(appDb.db.select('SELECT * FROM chunk'), isEmpty);
    expect(await dir.exists(), isFalse);
  });

  test('remove()는 보관 폴더 밖의 원본 파일은 건드리지 않는다', () async {
    final outside = await Directory.systemTemp.createTemp('pdf_outside');
    addTearDown(() => outside.delete(recursive: true));
    final file = await File(p.join(outside.path, 'a.pdf')).writeAsString('pdf');
    insertDoc(file.path);

    await library.remove(library.documents().single);

    expect(await file.exists(), isTrue);
  });

  test('PDF가 아닌 파일을 가져오면 실패하고 흔적을 남기지 않는다', () async {
    await expectLater(
      library.importPdf('가짜.pdf', Stream.value('not a pdf'.codeUnits)),
      throwsA(anything),
    );

    expect(library.documents(), isEmpty);
    expect(storage.listSync(), isEmpty);
  });
}
