import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdf_search_app/db.dart';
import 'package:pdf_search_app/library.dart';
import 'package:pdf_search_app/search.dart';
import 'package:pdf_search_app/ui/app_shell.dart';

void main() {
  late AppDb appDb;

  setUp(() => appDb = AppDb.inMemory());
  tearDown(() => appDb.db.dispose());

  Widget app() => MaterialApp(
    home: AppShell(
      library: PdfLibrary(appDb, storageDir: Directory.systemTemp),
      engine: SearchEngine(appDb),
    ),
  );

  int addDoc(String title, List<String> pages, {int? indexed}) {
    appDb.db.execute(
      'INSERT INTO document (title, file_path, file_hash, page_count, indexed_pages) '
      'VALUES (?, ?, ?, ?, ?)',
      [title, '/x/$title.pdf', title, pages.length, indexed ?? pages.length],
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

  Future<void> goTo(WidgetTester tester, String tab) async {
    await tester.tap(
      find.descendant(of: find.byType(NavigationBar), matching: find.text(tab)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String query) async {
    await goTo(tester, '검색');
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('문서가 없으면 홈에서 등록 안내를 보여 준다', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('PDF 검색 도우미'), findsOneWidget);
    expect(find.text('아직 등록된 문서가 없습니다.'), findsOneWidget);
    expect(find.text('PDF 문서 등록'), findsOneWidget);
  });

  testWidgets('홈에 등록된 문서 수와 색인 미완료 수를 보여 준다', (tester) async {
    addDoc('학사안내', ['가', '나']);
    addDoc('수강편람', ['가', '나'], indexed: 1);
    await tester.pumpWidget(app());

    expect(find.text('2개 문서 · 색인 미완료 1개'), findsOneWidget);
  });

  testWidgets('홈의 [요람 내용 검색]은 검색 탭으로 이동한다', (tester) async {
    await tester.pumpWidget(app());

    await tester.scrollUntilVisible(find.text('요람 내용 검색'), 200);
    await tester.tap(find.text('요람 내용 검색'));
    await tester.pumpAndSettle();

    expect(find.text('내용 검색'), findsOneWidget);
  });

  testWidgets('문서 관리 탭에 문서를 페이지 수와 함께 보여 준다', (tester) async {
    addDoc('학사안내', ['가', '나']);
    await tester.pumpWidget(app());
    await goTo(tester, '문서 관리');

    expect(find.text('학사안내'), findsOneWidget);
    expect(find.text('2쪽'), findsOneWidget);
  });

  testWidgets('문서가 없으면 문서 관리 탭에서 추가 버튼을 보여 준다', (tester) async {
    await tester.pumpWidget(app());
    await goTo(tester, '문서 관리');

    expect(find.textContaining('등록된 문서가 없습니다.'), findsOneWidget);
    expect(find.text('PDF 추가'), findsOneWidget);
  });

  testWidgets('검색하면 문서와 쪽 번호가 있는 결과를 보여 준다', (tester) async {
    addDoc('학사안내', ['관계없는 내용', '이번 학기 공학 융합계열 학생은 실습실을 씁니다.']);
    await tester.pumpWidget(app());
    await search(tester, '융합 공학 계열');

    expect(find.text('학사안내'), findsOneWidget);
    expect(find.text('2쪽'), findsOneWidget);
    expect(find.textContaining('공학 융합계열', findRichText: true), findsOneWidget);
  });

  testWidgets('일치하는 페이지가 없으면 안내를 보여 준다', (tester) async {
    addDoc('학사안내', ['관계없는 내용']);
    await tester.pumpWidget(app());
    await search(tester, '없는단어');

    expect(find.textContaining('일치하는 페이지가 없어요'), findsOneWidget);
  });

  testWidgets('문서가 없을 때 검색 탭은 등록을 안내한다', (tester) async {
    await tester.pumpWidget(app());
    await goTo(tester, '검색');

    expect(find.textContaining('먼저 PDF를 등록해 주세요'), findsOneWidget);
  });
}
