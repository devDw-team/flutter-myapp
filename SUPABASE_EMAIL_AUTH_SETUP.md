# Supabase 이메일 인증 설정 가이드

## 🔧 이메일 인증 활성화

OneMoment+ 앱에서 이메일 로그인/회원가입을 사용하려면 Supabase에서 이메일 인증을 활성화해야 합니다.

### 1. Supabase 대시보드 설정

1. **Supabase 대시보드** 접속: https://supabase.com/dashboard
2. **OneMoment+ 프로젝트** (`exmbyyqmhjqsvbyyrmad`) 선택
3. 좌측 메뉴에서 **Authentication** 클릭
4. **Settings** 탭 선택

### 2. 기본 인증 설정

#### Enable email confirmations
- **비활성화 권장** (개발 단계에서)
- 활성화 시 사용자가 이메일 인증을 완료해야 로그인 가능

#### Enable email confirmations for new users
- **비활성화 권장** (즉시 로그인 허용)
- 활성화 시 회원가입 후 이메일 인증 필요

#### Enable phone confirmations
- **비활성화** (현재 앱에서 사용하지 않음)

### 3. 익명 로그인 설정

```
Enable anonymous sign-ins: ✅ 활성화
```

이를 통해 "게스트로 시작하기" 기능이 정상 작동합니다.

### 4. 비밀번호 정책

```
Minimum password length: 6 (기본값)
```

### 5. 테스트용 사용자 생성

개발 중 테스트를 위해 수동으로 사용자를 생성할 수 있습니다:

1. **Authentication** > **Users** 탭
2. **Add user** 버튼 클릭
3. 이메일과 비밀번호 입력
4. **Email confirm** 체크 (인증 없이 생성)

## 📱 앱에서 지원되는 인증 방법

### 1. 이메일 로그인
```dart
await supabase.auth.signInWithPassword(
  email: 'user@example.com',
  password: 'password123',
);
```

### 2. 이메일 회원가입
```dart
await supabase.auth.signUp(
  email: 'user@example.com',
  password: 'password123',
);
```

### 3. 익명 로그인 (게스트)
```dart
await supabase.auth.signInAnonymously();
```

### 4. 로그아웃
```dart
await supabase.auth.signOut();
```

## 🔒 보안 고려사항

### 개발 환경
- 이메일 인증 비활성화로 빠른 테스트 가능
- 익명 로그인 활성화로 즉시 앱 체험 가능

### 프로덕션 환경
- 이메일 인증 활성화 권장
- Row Level Security (RLS) 정책 적용
- HTTPS만 허용

## 🚀 앱 동작 흐름

### 1. 앱 시작
```
앱 실행 → 인증 상태 확인 → 로그인 화면 or 메인 화면
```

### 2. 로그인 성공
```
로그인 → Supabase 세션 생성 → 메인 화면 이동
```

### 3. 로그아웃
```
로그아웃 → 세션 삭제 → 로그인 화면 이동
```

## 🐛 문제 해결

### "Invalid login credentials"
- 이메일 또는 비밀번호 오류
- Supabase Users 탭에서 사용자 존재 확인

### "Email not confirmed"
- 이메일 인증이 활성화되어 있는 경우
- Users 탭에서 수동으로 "Email confirmed" 체크

### "User already registered"
- 이미 가입된 이메일
- 로그인 모드로 전환하여 시도

### "Anonymous sign-ins are disabled"
- Authentication > Settings에서 익명 로그인 활성화
- 게스트 기능 사용 불가

## 📧 이메일 설정 (선택사항)

프로덕션에서 이메일 전송을 위해:

1. **Authentication** > **Settings** > **SMTP Settings**
2. 이메일 서비스 제공업체 설정 (Gmail, SendGrid 등)
3. 커스텀 이메일 템플릿 설정

---

**설정 완료 후 앱을 재실행하면 완전한 로그인 시스템이 작동합니다!** 🎉

### 추천 개발 설정
```
✅ Enable anonymous sign-ins
❌ Enable email confirmations  
❌ Enable phone confirmations
✅ Allow new users to sign up
```