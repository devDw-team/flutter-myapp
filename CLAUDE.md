# OneMoment+ 프로젝트 가이드

## 📱 프로젝트 개요

**OneMoment+**는 일상의 소중한 순간을 기록하는 Flutter 기반의 개인 일기 앱입니다. 사진, 텍스트, 위치 정보를 포함한 멀티미디어 일기를 작성하고 관리할 수 있습니다.

### 🎯 주요 기능
- 🔐 **사용자 인증**: 이메일 로그인, 회원가입, 게스트 모드
- 📝 **일기 작성**: 텍스트, 이미지, 위치 정보를 포함한 멀티미디어 일기
- 📅 **타임라인**: 시간순으로 정렬된 일기 조회
- 🏷️ **태그 및 카테고리**: 일기 분류 및 검색 최적화
- 😊 **기분 추적**: 일일 감정 상태 기록 및 분석
- 📊 **통계 및 분석**: 작성 패턴, 기분 변화 등 개인 인사이트
- 🔔 **알림 시스템**: 일기 작성 리마인더
- 💾 **백업 및 동기화**: 데이터 안전성 보장
- 🔒 **프라이버시**: Row Level Security로 개인정보 보호
- 📴 **오프라인 모드**: 네트워크 오류 시 graceful 처리

## 🏗️ 기술 스택

### Frontend
- **Flutter** 3.0+ (Dart)
- **Material Design** UI 컴포넌트
- **State Management**: StatefulWidget 기반

### Backend & Database
- **Supabase** (PostgreSQL + Auth + Storage + Real-time)
- **Row Level Security (RLS)** 적용
- **실시간 데이터 동기화**

### 주요 패키지
- `supabase_flutter: ^2.3.4` - 백엔드 연동
- `image_picker: ^1.0.4` - 카메라/갤러리 접근
- `google_maps_flutter: ^2.5.0` - 지도 및 위치 서비스
- `permission_handler: ^11.1.0` - 권한 관리
- `shared_preferences: ^2.2.2` - 로컬 설정 저장
- `path_provider: ^2.1.1` - 파일 시스템 접근

## 📁 프로젝트 구조

```
lib/
├── main.dart                           # 앱 진입점
├── config/
│   └── supabase_config.dart           # Supabase 설정
├── models/
│   └── moment_entry.dart              # 데이터 모델
├── services/
│   ├── moment_service.dart            # 일기 CRUD 서비스
│   └── database_migration_service.dart # DB 마이그레이션
├── screens/
│   ├── auth/
│   │   └── login_screen.dart          # 로그인/회원가입 화면 ✅
│   ├── home_screen.dart               # 홈 화면
│   ├── timeline_screen.dart           # 타임라인 화면
│   ├── info_screen.dart               # 정보 화면
│   ├── settings_screen.dart           # 설정 화면
│   └── admin/
│       └── database_admin_screen.dart # 데이터베이스 관리
├── utils/
│   ├── connectivity_helper.dart       # 네트워크 연결 확인 ✅
│   └── database_setup_helper.dart     # DB 설정 유틸리티
└── widgets/
    └── auth_wrapper.dart              # 인증 상태 관리 ✅

assets/
├── images/                            # 이미지 에셋
└── complete_database_schema.sql       # 완전한 DB 스키마

docs/
├── 데이터베이스설계.md                # 데이터베이스 설계 가이드
├── SUPABASE_SETUP.md                  # Supabase 설정 가이드
├── complete_database_schema.sql       # 전체 스키마 파일
└── test_database_schema.sql          # 스키마 테스트 파일
```

## 🗄️ 데이터베이스 설계

### ERD 개요
총 13개 테이블로 구성된 완전한 데이터베이스 스키마:

```mermaid
erDiagram
    users ||--o{ user_profiles : "has"
    users ||--o{ moment_entries : "creates"
    users ||--o{ tags : "owns"
    users ||--o{ categories : "owns"
    users ||--|| user_statistics : "has"
    
    moment_entries ||--o{ moment_media : "contains"
    moment_entries ||--o{ moment_locations : "has"
    moment_entries ||--o{ moment_tags : "tagged_with"
    moment_entries ||--o{ moment_categories : "belongs_to"
```

### 핵심 테이블
1. **moment_entries**: 일기 엔트리 (제목, 내용, 기분, 날씨 등)
2. **moment_media**: 멀티미디어 파일 (이미지, 비디오, 오디오)
3. **moment_locations**: 위치 정보 (GPS, 주소, 장소명)
4. **tags**: 사용자 정의 태그 시스템
5. **categories**: 카테고리 분류 시스템
6. **user_profiles**: 사용자 상세 정보
7. **user_statistics**: 사용자 통계 및 분석 데이터
8. **mood_tracking**: 기분 추적 로그
9. **notifications**: 알림 시스템
10. **backup_sessions**: 백업 관리
11. **sync_logs**: 동기화 로그

## 🚀 개발 환경 설정

