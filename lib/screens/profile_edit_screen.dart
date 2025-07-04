import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _timezoneController = TextEditingController();
  final _languageController = TextEditingController();
  
  DateTime? _selectedBirthDate;
  File? _selectedImage;
  String? _currentProfileImageUrl;
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _timezoneController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _bioController.text = response['bio'] ?? '';
          _timezoneController.text = response['timezone'] ?? 'UTC';
          _languageController.text = response['language'] ?? 'ko';
          
          if (response['birth_date'] != null) {
            _selectedBirthDate = DateTime.parse(response['birth_date']);
          }

          // 기존 프로필 이미지 설정
          if (response['settings'] != null) {
            try {
              Map<String, dynamic> settings;
              if (response['settings'] is String) {
                settings = jsonDecode(response['settings']);
              } else {
                settings = response['settings'] as Map<String, dynamic>;
              }
              
              if (settings['profile_image'] != null) {
                _currentProfileImageUrl = settings['profile_image'];
              }
            } catch (e) {
              print('프로필 이미지 설정 파싱 오류: $e');
            }
          }
          
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _timezoneController.text = 'UTC';
          _languageController.text = 'ko';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 정보를 불러오는 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<String> _getProfileImageUrl(String imagePath) async {
    try {
      print('프로필 이미지 URL 생성 시도: $imagePath');
      
      // 올바른 버킷 결정
      String bucketName = 'profile-images';
      if (imagePath.startsWith('profiles/')) {
        bucketName = 'moment-media';
      }
      
      print('사용할 버킷: $bucketName');
      
      // 직접 Signed URL 생성 시도
      final signedUrl = await _supabase.storage
          .from(bucketName)
          .createSignedUrl(imagePath, 3600); // 1시간 유효
      
      print('Signed URL 생성 성공: $signedUrl');
      return signedUrl;
    } catch (e) {
      print('프로필 이미지 URL 생성 오류: $e');
      throw e;
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('사용자 정보가 없습니다');
        return null;
      }

      print('사용자 ID: ${user.id}');

      // 기존 이미지가 있다면 삭제 (파일이 실제로 존재하는 경우에만)
      if (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty) {
        try {
          print('기존 이미지 삭제 시도: $_currentProfileImageUrl');
          // 기존 파일이 moment-media에 있는지 profile-images에 있는지 확인
          String bucketToDelete = 'moment-media';
          if (_currentProfileImageUrl!.contains('profile-images/') || !_currentProfileImageUrl!.startsWith('profiles/')) {
            bucketToDelete = 'profile-images';
          }
          
          await _supabase.storage
              .from(bucketToDelete)
              .remove([_currentProfileImageUrl!]);
          print('기존 이미지 삭제 성공');
        } catch (e) {
          print('기존 이미지 삭제 오류 (파일이 없을 수 있음): $e');
        }
      }

      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${user.id}/$fileName';

      print('이미지 업로드 시작: $filePath');
      print('파일 크기: ${await _selectedImage!.length()} bytes');
      
      final uploadResult = await _supabase.storage
          .from('profile-images')
          .upload(filePath, _selectedImage!);

      print('이미지 업로드 성공: $filePath');
      print('업로드 결과: $uploadResult');
      return filePath;
    } catch (e) {
      print('이미지 업로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 업로드 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }

      String? imagePath;
      if (_selectedImage != null) {
        imagePath = await _uploadImage();
        if (imagePath != null) {
          print('새 이미지 업로드 성공: $imagePath');
        } else {
          print('이미지 업로드 실패, 기존 이미지 유지');
        }
      }

      final profileData = {
        'user_id': user.id,
        'bio': _bioController.text.trim(),
        'birth_date': _selectedBirthDate?.toIso8601String().split('T')[0],
        'timezone': _timezoneController.text.trim(),
        'language': _languageController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // settings를 JSON 문자열로 저장
      Map<String, dynamic> settings = {};
      
      // 새 이미지가 성공적으로 업로드된 경우
      if (imagePath != null) {
        settings['profile_image'] = imagePath;
        print('새 이미지 경로 저장: $imagePath');
      } 
      // 새 이미지 업로드가 없거나 실패한 경우 기존 이미지 유지
      else if (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty) {
        settings['profile_image'] = _currentProfileImageUrl;
        print('기존 이미지 경로 유지: $_currentProfileImageUrl');
      }
      
      if (settings.isNotEmpty) {
        profileData['settings'] = jsonEncode(settings);
        print('저장할 settings: ${jsonEncode(settings)}');
      } else {
        print('저장할 이미지 정보 없음');
      }

      print('프로필 데이터 저장 시도: $profileData');
      
      await _supabase
          .from('user_profiles')
          .upsert(profileData);
      
      print('프로필 저장 완료');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 성공적으로 저장되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 저장 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('프로필 편집'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: _selectedImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _currentProfileImageUrl != null
                                ? ClipOval(
                                    child: FutureBuilder<String>(
                                      future: _getProfileImageUrl(_currentProfileImageUrl!),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.network(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.account_circle,
                                                size: 40,
                                                color: Colors.grey,
                                              );
                                            },
                                          );
                                        }
                                        return const CircularProgressIndicator();
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('프로필 사진 변경'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: '자기소개',
                  hintText: '자신에 대해 간단히 소개해주세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                readOnly: true,
                onTap: _selectDate,
                decoration: InputDecoration(
                  labelText: '생년월일',
                  hintText: '생년월일을 선택하세요',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: _selectedBirthDate != null
                      ? '${_selectedBirthDate!.year}년 ${_selectedBirthDate!.month}월 ${_selectedBirthDate!.day}일'
                      : '',
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _timezoneController,
                decoration: const InputDecoration(
                  labelText: '시간대',
                  hintText: '예: Asia/Seoul, UTC',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _languageController.text.isEmpty ? 'ko' : _languageController.text,
                decoration: const InputDecoration(
                  labelText: '언어',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ko', child: Text('한국어')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ja', child: Text('日本語')),
                  DropdownMenuItem(value: 'zh', child: Text('中文')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _languageController.text = value;
                  }
                },
              ),
              
              const SizedBox(height: 32),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '계정 정보',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _supabase.auth.currentUser?.email ?? '게스트',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '가입일: ${_supabase.auth.currentUser?.createdAt?.split('T')[0] ?? '알 수 없음'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}