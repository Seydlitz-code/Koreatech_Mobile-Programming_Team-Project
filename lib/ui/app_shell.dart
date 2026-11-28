import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../library.dart';
import '../search.dart';
import 'common.dart';
import 'document_tab.dart';
import 'home_tab.dart';
import 'search_tab.dart';
import 'viewer_page.dart';

/// 하단 탭(홈 / 검색 / 문서 관리)을 가진 첫 화면.
///
/// 문서 목록과 진행 중인 색인 작업은 여러 탭이 함께 보므로 여기서 관리한다.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.library, required this.engine});

  final PdfLibrary library;
  final SearchEngine engine;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _searchTab = 1;

  int _tab = 0;
  List<PdfDoc> _docs = const [];
  IndexJob? _job;

  @override
  void initState() {
    super.initState();
    _docs = widget.library.documents();
  }

  void _reloadDocs() => setState(() => _docs = widget.library.documents());

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
    final job = IndexJob(title);
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
    final onAdd = _job == null ? _addPdf : null;
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            HomeTab(
              docs: _docs,
              job: _job,
              onAdd: onAdd,
              onSearch: () => setState(() => _tab = _searchTab),
            ),
            SearchTab(
              docs: _docs,
              engine: widget.engine,
              onOpen: (doc, page, terms) =>
                  _open(doc, page: page, terms: terms),
            ),
            DocumentTab(
              docs: _docs,
              job: _job,
              onAdd: onAdd,
              onOpen: _open,
              onResume: _resume,
              onRemove: _confirmRemove,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: '검색'),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: '문서 관리',
          ),
        ],
      ),
    );
  }
}
