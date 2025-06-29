import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class DebugHelper {
  /// Supabase 연결 정보 출력
  static void printSupabaseInfo() {
    print('=== Supabase 연결 정보 ===');
    print('URL: ${SupabaseConfig.supabaseUrl}');
    print('Anon Key: ${SupabaseConfig.supabaseAnonKey.substring(0, 20)}...');
    
    final supabase = Supabase.instance.client;
    print('Client initialized: ${supabase.toString()}');
    print('Current user: ${supabase.auth.currentUser?.id ?? "null"}');
    print('Current session: ${supabase.auth.currentSession?.accessToken?.substring(0, 20) ?? "null"}');
    print('========================');
  }

  /// 네트워크 연결 테스트
  static Future<void> testSupabaseConnection() async {
    print('=== Supabase 연결 테스트 시작 ===');
    
    try {
      final supabase = Supabase.instance.client;
      
      print('1. 현재 세션 확인...');
      final session = supabase.auth.currentSession;
      print('   세션 상태: ${session != null ? "활성" : "없음"}');
      
      if (session == null) {
        print('2. 익명 로그인 시도...');
        final response = await supabase.auth.signInAnonymously();
        print('   로그인 결과: ${response.user?.id ?? "실패"}');
      }
      
      print('3. 데이터베이스 연결 테스트...');
      final testResponse = await supabase
          .from('moment_entries')
          .select('id')
          .limit(1);
      print('   쿼리 결과: ${testResponse.length}개 항목');
      
      print('✅ 모든 연결 테스트 성공');
      
    } catch (e) {
      print('❌ 연결 테스트 실패: $e');
      print('오류 타입: ${e.runtimeType}');
      if (e.toString().contains('SocketException')) {
        print('→ 네트워크 연결 문제');
      } else if (e.toString().contains('AuthException')) {
        print('→ 인증 문제');
      } else {
        print('→ 기타 오류');
      }
    }
    
    print('=== 연결 테스트 완료 ===');
  }

  /// 앱 상태 정보 출력
  static void printAppStatus() {
    print('=== 앱 상태 정보 ===');
    print('Flutter 버전: 확인 필요');
    print('플랫폼: 확인 필요');
    print('디버그 모드: ${bool.fromEnvironment('dart.vm.product') ? "Release" : "Debug"}');
    print('==================');
  }
}