### 1. 사전 요구사항
```bash
# Flutter 설치 확인
flutter doctor

# 프로젝트 의존성 설치
flutter pub get

# iOS 설정 (macOS에서만)
cd ios && pod install
```

### 2. Supabase 설정
1. [Supabase 대시보드](https://supabase.com) 접속
2. 새 프로젝트 생성
3. `lib/config/supabase_config.dart`에 프로젝트 URL과 API 키 설정
4. SQL Editor에서 `complete_database_schema.sql` 실행

### 3. 환경별 실행
```bash
# 개발 모드
flutter run

# 릴리즈 모드
flutter run --release

# iOS 빌드
flutter build ios

# Android 빌드
flutter build apk
```

## 🛠️ 주요 명령어

### 개발 명령어
```bash
# 프로젝트 클린
flutter clean && flutter pub get

# 의존성 업데이트
flutter pub upgrade

# 코드 분석
flutter analyze

# 테스트 실행
flutter test
```

### 데이터베이스 관리
앱 내 **설정 → 개발자 도구 → 데이터베이스 관리**에서:
- 데이터베이스 상태 확인
- 완전한 스키마 설정
- 단계별 테이블 생성
- 기존 데이터 마이그레이션

### 빌드 및 배포
```bash
# iOS 빌드 (코드사인 없이)
flutter build ios --no-codesign

# Android APK 빌드
flutter build apk --release

# 앱 번들 빌드 (Google Play)
flutter build appbundle
```

## 📱 화면별 기능

### 1. 인증 화면 (`auth/login_screen.dart`) - ✅ 완성 (2025-07-01)
- 이메일/비밀번호 로그인
- 회원가입 (자동 프로필 생성)
- 게스트 로그인 (익명 인증)
- 네트워크 연결 상태 확인
- 사용자 친화적 오류 처리

### 2. 홈 화면 (`home_screen.dart`)
- 오늘의 일기 작성
- 최근 일기 미리보기
- 빠른 기분 기록

### 3. 타임라인 화면 (`timeline_screen.dart`)
- 시간순 일기 목록
- 검색 및 필터링
- 무한 스크롤 페이징

### 4. 정보 화면 (`info_screen.dart`)
- 유용한 링크 관리
- 외부 콘텐츠 연동
- 개인 북마크

### 5. 설정 화면 (`settings_screen.dart`)
- 앱 환경 설정
- 알림 설정
- 백업/복원
- 개발자 도구 접근

### 6. 데이터베이스 관리 (`database_admin_screen.dart`)
- 스키마 생성 및 관리
- 마이그레이션 실행
- 데이터베이스 상태 모니터링

## 🔧 주요 서비스

### AuthWrapper (`widgets/auth_wrapper.dart`) - ✅ 완성 (2025-07-01)
```dart
// 인증 상태 자동 관리
// - 로그인 상태 확인
// - 인증 상태 변화 리스닝
// - 로그인/로그아웃 화면 자동 전환
// - 로딩 상태 처리
```

### LoginScreen (`screens/auth/login_screen.dart`) - ✅ 완성 (2025-07-01)
```dart
// 회원가입
await _supabase.auth.signUp(email: email, password: password);

// 로그인
await _supabase.auth.signInWithPassword(email: email, password: password);

// 게스트 로그인
await _supabase.auth.signInAnonymously();

// 자동 프로필 생성
await _createUserProfile(user);
```

### ConnectivityHelper (`utils/connectivity_helper.dart`) - ✅ 신규 (2025-07-01)
```dart
// 인터넷 연결 확인
final hasInternet = await ConnectivityHelper.checkInternetConnection();

// Supabase 서버 연결 확인
final hasSupabase = await ConnectivityHelper.checkSupabaseConnection();

// 연결 문제 다이얼로그 표시
ConnectivityHelper.showConnectionDialog(context, onRetry);
```

### MomentService (`moment_service.dart`)
```dart
// 일기 생성
await MomentService.createMoment(momentEntry);

// 일기 조회
final moments = await MomentService.getAllMoments();

// 일기 검색
final results = await MomentService.searchMoments(query);

// 일기 업데이트
await MomentService.updateMoment(id, momentEntry);

// 일기 삭제
await MomentService.deleteMoment(id);
```

### DatabaseSetupHelper (`database_setup_helper.dart`)
```dart
// 전체 스키마 설정
await DatabaseSetupHelper.setupCompleteSchema();

// 단계별 테이블 생성
await DatabaseSetupHelper.createTablesStepByStep();

// 기존 데이터 마이그레이션
await DatabaseSetupHelper.migrateExistingData();

// 데이터베이스 상태 확인
await DatabaseSetupHelper.checkDatabaseStatus();
```

## 🔒 보안 및 권한

### Row Level Security (RLS) 정책
- 모든 테이블에 RLS 활성화
- 사용자별 데이터 격리
- 개인정보 보호 강화

### 권한 관리
- 카메라/갤러리 접근 권한
- 위치 서비스 권한
- 파일 시스템 접근 권한
- 알림 권한

## 📊 성능 최적화

### 데이터베이스 최적화
- 검색용 GIN 인덱스 적용
- 복합 인덱스로 쿼리 성능 향상
- 자동 통계 업데이트 트리거

### 앱 성능
- 이미지 최적화 및 캐싱
- 페이징으로 메모리 사용량 최적화
- 비동기 데이터 로딩

## 🐛 트러블슈팅

### 일반적인 문제
1. **Supabase 연결 실패**
   - `supabase_config.dart`의 URL과 API 키 확인
   - 네트워크 연결 상태 확인
   - 방화벽 설정 확인

2. **빌드 오류**
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install  # iOS만
   ```

3. **권한 거부**
   - `permission_handler` 설정 확인
   - 플랫폼별 권한 설정 검토

### 네트워크 관련 문제
1. **인증 실패 (AuthRetryableFetchException)**
   - 인터넷 연결 확인
   - DNS 설정 확인
   - 앱은 오프라인 모드로 계속 사용 가능

2. **데이터 로드 실패**
   - 화면 상단의 "재연결" 버튼 사용
   - 타임라인에서 아래로 당겨서 새로고침

3. **오프라인 모드**
   - 네트워크 연결 시 자동으로 온라인 모드 전환
   - 오프라인 상태에서는 데이터 저장 제한

4. **macOS "Operation not permitted" 오류 (2025-07-01 해결)**
   - macOS entitlements 파일에 네트워크 클라이언트 권한 추가
   - iOS Info.plist에 App Transport Security 예외 설정
   - ConnectivityHelper를 통한 네트워크 연결 상태 사전 확인
   - 방화벽/VPN 설정 확인 필요

### 데이터베이스 문제
1. **테이블 없음 오류**
   - 앱 내 데이터베이스 관리에서 스키마 설정 실행

2. **RLS 정책 오류**
   - Supabase 대시보드에서 Authentication 설정 확인

3. **사용자 데이터 격리**
   - 익명 로그인으로 사용자별 데이터 분리
   - 다른 기기에서는 다른 데이터 표시됨

## 📈 향후 계획

### Phase 1: 기본 기능 완성
- ✅ 일기 CRUD 기능
- ✅ 멀티미디어 지원
- ✅ 데이터베이스 스키마 완성
- ✅ 사용자 인증 시스템 완성 (2025-07-01)

### Phase 2: 고급 기능
- 🔄 실시간 동기화
- 📱 푸시 알림
- 🤖 AI 기반 기분 분석

### Phase 3: 확장 기능
- 🌐 소셜 공유
- 📤 데이터 내보내기
- 🎨 테마 커스터마이징
- 🔐 생체 인증

## 🤝 기여 가이드

### 개발 플로우
1. 이슈 생성 및 논의
2. 기능 브랜치 생성
3. 개발 및 테스트
4. Pull Request 생성
5. 코드 리뷰 및 머지

### 코드 스타일
- Dart 공식 스타일 가이드 준수
- `flutter analyze` 통과 필수
- 주석 및 문서화 권장

## 📞 연락처 및 지원

- **프로젝트 관리자**: Claude Code Assistant
- **이슈 리포팅**: GitHub Issues 활용
- **문서 업데이트**: CLAUDE.md 파일 수정

---

## 📋 개발 로그

### 2025-07-01 업데이트
#### ✅ 완성된 기능:
- **사용자 인증 시스템 완전 구현**
  - 이메일/비밀번호 회원가입 및 로그인
  - 게스트 로그인 (익명 인증)
  - 자동 사용자 프로필 생성 (`user_profiles`, `user_statistics` 테이블)
  - 인증 상태 자동 관리 (`AuthWrapper`)

#### 🔧 해결된 문제:
- **macOS "Operation not permitted" 네트워크 오류**
  - macOS entitlements 파일에 `com.apple.security.network.client` 권한 추가
  - iOS Info.plist에 App Transport Security 예외 설정
  - `ConnectivityHelper` 클래스로 네트워크 연결 상태 사전 확인
  - 사용자 친화적인 오류 메시지 및 재시도 기능

#### 📝 추가된 파일:
- `lib/screens/auth/login_screen.dart` - 통합 인증 화면
- `lib/widgets/auth_wrapper.dart` - 인증 상태 관리
- `lib/utils/connectivity_helper.dart` - 네트워크 연결 확인

#### 🛠️ 수정된 설정:
- `macos/Runner/DebugProfile.entitlements` - 네트워크 클라이언트 권한
- `macos/Runner/Release.entitlements` - 네트워크 클라이언트 권한  
- `ios/Runner/Info.plist` - App Transport Security 예외

---

**마지막 업데이트**: 2025-07-01  
**버전**: 1.1.0  
**Flutter 버전**: 3.0+  
**Supabase 버전**: 2.3.4