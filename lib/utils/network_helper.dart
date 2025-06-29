import 'dart:io';

class NetworkHelper {
  /// 네트워크 연결 상태 확인
  static Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (e) {
      // 연결 실패
    }
    return false;
  }

  /// Supabase 서버 연결 상태 확인
  static Future<bool> checkSupabaseConnection() async {
    try {
      final result = await InternetAddress.lookup('exmbyyqmhjqsvbyyrmad.supabase.co');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (e) {
      // 연결 실패
    }
    return false;
  }

  /// 네트워크 오류 메시지 가공
  static String getNetworkErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('socketexception') || errorStr.contains('connection failed')) {
      return '네트워크 연결 오류가 발생했습니다.\n인터넷 연결을 확인해주세요.';
    } else if (errorStr.contains('host lookup') || errorStr.contains('dns')) {
      return 'DNS 조회에 실패했습니다.\n네트워크 설정을 확인해주세요.';
    } else if (errorStr.contains('timeout')) {
      return '연결 시간이 초과되었습니다.\n잠시 후 다시 시도해주세요.';
    } else if (errorStr.contains('operation not permitted')) {
      return '네트워크 접근이 차단되었습니다.\n방화벽 설정을 확인해주세요.';
    } else {
      return '알 수 없는 네트워크 오류가 발생했습니다.';
    }
  }

  /// 오프라인 모드 안내 메시지
  static String get offlineModeMessage => 
      '현재 오프라인 상태입니다.\n'
      '인터넷 연결 후 다시 시도해주세요.\n\n'
      '일부 기능이 제한될 수 있습니다.';

  /// 재연결 시도 안내 메시지
  static String get retryConnectionMessage => 
      '네트워크 연결을 다시 시도하시겠습니까?';
}