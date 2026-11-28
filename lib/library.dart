import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'db.dart';
import 'indexer.dart';

/// 등록된 PDF 한 건.
class PdfDoc {
  const PdfDoc({
    required this.id,
    required this.title,
    required this.filePath,
    required this.pageCount,
    required this.indexedPages,
  });

  final int id;
  final String title;
  final String filePath;
  final int pageCount;
  final int indexedPages;

  /// 모든 페이지 색인이 끝났는지. (page_count가 0이면 아직 열어 보지도 못한 것)
  bool get isIndexed => pageCount > 0 && indexedPages >= pageCount;
}

/// 문서 목록 조회, 가져오기(복사 + 색인), 삭제를 묶은 서비스.
///
/// 파일 선택기가 돌려준 파일은 임시 위치일 수 있으므로
/// 앱 전용 폴더([storageDir])로 복사한 뒤 색인한다.
class PdfLibrary {
  PdfLibrary(this._appDb, {required this.storageDir})
    : _indexer = PdfIndexer(_appDb);

  final AppDb _appDb;
  final PdfIndexer _indexer;

  /// 가져온 PDF를 보관하는 폴더.
  final Directory storageDir;

  List<PdfDoc> documents() {
    final rows = _appDb.db.select(
      'SELECT id, title, file_path, page_count, indexed_pages '
      'FROM document ORDER BY id DESC',
    );
    return [
      for (final r in rows)
        PdfDoc(
          id: r['id'] as int,
          title: r['title'] as String,
          filePath: r['file_path'] as String,
          pageCount: r['page_count'] as int,
          indexedPages: r['indexed_pages'] as int,
        ),
    ];
  }

  /// [bytes]를 [fileName]으로 보관 폴더에 저장하고 색인한다.
  /// 같은 내용의 파일이 이미 있으면 새로 저장하지 않고 기존 문서를 이어서 색인한다.
  Future<int> importPdf(
    String fileName,
    Stream<List<int>> bytes, {
    ProgressCallback? onProgress,
  }) async {
    // 같은 이름의 파일끼리 덮어쓰지 않도록 가져올 때마다 하위 폴더를 만든다.
    final dir = Directory(
      p.join(storageDir.path, DateTime.now().microsecondsSinceEpoch.toString()),
    );
    await dir.create(recursive: true);
    final copy = File(p.join(dir.path, p.basename(fileName)));
    await bytes.pipe(copy.openWrite());

    final hash = (await sha1.bind(copy.openRead()).first).toString();
    final existing = _appDb.db.select(
      'SELECT file_path FROM document WHERE file_hash = ?',
      [hash],
    );
    var path = copy.path;
    if (existing.isNotEmpty) {
      final oldPath = existing.first['file_path'] as String;
      if (oldPath != copy.path && await File(oldPath).exists()) {
        // 이미 보관 중인 사본이 있으니 방금 만든 사본은 버린다.
        await dir.delete(recursive: true);
        path = oldPath;
      }
    }

    try {
      return await _indexer.register(path, onProgress: onProgress);
    } catch (_) {
      // 열 수 없는 PDF였다면 반쯤 만들어진 문서를 남기지 않는다.
      final failed = _appDb.db.select(
        'SELECT id, indexed_pages FROM document WHERE file_hash = ?',
        [hash],
      );
      if (failed.isNotEmpty && failed.first['indexed_pages'] == 0) {
        _indexer.remove(failed.first['id'] as int);
        await _deleteStoredFile(path);
      }
      rethrow;
    }
  }

  /// 중단된 색인을 이어서 진행한다.
  Future<void> resume(PdfDoc doc, {ProgressCallback? onProgress}) =>
      _indexer.register(doc.filePath, onProgress: onProgress);

  /// 문서와 그 청크, 보관 중인 파일을 지운다.
  Future<void> remove(PdfDoc doc) async {
    _indexer.remove(doc.id);
    await _deleteStoredFile(doc.filePath);
  }

  /// 보관 폴더 안에 있는 파일만 지운다(사용자 원본은 건드리지 않는다).
  Future<void> _deleteStoredFile(String path) async {
    if (!p.isWithin(storageDir.path, path)) return;
    final parent = Directory(p.dirname(path));
    if (await parent.exists()) await parent.delete(recursive: true);
  }
}
