# PDF 검색 도우미

PDF를 등록하고 자연어로 검색하면 해당 페이지를 찾아주는 Android 앱
어순이나 띄어쓰기가 원문과 달라도 찾아줍니다. (`공학 융합계열` ↔ `융합 공학 계열`)

## 현재 상태

| 항목 | 상태 |
|---|---|
| DB 스키마 (`db.dart`) | 완료 |
| PDF 추출 + 청킹 + 저장 (`indexer.dart`) | 완료 |
| 검색/점수 계산 (`search.dart`) | 완료 |
| UI (홈 / 검색 / 문서 관리 탭, 뷰어) | 완료 (2차) |

## 파일 역할

| 파일 | 역할 |
|---|---|
| `lib/db.dart` | SQLite 테이블(`document`, `chunk`) 정의, 공백 제거 함수 `compact()` |
| `lib/indexer.dart` | PDF를 페이지별로 읽어 400자 단위로 잘라 DB에 저장. 중단 후 이어서 처리 가능 |
| `lib/search.dart` | 검색어를 토큰으로 나눠 후보 조회, 점수 계산, 미리보기 생성 |
| `lib/library.dart` | PDF 가져오기(앱 폴더로 복사 + 색인), 문서 목록, 삭제 |
| `lib/main.dart` | 초기화(pdfrx, DB) 후 앱 실행 |
| `lib/ui/app_shell.dart` | 첫 화면: 하단 탭(홈/검색/문서 관리), 문서 목록·색인 작업 상태, PDF 추가·삭제 |
| `lib/ui/home_tab.dart` | 홈 탭: 안내, 문서 등록 상태, 빠른 메뉴 |
| `lib/ui/search_tab.dart` | 검색 탭: 검색창, 검색 결과 카드 |
| `lib/ui/document_tab.dart` | 문서 관리 탭: 문서 목록, 이어서 색인, 삭제 |
| `lib/ui/common.dart` | 탭들이 같이 쓰는 위젯(제목, 진행률, 빈 화면) |
| `lib/ui/viewer_page.dart` | PDF 뷰어: 검색 결과의 쪽으로 이동, 검색어 강조 |
| `lib/ui/highlighted_text.dart` | 미리보기에서 일치 부분 강조 |
| `pubspec.yaml` | 패키지 목록 |

## 사용하는 패키지

| 패키지 | 용도 |
|---|---|
| `pdfrx` | PDF 텍스트 추출, 뷰어 |
| `sqlite3`, `sqlite3_flutter_libs` | SQLite |
| `path_provider`, `path` | 저장 경로 처리 |
| `file_picker` | PDF 파일 선택 |
| `crypto` | 파일 해시 (중복 등록 방지) |

## 개발 규칙

- Flutter 버전은 **3.50.1**로 고정합니다(`pubspec.yaml`의 `environment.flutter`, CI도 이 값을 씁니다). 버전이 다르면 `flutter upgrade`로 맞추세요.
- `main`에는 직접 푸시할 수 없습니다. 브랜치를 만들어 PR을 올리고, CI가 통과하면 머지합니다(리뷰 승인은 필수가 아니지만 가능하면 서로 확인해 주세요).
- PR마다 GitHub Actions CI(`.github/workflows/ci.yml`)가 돌고, `Analyze & Test`(포맷·analyze·테스트)와 `Build Android`(디버그 APK 빌드)가 모두 통과해야 머지할 수 있습니다.
- 푸시 전에 로컬에서 CI와 같은 검사를 돌려 보세요.

```
flutter pub get
dart format lib test
flutter analyze
flutter test
```
