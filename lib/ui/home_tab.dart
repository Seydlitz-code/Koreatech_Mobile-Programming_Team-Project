import 'package:material_ui/material_ui.dart';

import '../library.dart';
import 'common.dart';

/// 홈 탭: 안내, 문서 등록 상태, 빠른 메뉴.
class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.docs,
    required this.job,
    required this.onAdd,
    required this.onSearch,
  });

  final List<PdfDoc> docs;
  final IndexJob? job;

  /// 색인 중이면 null(버튼 비활성).
  final VoidCallback? onAdd;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'PDF 검색 도우미',
          subtitle: '대학요람을 쉽고 빠르게 검색해 보세요.',
        ),
        Card(
          elevation: 0,
          color: scheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 34,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(height: 16),
                Text(
                  '필요한 학사 정보를 찾아보세요',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '졸업 요건, 학사 규정, 수강 정보 등을 PDF 원문에서 검색할 수 있습니다. '
                  '어순이나 띄어쓰기가 달라도 찾아 줍니다.',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('문서 등록 상태'),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: scheme.onSecondaryContainer,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: job != null
                      ? IndexProgress(job: job!)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '등록된 PDF',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _statusText(),
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('빠른 메뉴'),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.upload_file),
          label: const Text('PDF 문서 등록'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onSearch,
          icon: const Icon(Icons.search),
          label: const Text('요람 내용 검색'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  String _statusText() {
    if (docs.isEmpty) return '아직 등록된 문서가 없습니다.';
    final pending = docs.where((d) => !d.isIndexed).length;
    return pending == 0
        ? '${docs.length}개 문서 검색 가능'
        : '${docs.length}개 문서 · 색인 미완료 $pending개';
  }
}
