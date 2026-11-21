import 'dart:math' as math;

import 'db.dart';

class SearchHit {
  SearchHit({
    required this.chunkId,
    required this.docId,
    required this.pageNo,
    required this.snippet,
    required this.score,
    required this.terms,
  });

  final int chunkId;
  final int docId;
  final int pageNo; // 1부터 시작
  final String snippet; // 결과 리스트 미리보기
  final double score;
  final List<String> terms; // 하이라이트에 쓸 검색어 토큰
}

class SearchEngine {
  SearchEngine(this._appDb);
  final AppDb _appDb;

  /// 자연어 검색. 어순/띄어쓰기가 달라도 찾는다.
  /// 결과는 (문서, 페이지)당 최고 점수 청크 하나만 반환한다.
  List<SearchHit> search(String query, {int? docId, int limit = 30}) {
    final rawTokens = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (rawTokens.isEmpty) return const [];

    // 검색용(공백 제거/소문자) 토큰, 중복 제거
    final tokens = rawTokens.map(AppDb.compact).toSet().toList();

    // 1) 후보 수집: 토큰 중 하나라도 포함한 청크
    final candidates = <int, Map<String, Object?>>{};
    for (final t in tokens) {
      final escaped = t
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      final rows = _appDb.db.select(
        'SELECT id, doc_id, page_no, text, compact FROM chunk '
        "WHERE compact LIKE ? ESCAPE '\\'"
        '${docId != null ? ' AND doc_id = ?' : ''}',
        ['%$escaped%', ?docId],
      );
      for (final r in rows) {
        candidates[r['id'] as int] = Map<String, Object?>.from(r);
      }
    }

    // 2) 점수 계산 + (문서, 페이지)당 최고점만 유지
    final best = <String, SearchHit>{};
    for (final r in candidates.values) {
      final score = scoreCompact(tokens, r['compact'] as String);
      if (score <= 0) continue;
      final hit = SearchHit(
        chunkId: r['id'] as int,
        docId: r['doc_id'] as int,
        pageNo: r['page_no'] as int,
        snippet: makeSnippet(r['text'] as String, tokens),
        score: score,
        terms: tokens,
      );
      final key = '${hit.docId}:${hit.pageNo}';
      if (best[key] == null || best[key]!.score < hit.score) best[key] = hit;
    }

    final results = best.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  /// 순수 함수: 청크 하나의 점수. (tokens: 공백 제거된 소문자 토큰)
  ///
  ///  - 포함된 토큰 비율            : 0 ~ 1
  ///  - 모든 토큰이 가까울수록 가산 : 0 ~ 1
  ///  - 토큰 순서만 바꾼 연속 문자열과 일치("공학융합계열") : +2
  static double scoreCompact(List<String> tokens, String compactText) {
    final n = tokens.length;
    final spans = <List<int>>[]; // [start, end)
    for (final t in tokens) {
      final i = compactText.indexOf(t);
      if (i >= 0) spans.add([i, i + t.length]);
    }
    final matched = spans.length;
    if (matched == 0) return 0;
    if (n >= 2 && matched < 2) return 0; // 다중 토큰은 최소 2개 일치

    var score = matched / n;

    if (matched == n) {
      final minStart = spans.map((s) => s[0]).reduce(math.min);
      final maxEnd = spans.map((s) => s[1]).reduce(math.max);
      final tokenLen = tokens.fold<int>(0, (a, t) => a + t.length);
      final gap = math.max(0, (maxEnd - minStart) - tokenLen);
      score += 1 / (1 + gap / 10);

      // 순서 무관 "붙어 있음" 검사 (토큰 5개 이하만: 5! = 120)
      if (n >= 2 && n <= 5) {
        for (final perm in _permutations(tokens)) {
          if (compactText.contains(perm.join())) {
            score += 2;
            break;
          }
        }
      }
    }
    return score;
  }

  /// 원문에서 첫 매칭 위치 주변을 잘라 미리보기로 만든다.
  static String makeSnippet(
    String text,
    List<String> tokens, {
    int before = 30,
    int after = 90,
  }) {
    final lower = text.toLowerCase();
    var pos = -1;
    for (final t in tokens) {
      final i = lower.indexOf(t);
      if (i >= 0 && (pos < 0 || i < pos)) pos = i;
    }
    if (pos < 0) pos = 0; // 원문 띄어쓰기 때문에 못 찾으면 청크 앞부분
    final s = math.max(0, pos - before);
    final e = math.min(text.length, pos + after);
    return '${s > 0 ? '…' : ''}${text.substring(s, e)}${e < text.length ? '…' : ''}';
  }

  static Iterable<List<String>> _permutations(List<String> items) sync* {
    if (items.length <= 1) {
      yield List.of(items);
      return;
    }
    for (var i = 0; i < items.length; i++) {
      final rest = [...items.sublist(0, i), ...items.sublist(i + 1)];
      for (final p in _permutations(rest)) {
        yield [items[i], ...p];
      }
    }
  }
}
