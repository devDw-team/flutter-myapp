import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // supabase 클라이언트 접근
import '../models/moment_entry.dart';

class MomentService {
  static const String tableName = 'moment_entries';

  // 현재 사용자의 모든 일기 항목 조회
  static Future<List<MomentEntry>> getAllMoments() async {
    try {
      // 현재 로그인된 사용자 확인
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final response = await supabase
          .from(tableName)
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => MomentEntry.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('일기 목록을 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  // 특정 일기 항목 조회
  static Future<MomentEntry?> getMomentById(String id) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final response = await supabase
          .from(tableName)
          .select()
          .eq('id', id)
          .eq('user_id', user.id)
          .single();
      
      return MomentEntry.fromJson(response);
    } catch (e) {
      throw Exception('일기를 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  // 새로운 일기 항목 생성
  static Future<MomentEntry> createMoment(MomentEntry moment) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // user_id 설정
      final momentData = moment.toInsertJson();
      momentData['user_id'] = user.id;

      final response = await supabase
          .from(tableName)
          .insert(momentData)
          .select()
          .single();
      
      return MomentEntry.fromJson(response);
    } catch (e) {
      throw Exception('일기 저장 중 오류가 발생했습니다: $e');
    }
  }

  // 일기 항목 업데이트
  static Future<MomentEntry> updateMoment(String id, MomentEntry moment) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final updateData = moment.toInsertJson();
      updateData['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await supabase
          .from(tableName)
          .update(updateData)
          .eq('id', id)
          .eq('user_id', user.id)
          .select()
          .single();
      
      return MomentEntry.fromJson(response);
    } catch (e) {
      throw Exception('일기 수정 중 오류가 발생했습니다: $e');
    }
  }

  // 일기 항목 삭제
  static Future<void> deleteMoment(String id) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      await supabase
          .from(tableName)
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('일기 삭제 중 오류가 발생했습니다: $e');
    }
  }

  // 날짜 범위로 일기 검색
  static Future<List<MomentEntry>> getMomentsByDateRange(DateTime start, DateTime end) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final response = await supabase
          .from(tableName)
          .select()
          .eq('user_id', user.id)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => MomentEntry.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('날짜별 일기 검색 중 오류가 발생했습니다: $e');
    }
  }

  // 텍스트로 일기 검색
  static Future<List<MomentEntry>> searchMoments(String query) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final response = await supabase
          .from(tableName)
          .select()
          .eq('user_id', user.id)
          .or('title.ilike.%$query%,content.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => MomentEntry.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('일기 검색 중 오류가 발생했습니다: $e');
    }
  }

  // 이미지 업로드 (Supabase Storage 사용) - 현재 사용하지 않음
  // 홈 화면에서 직접 Storage API 사용
} 