import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_search_app/search.dart';

void main() {
  group('SearchEngine.scoreCompact', () {
    test('어순이 달라도 붙어 있으면 최고점을 준다', () {
      // 비율 1 + 근접도 1 + 순서 무관 연속 일치 2
      expect(SearchEngine.scoreCompact(['공학', '융합계열'], '융합계열공학과'), 4.0);
    });

    test('토큰이 멀리 떨어질수록 근접도 점수가 줄어든다', () {
      final text = '공학${'x' * 100}융합계열';
      expect(
        SearchEngine.scoreCompact(['공학', '융합계열'], text),
        closeTo(1 + 1 / 11, 1e-9),
      );
    });

    test('일부 토큰만 일치하면 비율 점수만 준다', () {
      expect(
        SearchEngine.scoreCompact(['a', 'b', 'c'], 'xaxbx'),
        closeTo(2 / 3, 1e-9),
      );
    });

    test('다중 토큰 검색에서 하나만 일치하면 0점이다', () {
      expect(SearchEngine.scoreCompact(['공학', '융합'], '공학만'), 0);
    });

    test('하나도 일치하지 않으면 0점이다', () {
      expect(SearchEngine.scoreCompact(['없음'], '전혀다른문장'), 0);
    });

    test('단일 토큰이 일치하면 비율과 근접도 점수를 준다', () {
      expect(SearchEngine.scoreCompact(['공학'], '공학'), 2.0);
    });
  });

  group('SearchEngine.makeSnippet', () {
    test('첫 매칭 위치 주변을 잘라 앞뒤에 말줄임표를 붙인다', () {
      final text = '${'x' * 50}Target${'y' * 200}';
      expect(
        SearchEngine.makeSnippet(text, ['target']),
        '…${text.substring(20, 140)}…',
      );
    });

    test('매칭이 없으면 청크 앞부분을 보여준다', () {
      final text = 'a' * 200;
      expect(SearchEngine.makeSnippet(text, ['zzz']), '${'a' * 90}…');
    });
  });
}
