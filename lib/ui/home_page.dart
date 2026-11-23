import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../library.dart';
import '../search.dart';
import 'highlighted_text.dart';
import 'viewer_page.dart';

/// 첫 화면. 검색창 + (검색어가 없으면) 문서 목록 / (있으면) 검색 결과.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.library, required this.engine});

  final PdfLibrary library;
  final SearchEngine engine;

  @override
  State<HomePage> createState() => _HomePageState();
}

/// 진행 중인 색인 작업 표시용.
class _IndexJob {
  _IndexJob(this.title);
  final String title;
  int done = 0;
  int total = 0;
}

class _HomePageState extends State<HomePage> {
  final _query = TextEditingController();
  Timer? _debounce;

  List<PdfDoc> _docs = const [];
  List<SearchHit> _hits = const [];
  _IndexJob? _job;

  @override
  void initState() {
    super.initState();
    _reloadDocs();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _reloadDocs() {
    setState(() => _docs = widget.library.documents());
    _runSearch();
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _runSearch);
    setState(() {}); // 지우기 버튼 표시 갱신
  }

  void _runSearch() {
    final q = _query.text.trim();
    setState(() => _hits = q.isEmpty ? const [] : widget.engine.search(q));
  }

  Future<void> _addPdf() async {
    final PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
    } catch (e) {
      _showMessage('파일을 열 수 없습니다: $e');
      return;
    }
    if (picked == null) return;
    final file = picked;

    await _runIndexJob(
      file.name,
      (onProgress) => widget.library.importPdf(
        file.name,
        file.readAsByteStream(),
        onProgress: onProgress,
      ),
    );
  }

  Future<void> _resume(PdfDoc doc) => _runIndexJob(doc.title, (onProgress) {
    return widget.library.resume(doc, onProgress: onProgress);
  });

  Future<void> _runIndexJob(
    String title,
    Future<void> Function(void Function(int, int) onProgress) work,
  ) async {
    final job = _IndexJob(title);
    setState(() => _job = job);
    var listed = false;
    try {
      await work((done, total) {
        if (!mounted) return;
        setState(() {
          job
            ..done = done
            ..total = total;
          // 문서 행은 첫 페이지 처리 전에 만들어지므로 한 번만 목록을 새로 고친다.
          if (!listed) {
            listed = true;
            _docs = widget.library.documents();
          }
        });
      });
      _showMessage("'$title' 색인을 마쳤습니다.");
    } catch (e) {
      _showMessage("'$title'을(를) 색인하지 못했습니다. PDF 파일이 맞는지 확인해 주세요.");
    } finally {
      if (mounted) {
        setState(() => _job = null);
        _reloadDocs();
      }
    }
  }

  Future<void> _confirmRemove(PdfDoc doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문서 삭제'),
        content: Text("'${doc.title}'와(과) 색인 데이터를 삭제할까요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.library.remove(doc);
    if (mounted) _reloadDocs();
  }

  void _open(PdfDoc doc, {int page = 1, List<String> terms = const []}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ViewerPage(doc: doc, initialPage: page, terms: terms),
      ),
    );
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('PDF 검색 도우미')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchBar(
              controller: _query,
              hintText: '내용으로 검색 (어순·띄어쓰기 무관)',
              leading: const Icon(Icons.search),
              trailing: [
                if (searching)
                  IconButton(
                    tooltip: '지우기',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _query.clear();
                      _onQueryChanged('');
                    },
                  ),
              ],
              onChanged: _onQueryChanged,
              onSubmitted: (_) => _runSearch(),
            ),
          ),
          if (_job != null) _IndexProgress(job: _job!),
          Expanded(child: searching ? _buildResults() : _buildDocs()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _job == null ? _addPdf : null,
        icon: const Icon(Icons.add),
        label: const Text('PDF 추가'),
      ),
    );
  }

  Widget _buildDocs() {
    if (_docs.isEmpty) {
      return const _EmptyState(
        icon: Icons.picture_as_pdf_outlined,
        message: 'PDF를 추가하면 내용으로 검색할 수 있어요.\n오른쪽 아래 [PDF 추가]를 눌러 보세요.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: _docs.length,
      itemBuilder: (context, i) {
        final doc = _docs[i];
        final busy = _job != null;
        return ListTile(
          leading: const Icon(Icons.picture_as_pdf_outlined),
          title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            doc.isIndexed
                ? '${doc.pageCount}쪽'
                : '색인 미완료 (${doc.indexedPages}/${doc.pageCount}쪽) · 눌러서 이어서 색인',
          ),
          onTap: doc.isIndexed
              ? () => _open(doc)
              : (busy ? null : () => _resume(doc)),
          trailing: IconButton(
            tooltip: '삭제',
            icon: const Icon(Icons.delete_outline),
            onPressed: busy ? null : () => _confirmRemove(doc),
          ),
        );
      },
    );
  }

  Widget _buildResults() {
    if (_docs.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off,
        message: '먼저 PDF를 추가해 주세요.',
      );
    }
    if (_hits.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off,
        message: "'${_query.text.trim()}'와(과) 일치하는 페이지가 없어요.",
      );
    }
    final byId = {for (final d in _docs) d.id: d};
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: _hits.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final hit = _hits[i];
        final doc = byId[hit.docId];
        if (doc == null) return const SizedBox.shrink();
        return ListTile(
          title: Text(
            '${doc.title} · ${hit.pageNo}쪽',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: HighlightedText(
            text: hit.snippet,
            ranges: SearchEngine.matchRanges(hit.snippet, hit.terms),
            maxLines: 3,
          ),
          onTap: () => _open(doc, page: hit.pageNo, terms: hit.terms),
        );
      },
    );
  }
}

class _IndexProgress extends StatelessWidget {
  const _IndexProgress({required this.job});

  final _IndexJob job;

  @override
  Widget build(BuildContext context) {
    final value = job.total == 0 ? null : job.done / job.total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.total == 0
                ? "'${job.title}' 준비 중…"
                : "'${job.title}' 색인 중 (${job.done}/${job.total}쪽)",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: value),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
