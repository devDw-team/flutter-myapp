class SupabaseConfig {
  // Supabase 프로젝트 URL - MCP를 통해 자동으로 가져옴
  static const String supabaseUrl = 'https://exmbyyqmhjqsvbyyrmad.supabase.co';
  
  // Supabase 익명 키 - MCP를 통해 자동으로 가져옴
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4bWJ5eXFtaGpxc3ZieXlybWFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExNjE2NTUsImV4cCI6MjA2NjczNzY1NX0.MZq5_xONa6Er6kl5iCcIb7RTPxR_WBtk01dX8vXr9bc';
  
  // Supabase 서비스 역할 키 (서버 사이드에서만 사용)
  // static const String supabaseServiceRoleKey = 'YOUR_SERVICE_ROLE_KEY';
}

/*
사용법:
1. Supabase 대시보드에서 프로젝트를 생성합니다
2. Settings > API에서 Project URL과 anon public key를 복사합니다
3. 위의 YOUR_SUPABASE_URL과 YOUR_SUPABASE_ANON_KEY를 실제 값으로 교체합니다

예시:
static const String supabaseUrl = 'https://your-project-ref.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
*/ 