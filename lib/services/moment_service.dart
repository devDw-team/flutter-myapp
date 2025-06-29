import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // supabase 클라이언트 접근
import '../models/moment_entry.dart';

class MomentService {
  static const String tableName = 'moment_entries';

  // 모든 일기 항목 조회
  Future<List<MomentEntry>> getAllMoments() async {
    try {
      final response = await supabase
          .from(tableName)
          .select()
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => MomentEntry.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('일기 목록을 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  // 특정 일기 항목 조회
  Future<MomentEntry?> getMomentById(String id) async {
    try {
      final response = await supabase
          .from(tableName)
          .select()
          .eq('id', id)
          .single();
      
      return MomentEntry.fromJson(response);
    } catch (e) {
      throw Exception('일기를 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  // 새로운 일기 항목 생성
  Future<MomentEntry> createMoment(MomentEntry moment) async {
    try {
      final response = await supabase
          .from(tableName)
          .insert(moment.toInsertJson())
          .select()
          .single();
      
      return MomentEntry.fromJson(response);
    } catch (e) {
      throw Exception('일기 저장 중 오류가 발생했습니다: $e');
    }
  }

  // 일기 항목 업데이트
  Future<MomentEntry> updateMoment(String id, MomentEntry moment) async {
    try {
      final updateData = moment.toInsertJson();
      updateData['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await supabase
          .from(tableName)
          .update(updateData)
          .eq('id', id)
          .select()
          .single();
      
      return MomentEntry.fromJson(response);
    } catch (e) {
      throw Exception('일기 수정 중 오류가 발생했습니다: $e');
    }
  }

  // 일기 항목 삭제
  Future<void> deleteMoment(String id) async {
    try {
      await supabase
          .from(tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('일기 삭제 중 오류가 발생했습니다: $e');
    }
  }

  // 날짜 범위로 일기 검색
  Future<List<MomentEntry>> getMomentsByDateRange(DateTime start, DateTime end) async {
    try {
      final response = await supabase
          .from(tableName)
          .select()
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
  Future<List<MomentEntry>> searchMoments(String query) async {
    try {
      final response = await supabase
          .from(tableName)
          .select()
          .or('title.ilike.%$query%,content.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => MomentEntry.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('일기 검색 중 오류가 발생했습니다: $e');
    }
  }

  // 이미지 업로드 (Supabase Storage 사용)
  Future<String?> uploadImage(String filePath, String fileName) async {
    try {
      final bytes = await supabase.storage
          .from('moment-images')
          .uploadBinary(fileName, await _getFileBytes(filePath));
      
      final publicUrl = supabase.storage
          .from('moment-images')
          .getPublicUrl(fileName);
      
      return publicUrl;
    } catch (e) {
      throw Exception('이미지 업로드 중 오류가 발생했습니다: $e');
    }
  }

  // 파일 바이트 읽기 헬퍼 메서드 (실제 구현 시 플랫폼별 처리 필요)
  Future<List<int>> _getFileBytes(String filePath) async {
    // 실제 구현에서는 File.readAsBytes() 또는 플랫폼별 파일 읽기 로직 필요
    throw UnimplementedError('파일 읽기 로직을 구현해야 합니다');
  }
} 