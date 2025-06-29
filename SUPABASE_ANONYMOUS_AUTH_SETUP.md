# Supabase 익명 인증 설정 가이드

## 🔍 문제 상황

OneMoment+ 앱 실행 시 다음과 같은 오류가 발생합니다:

```
"Anonymous sign-ins are disabled"
```

이는 Supabase 프로젝트에서 익명 로그인이 비활성화되어 있기 때문입니다.

## ✅ 해결 방법

### 1. Supabase 대시보드 접속

1. [Supabase 대시보드](https://supabase.com/dashboard)에 로그인
2. OneMoment+ 프로젝트 (`exmbyyqmhjqsvbyyrmad`) 선택

### 2. 익명 인증 활성화

1. 좌측 메뉴에서 **Authentication** 클릭
2. **Settings** 탭 선택
3. **Enable anonymous sign-ins** 옵션을 **활성화**
4. **Save** 버튼 클릭

### 3. 설정 확인

다음 curl 명령어로 익명 로그인이 활성화되었는지 확인:

```bash
curl -X POST \
  'https://exmbyyqmhjqsvbyyrmad.supabase.co/auth/v1/signup' \
  -H 'Content-Type: application/json' \
  -H 'apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4bWJ5eXFtaGpxc3ZieXlybWFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExNjE2NTUsImV4cCI6MjA2NjczNzY1NX0.MZq5_xONa6Er6kl5iCcIb7RTPxR_WBtk01dX8vXr9bc' \
  -d '{}'
```

**성공 시**: 사용자 정보가 포함된 JSON 응답
**실패 시**: `"anonymous_provider_disabled"` 오류

## 🛡️ 보안 고려사항

### 익명 인증의 장점
- 사용자가 회원가입 없이 바로 앱 사용 가능
- 개인정보 수집 최소화
- 빠른 온보딩 경험

### 익명 인증의 주의사항
- 기기 변경 시 데이터 손실 가능
- 장기적인 사용자 관리 어려움
- 필요시 나중에 이메일/소셜 로그인으로 전환 가능

## 🔄 대안 방법

익명 로그인을 활성화하지 않으려면 다음 인증 방법을 사용할 수 있습니다:

### 1. 이메일 인증
```dart
await supabase.auth.signInWithPassword(
  email: 'user@example.com',
  password: 'password123',
);
```

### 2. 소셜 로그인 (Google, Apple 등)
```dart
await supabase.auth.signInWithOAuth(Provider.google);
```

### 3. 매직 링크
```dart
await supabase.auth.signInWithOtp(email: 'user@example.com');
```

## 📱 앱 동작

### 익명 로그인 활성화 후
- ✅ 정상적인 데이터 저장/조회
- ✅ 모든 기능 사용 가능
- ✅ 사용자별 데이터 격리

### 익명 로그인 비활성화 시
- ⚠️ 게스트 모드로 실행
- ❌ 데이터 저장 기능 제한
- ✅ UI 탐색은 가능

## 🚀 권장 설정

OneMoment+ 같은 개인 일기 앱의 경우 **익명 로그인 활성화**를 권장합니다:

1. **사용자 경험**: 즉시 앱 사용 가능
2. **프라이버시**: 개인정보 수집 최소화
3. **전환 가능**: 나중에 계정 연결 옵션 제공

## 📞 문제 해결

설정 후에도 문제가 지속되면:

1. **캐시 삭제**: `flutter clean && flutter pub get`
2. **앱 재시작**: 완전히 종료 후 재실행
3. **브라우저 캐시**: Supabase 대시보드 새로고침

---

**설정 완료 후 앱을 다시 실행하면 정상적으로 작동합니다!** 🎉