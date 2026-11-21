# PDF 검색 도우미

PDF를 등록하고 자연어로 검색하면 해당 페이지를 찾아주는 Android 앱
어순이나 띄어쓰기가 원문과 달라도 찾아줍니다. (`공학 융합계열` ↔ `융합 공학 계열`)

## 현재 상태

| 항목 | 상태 |
|---|---|
| DB 스키마 (`db.dart`) | 완료 |
| PDF 추출 + 청킹 + 저장 (`indexer.dart`) | 완료 |
| 검색/점수 계산 (`search.dart`) | 완료 |
| UI (문서 목록 / 검색 / 뷰어) | 미구현 |

## 파일 역할

| 파일 | 역할 |
|---|---|
| `lib/db.dart` | SQLite 테이블(`document`, `chunk`) 정의, 공백 제거 함수 `compact()` |
| `lib/indexer.dart` | PDF를 페이지별로 읽어 400자 단위로 잘라 DB에 저장. 중단 후 이어서 처리 가능 |
| `lib/search.dart` | 검색어를 토큰으로 나눠 후보 조회, 점수 계산, 미리보기 생성 |
| `pubspec.yaml` | 패키지 목록 |

## 사용하는 패키지

| 패키지 | 용도 |
|---|---|
| `pdfrx` | PDF 텍스트 추출, 뷰어 |
| `sqlite3`, `sqlite3_flutter_libs` | SQLite |
| `path_provider`, `path` | 저장 경로 처리 |
| `file_picker` | PDF 파일 선택 |
| `crypto` | 파일 해시 (중복 등록 방지) |
