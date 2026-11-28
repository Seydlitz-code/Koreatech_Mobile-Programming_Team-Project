import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../library.dart';
import '../search.dart';
import 'common.dart';
import 'highlighted_text.dart';

/// 검색 탭: 검색어를 입력하면 일치하는 페이지를 점수 순으로 보여 준다.
class SearchTab extends StatefulWidget {
  const SearchTab({
    super.key,
    required this.docs,
    required this.engine,
    required this.onOpen,
  });

  final List<PdfDoc> docs;
  final SearchEngine engine;
  final void Function(PdfDoc doc, int page, List<String> terms) onOpen;

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<SearchHit> _hits = const [];

  @override
  void didUpdateWidget(SearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 문서가 추가·삭제·색인되면 결과도 다시 계산한다.
    if (!identical(oldWidget.docs, widget.docs)) _hits = _search();
  }

  List<SearchHit> _search() {
    final q = _query.text.trim();
    return q.isEmpty ? const [] : widget.engine.search(q);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _runSearch);
    setState(() {}); // 지우기 버튼 표시 갱신
  }

  void _runSearch() {
    _debounce?.cancel();
    setState(() => _hits = _search());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(title: '내용 검색', subtitle: '찾고 싶은 학사 정보를 입력하세요.'),
        TextField(
          controller: _query,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: '예: 졸업 이수 학점, 수강 신청',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.text.isEmpty
                ? null
                : IconButton(
                    tooltip: '지우기',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _query.clear();
                      _runSearch();
                    },
                  ),
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: _onQueryChanged,
          onSubmitted: (_) => _runSearch(),
        ),
        const SizedBox(height: 24),
        ..._buildResults(),
      ],
    );
  }

  List<Widget> _buildResults() {
    final q = _query.text.trim();
    if (widget.docs.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.search_off,
          message: '먼저 PDF를 등록해 주세요.\n[문서 관리] 탭에서 추가할 수 있습니다.',
        ),
      ];
    }
    if (q.isEmpty) return const [];
    if (_hits.isEmpty) {
      return [
        EmptyState(icon: Icons.search_off, message: "'$q'와(과) 일치하는 페이지가 없어요."),
      ];
    }
    final byId = {for (final d in widget.docs) d.id: d};
    return [
      SectionTitle('검색 결과 ${_hits.length}건'),
      for (final hit in _hits)
        if (byId[hit.docId] case final doc?)
          SearchResultCard(
            title: doc.title,
            page: '${hit.pageNo}쪽',
            snippet: hit.snippet,
            ranges: SearchEngine.matchRanges(hit.snippet, hit.terms),
            onTap: () => widget.onOpen(doc, hit.pageNo, hit.terms),
          ),
    ];
  }
}

/// 검색 결과 카드.
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.title,
    required this.page,
    required this.snippet,
    required this.ranges,
    required this.onTap,
  });

  final String title;
  final String page;
  final String snippet;
  final List<(int, int)> ranges;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    page,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              HighlightedText(text: snippet, ranges: ranges, maxLines: 3),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '원문 보기  ›',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
