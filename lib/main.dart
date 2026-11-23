import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import 'db.dart';
import 'library.dart';
import 'search.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // pdfrx 3.x: 위젯보다 먼저 PdfDocument API(인덱서)를 쓰므로 미리 초기화한다.
  await pdfrxFlutterInitialize();

  final appDb = await AppDb.open();
  final docsDir = await getApplicationDocumentsDirectory();
  final library = PdfLibrary(
    appDb,
    storageDir: Directory(p.join(docsDir.path, 'pdfs')),
  );

  runApp(PdfSearchApp(library: library, engine: SearchEngine(appDb)));
}

class PdfSearchApp extends StatelessWidget {
  const PdfSearchApp({super.key, required this.library, required this.engine});

  final PdfLibrary library;
  final SearchEngine engine;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF3E5E86);
    return MaterialApp(
      title: 'PDF 검색 도우미',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: HomePage(library: library, engine: engine),
    );
  }
}
