import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';

import '../library.dart';
import '../search.dart';

/// PDF를 [initialPage]부터 보여 주고, [terms]가 있으면 페이지 위에 강조한다.
class ViewerPage extends StatefulWidget {
  const ViewerPage({
    super.key,
    required this.doc,
    this.initialPage = 1,
    this.terms = const [],
  });

  final PdfDoc doc;
  final int initialPage;

  /// 공백 제거된 소문자 검색 토큰.
  final List<String> terms;

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  final _controller = PdfViewerController();
  late final _searcher = PdfTextSearcher(_controller)..addListener(_onSearch);
  late int _page = widget.initialPage;

  @override
  void dispose() {
    _searcher
      ..removeListener(_onSearch)
      ..dispose();
    super.dispose();
  }

  void _onSearch() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.doc.pageCount;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.doc.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(total > 0 ? '$_page / $total쪽' : '$_page쪽'),
            ),
          ),
        ],
      ),
      body: PdfViewer.file(
        widget.doc.filePath,
        controller: _controller,
        initialPageNumber: widget.initialPage,
        params: PdfViewerParams(
          onViewerReady: (document, controller) {
            final pattern = SearchEngine.spacingTolerantPattern(widget.terms);
            if (pattern != null) {
              _searcher.startTextSearch(
                pattern,
                goToFirstMatch: false,
                searchImmediately: true,
                startPageNumber: widget.initialPage,
              );
            }
          },
          onPageChanged: (page) {
            if (page != null && mounted) setState(() => _page = page);
          },
          pagePaintCallbacks: [_searcher.pageTextMatchPaintCallback],
          errorBannerBuilder: (context, error, stackTrace, documentRef) =>
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'PDF를 열 수 없습니다.\n파일이 옮겨졌거나 지워졌을 수 있어요.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
