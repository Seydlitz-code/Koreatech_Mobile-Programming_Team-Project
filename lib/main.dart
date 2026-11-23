
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await pdfrxFlutterInitialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '대학요람 검색 도우미',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF426B9C),
          surface: const Color(0xFFF7F8FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F8FA),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    SearchPage(),
    DocumentPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: pages[selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: '검색',
          ),
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

// 홈 화면
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),

        const Text(
          'PDF 검색 도우미',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          '대학요람을 쉽고 빠르게 검색해 보세요.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 28),

        // 검색 안내 카드
        Card(
          elevation: 0,
          color: const Color(0xFFEAF1F9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 34,
                  color: Color(0xFF426B9C),
                ),
                const SizedBox(height: 16),
                const Text(
                  '필요한 학사 정보를 찾아보세요',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '졸업 요건, 학사 규정, 수강 정보 등을 '
                      'PDF 원문에서 검색할 수 있습니다.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          '문서 등록 상태',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xFF426B9C),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '대학요람 PDF',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '아직 등록된 문서가 없습니다.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.info_outline,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          '빠른 메뉴',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF 등록 기능은 추후 연결됩니다.')),
            );
          },
          icon: const Icon(Icons.upload_file),
          label: const Text('PDF 문서 등록'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('하단 검색 메뉴를 이용해 주세요.')),
            );
          },
          icon: const Icon(Icons.search),
          label: const Text('요람 내용 검색'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

// 검색 화면
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),

        const Text(
          '내용 검색',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          '찾고 싶은 학사 정보를 입력하세요.',
          style: TextStyle(color: Colors.grey.shade600),
        ),

        const SizedBox(height: 24),

        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: '예: 졸업 이수 학점, 수강 신청',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close),
              onPressed: searchController.clear,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('실제 검색 기능은 추후 연결됩니다.')),
            );
          },
        ),

        const SizedBox(height: 24),

        const Text(
          '검색 결과 예시',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        SearchResultCard(
          title: '졸업 이수 학점',
          page: '42페이지',
          description: '졸업을 위해 필요한 전공 및 교양 이수 학점에 관한 내용입니다.',
        ),

        SearchResultCard(
          title: '수강 신청 안내',
          page: '18페이지',
          description: '수강 신청 기간 및 신청 방법에 관한 안내입니다.',
        ),

        SearchResultCard(
          title: '학사 경고 및 제적',
          page: '67페이지',
          description: '학사 경고 기준과 제적 관련 규정에 관한 내용입니다.',
        ),
      ],
    );
  }
}

// 검색 결과 카드
class SearchResultCard extends StatelessWidget {
  final String title;
  final String page;
  final String description;

  const SearchResultCard({
    super.key,
    required this.title,
    required this.page,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  page,
                  style: const TextStyle(
                    color: Color(0xFF426B9C),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                '원문 보기  ›',
                style: TextStyle(
                  color: Color(0xFF426B9C),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 문서 관리 화면
class DocumentPage extends StatelessWidget {
  const DocumentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),

        const Text(
          '문서 관리',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          '등록된 PDF 문서와 색인 상태를 확인할 수 있습니다.',
          style: TextStyle(
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 24),

        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 36,
              horizontal: 20,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.folder_open,
                  size: 56,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  '등록된 문서가 없습니다.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'PDF 파일을 등록하면 이곳에서 확인할 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PDF 등록 기능은 추후 연결됩니다.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('PDF 등록'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
