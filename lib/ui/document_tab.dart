import 'package:material_ui/material_ui.dart';

import '../library.dart';
import 'common.dart';

/// 문서 관리 탭: 등록된 PDF 목록, 색인 상태, 추가·삭제.
class DocumentTab extends StatelessWidget {
  const DocumentTab({
    super.key,
    required this.docs,
    required this.job,
    required this.onAdd,
    required this.onOpen,
    required this.onResume,
    required this.onRemove,
  });

  final List<PdfDoc> docs;
  final IndexJob? job;

  /// 색인 중이면 null(버튼 비활성).
  final VoidCallback? onAdd;
  final void Function(PdfDoc doc) onOpen;
  final void Function(PdfDoc doc) onResume;
  final void Function(PdfDoc doc) onRemove;

  @override
  Widget build(BuildContext context) {
    final busy = job != null;
    final addButton = FilledButton.icon(
      onPressed: onAdd,
      icon: const Icon(Icons.add),
      label: const Text('PDF 추가'),
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: '문서 관리',
          subtitle: '등록된 PDF 문서와 색인 상태를 확인할 수 있습니다.',
        ),
        if (job != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: IndexProgress(job: job!),
          ),
        if (docs.isEmpty)
          EmptyState(
            icon: Icons.folder_open,
            message: '등록된 문서가 없습니다.\nPDF를 추가하면 내용으로 검색할 수 있어요.',
            action: addButton,
          )
        else ...[
          Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final doc in docs)
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf_outlined),
                    title: Text(
                      doc.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      doc.isIndexed
                          ? '${doc.pageCount}쪽'
                          : '색인 미완료 (${doc.indexedPages}/${doc.pageCount}쪽) · 눌러서 이어서 색인',
                    ),
                    onTap: doc.isIndexed
                        ? () => onOpen(doc)
                        : (busy ? null : () => onResume(doc)),
                    trailing: IconButton(
                      tooltip: '삭제',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: busy ? null : () => onRemove(doc),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          addButton,
        ],
      ],
    );
  }
}
