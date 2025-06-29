import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/photo_location_service.dart';
import '../services/moment_service.dart';
import '../models/moment_entry.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  Map<String, double>? _photoLocation;
  bool _isSaving = false;
  final _supabase = Supabase.instance.client;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final location = await PhotoLocationService.extractLocationFromPhoto(image.path);
      setState(() {
        _selectedImage = File(image.path);
        _photoLocation = location;
      });
      
      if (location != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사진에서 위치 정보를 찾았습니다! 지도에서 확인하세요.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final location = await PhotoLocationService.extractLocationFromPhoto(image.path);
      setState(() {
        _selectedImage = File(image.path);
        _photoLocation = location;
      });
      
      if (location != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사진에서 위치 정보를 찾았습니다! 지도에서 확인하세요.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _saveRecord() async {
    // 입력 검증
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('한 줄 기록을 입력해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 사용자 인증 확인
    final user = _supabase.auth.currentUser;
    if (user == null) {
      // 오프라인 모드에서는 로컬에 저장하는 안내 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('오프라인 상태입니다.\n온라인 연결 후 다시 시도해주세요.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: '확인',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? imagePath;
      
      // 이미지가 있는 경우 Supabase Storage에 업로드
      if (_selectedImage != null) {
        final fileName = 'moments/${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage
            .from('moment-media')
            .uploadBinary(fileName, await _selectedImage!.readAsBytes());
        imagePath = fileName;
      }

      // MomentEntry 객체 생성
      final momentEntry = MomentEntry(
        id: '', // Supabase에서 자동 생성
        userId: user.id,
        title: '오늘의 기록', // 기본 제목
        content: _textController.text.trim(),
        imagePath: imagePath,
        latitude: _photoLocation?['latitude'],
        longitude: _photoLocation?['longitude'],
        locationName: null, // 나중에 geocoding으로 추가 가능
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 데이터베이스에 저장
      await MomentService.createMoment(momentEntry);

      // 성공 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기록이 저장되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );

        // 입력 필드 초기화
        _textController.clear();
        setState(() {
          _selectedImage = null;
          _photoLocation = null;
        });
      }
    } catch (e) {
      // 에러 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('사진 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!kIsWeb && !Platform.isMacOS)
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('카메라로 촬영'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy년 M월 d일').format(DateTime.now());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('OneMoment+'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              today,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            
            // Photo area
            GestureDetector(
              onTap: _showImagePickerDialog,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          if (_photoLocation != null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MapScreen(
                                        latitude: _photoLocation!['latitude']!,
                                        longitude: _photoLocation!['longitude']!,
                                        imageTitle: '사진 촬영 위치',
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '사진 추가',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Text input
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: '오늘의 한 줄 기록을 남겨보세요...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            const Spacer(),
            
            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveRecord,
                child: _isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('저장 중...'),
                        ],
                      )
                    : const Text('오늘 기록 저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}