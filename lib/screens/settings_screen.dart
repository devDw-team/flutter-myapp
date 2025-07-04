import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin/database_admin_screen.dart';
import 'profile_edit_screen.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  final _supabase = Supabase.instance.client;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _clearInvalidProfileImage() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      print('잘못된 프로필 이미지 정보 정리 중...');
      
      // 프로필에서 이미지 정보 제거
      await _supabase
          .from('user_profiles')
          .update({'settings': '{}'})
          .eq('user_id', user.id);
      
      print('프로필 이미지 정보 정리 완료');
    } catch (e) {
      print('프로필 이미지 정리 오류: $e');
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('사용자 정보가 없습니다');
        return;
      }

      print('프로필 이미지 로드 시작: ${user.id}');

      final response = await _supabase
          .from('user_profiles')
          .select('settings')
          .eq('user_id', user.id)
          .maybeSingle();

      print('프로필 응답: $response');

      if (response != null && response['settings'] != null) {
        try {
          Map<String, dynamic> settings;
          if (response['settings'] is String) {
            settings = jsonDecode(response['settings']);
          } else {
            settings = response['settings'] as Map<String, dynamic>;
          }
          
          print('설정 파싱 성공: $settings');
          
          if (settings['profile_image'] != null) {
            final imagePath = settings['profile_image'] as String;
            print('이미지 경로: $imagePath');
            
            // 올바른 버킷 결정 (기존 파일은 moment-media에 있을 수 있음)
            String bucketName = 'profile-images';
            if (imagePath.startsWith('profiles/')) {
              bucketName = 'moment-media';
            }
            
            print('사용할 버킷: $bucketName');
            
            // 직접 Signed URL 생성 시도 (파일 존재 확인 건너뛰기)
            try {
              final signedUrl = await _supabase.storage
                  .from(bucketName)
                  .createSignedUrl(imagePath, 3600);
              
              print('Signed URL 생성 성공: $signedUrl');
              
              setState(() {
                _profileImageUrl = signedUrl;
              });
            } catch (storageError) {
              print('Storage 접근 오류: $storageError');
              // 파일이 없거나 접근할 수 없으면 설정에서 제거
              await _clearInvalidProfileImage();
            }
          }
        } catch (e) {
          print('설정 파싱 오류: $e');
        }
      } else {
        print('프로필 설정이 없습니다');
      }
    } catch (e) {
      print('프로필 이미지 로드 오류: $e');
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        // 모든 화면을 제거하고 루트로 이동하여 AuthWrapper가 처리하도록 함
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getUserDisplayName() {
    final user = _supabase.auth.currentUser;
    if (user == null) return '게스트';
    
    if (user.isAnonymous) {
      return '게스트 사용자';
    } else {
      return user.email ?? '사용자';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 사용자 정보 섹션
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _profileImageUrl != null
                    ? Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            _profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.account_circle,
                                size: 64,
                                color: Colors.blue,
                              );
                            },
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.account_circle,
                        size: 64,
                        color: Colors.blue,
                      ),
                const SizedBox(height: 8),
                Text(
                  _getUserDisplayName(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _supabase.auth.currentUser?.isAnonymous == true 
                      ? '임시 계정으로 로그인됨'
                      : 'OneMoment+ 사용자',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '앱 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          SwitchListTile(
            title: const Text('알림'),
            subtitle: const Text('일일 기록 알림을 받습니다'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          
          SwitchListTile(
            title: const Text('다크 모드'),
            subtitle: const Text('어두운 테마를 사용합니다'),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),
          
          
          const Divider(),
          
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '계정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('프로필 편집'),
            subtitle: const Text('개인 정보 및 프로필 설정'),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileEditScreen(),
                ),
              );
              // 프로필 편집 후 돌아오면 이미지 새로고침
              if (result == null) {
                _loadProfileImage();
              }
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('로그아웃'),
            subtitle: const Text('현재 계정에서 로그아웃합니다'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('정말로 로그아웃하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleLogout();
                        },
                        child: const Text(
                          '로그아웃',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          
          const Divider(),
          
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '앱 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('버전'),
            subtitle: Text('1.0.0'),
          ),
          
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('도움말'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('OneMoment+ 사용법'),
                    content: const Text(
                      '• 홈: 오늘의 사진과 한 줄 기록을 남겨보세요\n'
                      '• 타임라인: 지금까지의 모든 기록을 확인할 수 있습니다\n'
                      '• 정보: 유용한 링크들을 저장하고 관리하세요\n'
                      '• 설정: 앱 환경을 설정할 수 있습니다',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('확인'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}