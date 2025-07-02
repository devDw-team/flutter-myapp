import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/moment_service.dart';
import '../models/moment_entry.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<MomentEntry> _moments = [];
  bool _isLoading = true;
  String? _error;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  Future<void> _loadMoments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 사용자 인증 확인
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = '오프라인 상태입니다.\n온라인 연결 후 새로고침해주세요.';
          _isLoading = false;
        });
        return;
      }

      // Supabase MCP를 사용하여 데이터베이스에서 일기 목록 가져오기
      final response = await _supabase
          .from('moment_entries')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      
      final moments = (response as List)
          .map((item) => MomentEntry.fromJson(item))
          .toList();
      
      if (mounted) {
        setState(() {
          _moments = moments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // 네트워크 오류 처리
        if (errorMessage.contains('SocketException') || 
            errorMessage.contains('Connection failed') ||
            errorMessage.contains('Failed host lookup')) {
          errorMessage = '네트워크 연결 오류\n인터넷 연결을 확인해주세요.';
        }
        
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshMoments() async {
    await _loadMoments();
  }

  Future<String> _getImageUrl(String imagePath) async {
    try {
      // Private 버킷이므로 createSignedUrl을 사용해야 함
      final signedUrl = await _supabase.storage
          .from('moment-media')
          .createSignedUrl(imagePath, 3600); // 1시간 유효한 서명된 URL
      return signedUrl;
    } catch (e) {
      print('이미지 URL 생성 오류: $e');
      return ''; // 빈 문자열 반환
    }
  }

  Future<void> _deleteMoment(MomentEntry moment) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 1. Storage에서 이미지 삭제 (있는 경우)
      if (moment.imagePath != null && moment.imagePath!.isNotEmpty) {
        await _supabase.storage
            .from('moment-media')
            .remove([moment.imagePath!]);
        print('이미지 삭제 완료: ${moment.imagePath}');
      }

      // 2. 데이터베이스에서 기록 삭제
      await _supabase
          .from('moment_entries')
          .delete()
          .eq('id', moment.id!)
          .eq('user_id', _supabase.auth.currentUser!.id);

      // 3. 로컬 리스트에서 제거
      setState(() {
        _moments.removeWhere((m) => m.id == moment.id);
        _isLoading = false;
      });

      // 4. 성공 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기록이 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('삭제 오류: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(MomentEntry moment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('기록 삭제'),
          content: const Text('이 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMoment(moment);
              },
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('타임라인'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMoments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '오류가 발생했습니다:\n$_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMoments,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _moments.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timeline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '아직 기록이 없습니다.\n홈에서 첫 번째 기록을 남겨보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshMoments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _moments.length,
                        itemBuilder: (context, index) {
                          final moment = _moments[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 날짜 헤더
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat('MM월 dd일').format(moment.createdAt),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormat('E HH:mm').format(moment.createdAt),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // 더 작고 세련된 삭제 버튼
                                      GestureDetector(
                                        onTap: () => _showDeleteConfirmation(moment),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.more_vert,
                                            color: Colors.grey,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // 이미지 (있는 경우)
                                  if (moment.imagePath != null && moment.imagePath!.isNotEmpty) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: FutureBuilder<String>(
                                        future: _getImageUrl(moment.imagePath!),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return Container(
                                              height: 200,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            );
                                          }
                                          
                                          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                                            return Container(
                                              height: 200,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.broken_image,
                                                    size: 48,
                                                    color: Colors.grey,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    '이미지를 불러올 수 없습니다',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                          
                                          return Image.network(
                                            snapshot.data!,
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                height: 200,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Center(
                                                  child: CircularProgressIndicator(),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              print('이미지 로딩 에러: $error');
                                              return Container(
                                                height: 200,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.broken_image,
                                                      size: 48,
                                                      color: Colors.grey,
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      '이미지를 불러올 수 없습니다',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  
                                  // 텍스트 내용
                                  Text(
                                    moment.content,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  
                                  // 위치 정보 (있는 경우)
                                  if (moment.latitude != null && moment.longitude != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          moment.locationName ?? 
                                          '${moment.latitude!.toStringAsFixed(4)}, ${moment.longitude!.toStringAsFixed(4)}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}