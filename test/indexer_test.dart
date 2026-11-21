import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_search_app/db.dart';
import 'package:pdf_search_app/indexer.dart';

void main() {
  group('AppDb.compact', () {
    test('공백을 모두 지우고 소문자로 만든다', () {
      expect(AppDb.compact(' 융합 계열\tABC\n'), '융합계열abc');
    });
  });

  group('PdfIndexer.chunkText', () {
    test('의미 있는 글자가 3자 미만이면 버린다', () {
      expect(PdfIndexer.chunkText('  a b  '), isEmpty);
    });

    test('줄바꿈과 연속 공백을 공백 하나로 정리한다', () {
      expect(PdfIndexer.chunkText('hello\r\n  world'), ['hello world']);
    });

    test('짧은 텍스트는 청크 하나로 반환한다', () {
      final text = '가' * PdfIndexer.chunkSize;
      expect(PdfIndexer.chunkText(text), [text]);
    });

    test('긴 텍스트는 겹침을 두고 자른다', () {
      final text = List.generate(
        1000,
        (i) => String.fromCharCode(97 + i % 26),
      ).join();
      final chunks = PdfIndexer.chunkText(text);

      // step = 400 - 50 = 350 -> [0,400) [350,750) [700,1000)
      expect(chunks, [
        text.substring(0, 400),
        text.substring(350, 750),
        text.substring(700, 1000),
      ]);
    });
  });
}
