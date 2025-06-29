import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseMigrationService {
  static final _supabase = Supabase.instance.client;

  /// 전체 데이터베이스 스키마 마이그레이션 실행
  static Future<Map<String, dynamic>> runFullMigration() async {
    final results = <String, dynamic>{};
    
    try {
      // 1. 사용자 관련 테이블 생성
      results['users'] = await _createUserTables();
      
      // 2. 일기 관련 테이블 확장
      results['moments'] = await _createMomentTables();
      
      // 3. 태그 및 카테고리 시스템
      results['categorization'] = await _createCategorizationTables();
      
      // 4. 부가 기능 테이블
      results['additional'] = await _createAdditionalTables();
      
      // 5. 인덱스 생성
      results['indexes'] = await _createIndexes();
      
      // 6. 트리거 및 함수 생성
      results['triggers'] = await _createTriggersAndFunctions();
      
      // 7. RLS 정책 설정
      results['rls'] = await _setupRLSPolicies();
      
      results['status'] = 'success';
      results['message'] = 'Database migration completed successfully';
      
    } catch (e) {
      results['status'] = 'error';
      results['message'] = 'Migration failed: $e';
    }
    
    return results;
  }

  /// 사용자 관련 테이블 생성
  static Future<Map<String, dynamic>> _createUserTables() async {
    final results = <String, dynamic>{};
    
    try {
      // user_profiles 테이블 생성
      await _supabase.rpc('create_user_profiles_table');
      results['user_profiles'] = 'created';
      
      // user_statistics 테이블 생성
      await _supabase.rpc('create_user_statistics_table');
      results['user_statistics'] = 'created';
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// 일기 관련 테이블 생성/확장
  static Future<Map<String, dynamic>> _createMomentTables() async {
    final results = <String, dynamic>{};
    
    try {
      // moment_entries 테이블 확장
      await _supabase.rpc('extend_moment_entries_table');
      results['moment_entries'] = 'extended';
      
      // moment_media 테이블 생성
      await _supabase.rpc('create_moment_media_table');
      results['moment_media'] = 'created';
      
      // moment_locations 테이블 생성
      await _supabase.rpc('create_moment_locations_table');
      results['moment_locations'] = 'created';
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// 태그 및 카테고리 시스템 테이블 생성
  static Future<Map<String, dynamic>> _createCategorizationTables() async {
    final results = <String, dynamic>{};
    
    try {
      // tags 테이블 생성
      await _supabase.rpc('create_tags_table');
      results['tags'] = 'created';
      
      // moment_tags 연결 테이블 생성
      await _supabase.rpc('create_moment_tags_table');
      results['moment_tags'] = 'created';
      
      // categories 테이블 생성
      await _supabase.rpc('create_categories_table');
      results['categories'] = 'created';
      
      // moment_categories 연결 테이블 생성
      await _supabase.rpc('create_moment_categories_table');
      results['moment_categories'] = 'created';
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// 부가 기능 테이블 생성
  static Future<Map<String, dynamic>> _createAdditionalTables() async {
    final results = <String, dynamic>{};
    
    try {
      // mood_tracking 테이블 생성
      await _supabase.rpc('create_mood_tracking_table');
      results['mood_tracking'] = 'created';
      
      // backup_sessions 테이블 생성
      await _supabase.rpc('create_backup_sessions_table');
      results['backup_sessions'] = 'created';
      
      // notifications 테이블 생성
      await _supabase.rpc('create_notifications_table');
      results['notifications'] = 'created';
      
      // sync_logs 테이블 생성
      await _supabase.rpc('create_sync_logs_table');
      results['sync_logs'] = 'created';
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// 성능 최적화 인덱스 생성
  static Future<Map<String, dynamic>> _createIndexes() async {
    final results = <String, dynamic>{};
    
    try {
      await _supabase.rpc('create_performance_indexes');
      results['indexes'] = 'created';
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// 트리거 및 함수 생성
  static Future<Map<String, dynamic>> _createTriggersAndFunctions() async {
    final results = <String, dynamic>{};
    
    try {
      await _supabase.rpc('create_database_triggers');
      results['triggers'] = 'created';
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// RLS 정책 설정
  static Future<Map<String, dynamic>> _setupRLSPolicies() async {
    final results = <String, dynamic>{};
    
    try {
      await _supabase.rpc('setup_rls_policies');
      results['rls_policies'] = 'configured';
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// 기존 데이터 마이그레이션
  static Future<Map<String, dynamic>> migrateExistingData() async {
    final results = <String, dynamic>{};
    
    try {
      // 기존 moment_entries의 위치 데이터를 moment_locations로 이관
      await _supabase.rpc('migrate_location_data');
      results['location_migration'] = 'completed';
      
      // 기존 이미지 데이터를 moment_media로 이관
      await _supabase.rpc('migrate_media_data');
      results['media_migration'] = 'completed';
      
      // 사용자 통계 초기화
      await _supabase.rpc('initialize_user_statistics');
      results['statistics_init'] = 'completed';
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// 데이터베이스 상태 확인
  static Future<Map<String, dynamic>> checkDatabaseStatus() async {
    final results = <String, dynamic>{};
    
    try {
      // 테이블 존재 확인
      final tableCheck = await _supabase.rpc('check_table_existence');
      results['tables'] = tableCheck;
      
      // 인덱스 상태 확인
      final indexCheck = await _supabase.rpc('check_index_status');
      results['indexes'] = indexCheck;
      
      // RLS 정책 상태 확인
      final rlsCheck = await _supabase.rpc('check_rls_status');
      results['rls'] = rlsCheck;
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }
}