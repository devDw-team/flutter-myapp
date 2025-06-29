# OneMoment+ Supabase 설정 가이드

이 가이드는 OneMoment+ Flutter 앱을 Supabase와 연결하는 방법을 설명합니다.

## 1. Supabase 프로젝트 생성

1. [Supabase 웹사이트](https://supabase.com)에 접속
2. 계정 생성 또는 로그인
3. "New project" 버튼 클릭
4. 프로젝트 이름, 데이터베이스 비밀번호, 리전 설정
5. 프로젝트 생성 완료 대기

## 2. 데이터베이스 스키마 설정

1. Supabase 대시보드에서 좌측 메뉴의 "SQL Editor" 클릭
2. 프로젝트 루트의 `supabase_schema.sql` 파일 내용을 복사
3. SQL Editor에 붙여넣기 후 "RUN" 버튼 클릭
4. 테이블과 정책이 성공적으로 생성되었는지 확인

## 3. 스토리지 버킷 생성 (이미지 업로드용)

1. 좌측 메뉴에서 "Storage" 클릭
2. "Create a new bucket" 버튼 클릭
3. 버킷 이름: `moment-images`
4. Public bucket 체크박스 활성화
5. "Create bucket" 버튼 클릭

## 4. API 키 설정

1. 좌측 메뉴에서 "Settings" > "API" 클릭
2. 다음 정보를 복사:
   - **Project URL**: `https://your-project-ref.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

3. `lib/config/supabase_config.dart` 파일에서 다음 값들을 실제 값으로 교체:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project-ref.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
}
```

## 5. 앱에서 Supabase 사용하기

### 5.1 기본 사용법

```dart
import 'package:onemoment_plus/services/moment_service.dart';
import 'package:onemoment_plus/models/moment_entry.dart';

class ExampleUsage {
  final MomentService _momentService = MomentService();

  // 일기 목록 불러오기
  Future<void> loadMoments() async {
    try {
      final moments = await _momentService.getAllMoments();
      // UI 업데이트 로직
    } catch (e) {
      print('오류: $e');
    }
  }

  // 새 일기 작성
  Future<void> createNewMoment() async {
    try {
      final newMoment = MomentEntry(
        title: '오늘의 순간',
        content: '아름다운 하루였다.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _momentService.createMoment(newMoment);
    } catch (e) {
      print('저장 실패: $e');
    }
  }
}
```

### 5.2 실시간 업데이트 (선택사항)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void setupRealtimeListener() {
  supabase
    .from('moment_entries')
    .stream(primaryKey: ['id'])
    .listen((List<Map<String, dynamic>> data) {
      // 실시간 데이터 변경 감지
      print('데이터가 업데이트되었습니다: $data');
    });
}
```

## 6. 보안 설정 (배포 전 필수)

현재 개발용으로 모든 사용자가 데이터에 접근할 수 있도록 설정되어 있습니다.
실제 배포 시에는 다음 단계를 따라 보안을 강화하세요:

### 6.1 사용자 인증 추가

```dart
// 이메일 회원가입
await supabase.auth.signUp(
  email: 'user@example.com',
  password: 'password123',
);

// 로그인
await supabase.auth.signInWithPassword(
  email: 'user@example.com',
  password: 'password123',
);
```

### 6.2 Row Level Security 정책 업데이트

Supabase SQL Editor에서 다음 명령어를 실행:

```sql
-- 기존 개발용 정책 삭제
DROP POLICY "Enable all access for moment_entries" ON moment_entries;

-- 사용자별 데이터 접근 정책 생성
CREATE POLICY "Users can view their own moments" ON moment_entries
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert their own moments" ON moment_entries
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own moments" ON moment_entries
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete their own moments" ON moment_entries
    FOR DELETE USING (auth.uid()::text = user_id);
```

## 7. 문제 해결

### 연결 오류
- API URL과 키가 정확한지 확인
- 인터넷 연결 상태 확인
- Supabase 프로젝트가 활성화되어 있는지 확인

### 데이터 접근 오류
- Row Level Security 정책 확인
- 사용자 인증 상태 확인

### 이미지 업로드 오류
- 스토리지 버킷이 생성되어 있는지 확인
- 버킷이 public으로 설정되어 있는지 확인

## 8. 추가 기능

### 8.1 오프라인 지원
- `shared_preferences` 패키지를 사용한 로컬 캐싱
- 네트워크 연결 상태 체크

### 8.2 이미지 최적화
- 이미지 압축 및 리사이징
- 썸네일 생성

## 참고 자료

- [Supabase Flutter 공식 문서](https://supabase.com/docs/reference/dart)
- [Supabase Auth 가이드](https://supabase.com/docs/guides/auth)
- [Supabase Storage 가이드](https://supabase.com/docs/guides/storage) 