import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdf_search_app/db.dart';
import 'package:pdf_search_app/library.dart';
import 'package:pdf_search_app/search.dart';
import 'package:pdf_search_app/ui/home_page.dart';

void main() {
  late AppDb appDb;

  setUp(() => appDb = AppDb.inMemory());
  tearDown(() => appDb.db.dispose());

  Widget app() => MaterialApp(
    home: HomePage(
      library: PdfLibrary(appDb, storageDir: Directory.systemTemp),
      engine: SearchEngine(appDb),
    ),
  );

  int addDoc(String title, List<String> pages) {
    appDb.db.execute(
      'INSERT INTO document (title, file_path, file_hash, page_count, indexed_pages) '
      'VALUES (?, ?, ?, ?, ?)',
      [title, '/x/$title.pdf', title, pages.length, pages.length],
    );
    final id = appDb.db.lastInsertRowId;
    for (var i = 0; i < pages.length; i++) {
      appDb.db.execute(
        'INSERT INTO chunk (doc_id, page_no, text, compact) VALUES (?, ?, ?, ?)',
        [id, i + 1, pages[i], AppDb.compact(pages[i])],
      );
    }
    return id;
  }

  testWidgets('문서가 없으면 추가 안내를 보여 준다', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('PDF 검색 도우미'), findsOneWidget);
    expect(find.textContaining('PDF를 추가하면'), findsOneWidget);
    expect(find.text('PDF 추가'), findsOneWidget);
  });

  testWidgets('등록된 문서를 페이지 수와 함께 보여 준다', (tester) async {
    addDoc('학사안내', ['가', '나']);
    await tester.pumpWidget(app());

    expect(find.text('학사안내'), findsOneWidget);
    expect(find.text('2쪽'), findsOneWidget);
  });

  testWidgets('검색하면 문서와 쪽 번호가 있는 결과를 보여 준다', (tester) async {
    addDoc('학사안내', ['관계없는 내용', '이번 학기 공학 융합계열 학생은 실습실을 씁니다.']);
    await tester.pumpWidget(app());

    await tester.enterText(find.byType(TextField), '융합 공학 계열');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('학사안내 · 2쪽'), findsOneWidget);
    expect(find.textContaining('공학 융합계열', findRichText: true), findsOneWidget);
  });

  testWidgets('일치하는 페이지가 없으면 안내를 보여 준다', (tester) async {
    addDoc('학사안내', ['관계없는 내용']);
    await tester.pumpWidget(app());

    await tester.enterText(find.byType(TextField), '없는단어');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('일치하는 페이지가 없어요'), findsOneWidget);
  });
}
