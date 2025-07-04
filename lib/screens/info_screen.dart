import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/useful_link.dart';
import '../services/ai_analysis_service.dart';
import 'link_detail_screen.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _supabase = Supabase.instance.client;
  
  List<UsefulLink> _links = [];
  List<UsefulLink> _filteredLinks = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadLinks();
    _searchController.addListener(_filterLinks);
  }

  Future<void> _loadLinks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 사용자 인증 확인
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = '로그인이 필요합니다.';
          _isLoading = false;
        });
        return;
      }

      // Supabase MCP를 사용하여 데이터베이스에서 링크 목록 가져오기
      final response = await _supabase
          .from('useful_links')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      
      final links = (response as List)
          .map((item) => UsefulLink.fromJson(item))
          .toList();
      
      if (mounted) {
        setState(() {
          _links = links;
          _filteredLinks = List.from(_links);
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

  void _filterLinks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLinks = _links.where((link) {
        return link.title.toLowerCase().contains(query) ||
               link.description?.toLowerCase().contains(query) == true ||
               link.tags.any((tag) => tag.toLowerCase().contains(query)) ||
               link.category.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _refreshLinks() async {
    await _loadLinks();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('링크를 열 수 없습니다: $url')),
        );
      }
    }
  }

  void _navigateToAddLink() async {
    final result = await showDialog<UsefulLink>(
      context: context,
      builder: (context) => _AddLinkDialog(),
    );
    
    if (result != null) {
      await _saveLink(result);
    }
  }

  Future<void> _saveLink(UsefulLink link) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final linkData = link.toInsertJson();
      linkData['user_id'] = user.id;

      await _supabase.from('useful_links').insert(linkData);
      
      // 목록 새로고침
      await _loadLinks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('링크가 저장되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('링크 저장 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteLink(UsefulLink link) async {
    try {
      await _supabase
          .from('useful_links')
          .delete()
          .eq('id', link.id!)
          .eq('user_id', _supabase.auth.currentUser!.id);

      // 로컬 리스트에서 제거
      setState(() {
        _links.removeWhere((l) => l.id == link.id);
        _filterLinks();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('링크가 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('링크 삭제 오류: $e');
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

  void _showDeleteConfirmation(UsefulLink link) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('링크 삭제'),
          content: Text('${link.title}을(를) 삭제하시겠습니까?\n삭제된 링크는 복구할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteLink(link);
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
        title: const Text('정보 보관함'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLinks,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '제목, 설명, 태그, 카테고리로 검색...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
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
                              onPressed: _loadLinks,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      )
                    : _filteredLinks.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.link_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '저장된 링크가 없습니다.\n새 링크를 추가해보세요!',
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
                            onRefresh: _refreshLinks,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredLinks.length,
                              itemBuilder: (context, index) {
                                final link = _filteredLinks[index];
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () async {
                                      final result = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LinkDetailScreen(link: link),
                                        ),
                                      );
                                      
                                      // 삭제되었으면 목록 새로고침
                                      if (result == true) {
                                        await _loadLinks();
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Hero(
                                                  tag: 'link_title_${link.id}',
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: Text(
                                                      link.title,
                                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // 즐겨찾기 아이콘
                                              if (link.isFavorite)
                                                const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 20,
                                                ),
                                              const SizedBox(width: 8),
                                              // 링크 열기 버튼
                                              GestureDetector(
                                                onTap: () {
                                                  _launchUrl(link.url);
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.open_in_new,
                                                    color: Colors.blue,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          // 설명 (있는 경우)
                                          if (link.description != null && link.description!.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              link.description!,
                                              style: Theme.of(context).textTheme.bodyMedium,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          
                                          const SizedBox(height: 8),
                                          
                                          Text(
                                            link.url,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          
                                          const SizedBox(height: 8),
                                          
                                          Row(
                                            children: [
                                              // 태그들
                                              Expanded(
                                                child: Wrap(
                                                  spacing: 4,
                                                  runSpacing: 4,
                                                  children: link.tags
                                                      .map((tag) => Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey[200],
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Text(
                                                              tag,
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                color: Colors.black87,
                                                              ),
                                                            ),
                                                          ))
                                                      .toList(),
                                                ),
                                              ),
                                              // 날짜
                                              Text(
                                                DateFormat('MM/dd').format(link.createdAt),
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddLink,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _AddLinkDialog extends StatefulWidget {
  @override
  State<_AddLinkDialog> createState() => _AddLinkDialogState();
}

class _AddLinkDialogState extends State<_AddLinkDialog> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String _selectedCategory = '경제';
  bool _isFavorite = false;
  int _currentStep = 0;
  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;
  String? _thumbnailUrl;
  String? _channelName;

  final _formKey = GlobalKey<FormState>();

  final List<String> _categories = [
    '경제',
    '경영', 
    '정치',
    '사회',
    'IT',
    'AI',
    '바이브코딩',
  ];

  final List<Map<String, dynamic>> _categoryData = [
    {'name': '경제', 'icon': Icons.trending_up, 'color': Colors.green},
    {'name': '경영', 'icon': Icons.business, 'color': Colors.blue},
    {'name': '정치', 'icon': Icons.account_balance, 'color': Colors.purple},
    {'name': '사회', 'icon': Icons.groups, 'color': Colors.orange},
    {'name': 'IT', 'icon': Icons.computer, 'color': Colors.indigo},
    {'name': 'AI', 'icon': Icons.smart_toy, 'color': Colors.cyan},
    {'name': '바이브코딩', 'icon': Icons.code, 'color': Colors.pink},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_link,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '새 링크 추가',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Progress Indicator
            Container(
              height: 4,
              color: Colors.grey[200],
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: MediaQuery.of(context).size.width * 0.9 * ((_currentStep + 1) / 3),
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.6)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_hasAnalyzed) ...[
                          // URL 입력 단계
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Theme.of(context).primaryColor,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'AI가 자동으로 분석해드려요',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'URL을 입력하면 제목, 요약, 태그를 자동으로 추출합니다',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // URL 입력
                          TextFormField(
                            controller: _urlController,
                            decoration: InputDecoration(
                              labelText: 'URL',
                              hintText: 'https://example.com 또는 YouTube 링크',
                              prefixIcon: Icon(
                                AiAnalysisService.isYouTubeUrl(_urlController.text) 
                                    ? Icons.video_library
                                    : Icons.link,
                                color: AiAnalysisService.isYouTubeUrl(_urlController.text) 
                                    ? Colors.red
                                    : null,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'URL을 입력해주세요.';
                              }
                              final uri = Uri.tryParse(value);
                              if (uri == null || !uri.hasAbsolutePath || !uri.hasScheme) {
                                return '올바른 URL을 입력해주세요.';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {}); // 아이콘 업데이트
                            },
                          ),
                          const SizedBox(height: 32),
                          
                          // AI 분석 버튼
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isAnalyzing ? null : _analyzeUrl,
                                  icon: _isAnalyzing 
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.auto_awesome),
                                  label: Text(
                                    _isAnalyzing ? '분석 중...' : 'AI로 분석하기',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                if (_urlController.text.isNotEmpty) {
                                  setState(() {
                                    _hasAnalyzed = true;
                                    _titleController.text = _urlController.text; // URL을 제목으로 임시 설정
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('URL을 먼저 입력해주세요.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                '수동으로 입력하기',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ] else if (_currentStep == 0) ...[
                          // Step 0: 분석 결과 및 기본 정보
                          if (_thumbnailUrl != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _thumbnailUrl!,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // AI 분석 결과 표시
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'AI 분석 완료',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // 제목 입력
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: '제목',
                              hintText: '링크의 제목을 입력하세요',
                              prefixIcon: const Icon(Icons.title),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '제목을 입력해주세요.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // 요약 입력
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: '요약',
                              hintText: '링크에 대한 간단한 설명',
                              prefixIcon: const Icon(Icons.description),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            maxLines: 3,
                          ),
                        ] else if (_currentStep == 1) ...[
                          // Step 1: 카테고리 선택
                          Text(
                            '카테고리 선택',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '링크의 카테고리를 선택해주세요',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // 카테고리 선택 (Grid)
                          SizedBox(
                            height: 120,
                            child: GridView.builder(
                              scrollDirection: Axis.horizontal,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.6,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _categoryData.length,
                              itemBuilder: (context, index) {
                                final category = _categoryData[index];
                                final isSelected = _selectedCategory == category['name'];
                                
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = category['name'];
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? category['color'].withOpacity(0.2)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected 
                                            ? category['color']
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          category['icon'],
                                          color: isSelected 
                                              ? category['color']
                                              : Colors.grey[600],
                                          size: 28,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          category['name'],
                                          style: TextStyle(
                                            color: isSelected 
                                                ? category['color']
                                                : Colors.grey[700],
                                            fontWeight: isSelected 
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ] else if (_currentStep == 2) ...[
                          // Step 2: 태그 및 옵션
                          Text(
                            '태그 및 옵션',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '태그를 추가하고 즐겨찾기 여부를 선택하세요',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // 태그 입력
                          TextFormField(
                            controller: _tagsController,
                            decoration: InputDecoration(
                              labelText: '태그',
                              hintText: '태그를 입력하세요 (쉼표로 구분)',
                              prefixIcon: const Icon(Icons.label),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // 추천 태그
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_tagsController.text.isNotEmpty) ...[
                                Text(
                                  'AI가 추출한 태그',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              Wrap(
                                spacing: 8,
                                children: [
                                  '읽어보기', '중요', '참고자료', '나중에', '업무'
                                ].map((tag) => ActionChip(
                                  label: Text(tag),
                                  onPressed: () {
                                    final currentTags = _tagsController.text;
                                    if (currentTags.isEmpty) {
                                      _tagsController.text = tag;
                                    } else if (!currentTags.contains(tag)) {
                                      _tagsController.text = '$currentTags, $tag';
                                    }
                                  },
                                )).toList(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // 즐겨찾기 옵션
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isFavorite ? Colors.amber : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isFavorite ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '즐겨찾기로 추가',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '자주 사용하는 링크를 즐겨찾기로 표시하세요',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isFavorite,
                                  onChanged: (value) {
                                    setState(() {
                                      _isFavorite = value;
                                    });
                                  },
                                  activeColor: Colors.amber,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0 || (_hasAnalyzed && _currentStep == 0))
                    TextButton.icon(
                      onPressed: () {
                        if (_hasAnalyzed && _currentStep == 0) {
                          setState(() {
                            _hasAnalyzed = false;
                            _titleController.clear();
                            _descriptionController.clear();
                            _tagsController.clear();
                            _thumbnailUrl = null;
                            _channelName = null;
                          });
                        } else {
                          setState(() {
                            _currentStep--;
                          });
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('이전'),
                    ),
                  const Spacer(),
                  if (_hasAnalyzed && _currentStep < 2)
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_currentStep == 0) {
                          if (_titleController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('제목을 입력해주세요.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        }
                        setState(() {
                          _currentStep++;
                        });
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('다음'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final tags = _tagsController.text
                              .split(',')
                              .map((tag) => tag.trim())
                              .where((tag) => tag.isNotEmpty)
                              .toList();

                          final link = UsefulLink(
                            title: _titleController.text.trim(),
                            url: _urlController.text.trim(),
                            description: _descriptionController.text.trim().isEmpty 
                                ? null 
                                : _descriptionController.text.trim(),
                            category: _selectedCategory,
                            tags: tags,
                            isFavorite: _isFavorite,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          Navigator.of(context).pop(link);
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('저장'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAbsolutePath || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('올바른 URL을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      final result = await AiAnalysisService.analyzeUrl(url);
      
      setState(() {
        _titleController.text = result['title'] ?? '';
        _descriptionController.text = result['summary'] ?? '';
        _tagsController.text = result['tags'] ?? '';
        _thumbnailUrl = result['thumbnail'];
        _channelName = result['channel'];
        _hasAnalyzed = true;
        _isAnalyzing = false;
      });
      
      // 성공 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI 분석이 완료되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI 분석 중 오류 발생: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '수동 입력',
              onPressed: () {
                setState(() {
                  _hasAnalyzed = true;
                });
              },
            ),
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}