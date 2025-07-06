import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/useful_link.dart';

class LinkDetailScreen extends StatefulWidget {
  final UsefulLink link;
  
  const LinkDetailScreen({
    super.key,
    required this.link,
  });

  @override
  State<LinkDetailScreen> createState() => _LinkDetailScreenState();
}

class _LinkDetailScreenState extends State<LinkDetailScreen> {
  final _supabase = Supabase.instance.client;
  late UsefulLink _link;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _link = widget.link;
  }
  
  Future<void> _launchUrl() async {
    final uri = Uri.parse(_link.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('링크를 열 수 없습니다: ${_link.url}')),
        );
      }
    }
  }
  
  Future<void> _toggleFavorite() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final newFavoriteStatus = !_link.isFavorite;
      
      await _supabase
          .from('useful_links')
          .update({
            'is_favorite': newFavoriteStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _link.id!)
          .eq('user_id', _supabase.auth.currentUser!.id);
      
      setState(() {
        _link = _link.copyWith(
          isFavorite: newFavoriteStatus,
          updatedAt: DateTime.now(),
        );
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newFavoriteStatus ? '즐겨찾기에 추가되었습니다.' : '즐겨찾기가 해제되었습니다.'
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _deleteLink() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('링크 삭제'),
        content: Text('${_link.title}을(를) 삭제하시겠습니까?\n삭제된 링크는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _supabase
          .from('useful_links')
          .delete()
          .eq('id', _link.id!)
          .eq('user_id', _supabase.auth.currentUser!.id);
      
      if (mounted) {
        Navigator.of(context).pop(true); // 삭제 성공을 나타내는 true 반환
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('링크가 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('링크 상세'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _link.isFavorite ? Icons.star : Icons.star_border,
              color: _link.isFavorite ? Colors.amber : null,
            ),
            onPressed: _isLoading ? null : _toggleFavorite,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteLink();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('삭제', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Hero(
                tag: 'link_title_${_link.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    _link.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // URL
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _link.url,
                        style: TextStyle(
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // 링크 열기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _launchUrl,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('링크 열기'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // 설명
              if (_link.description != null && _link.description!.isNotEmpty) ...[
                Text(
                  '설명',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _link.description!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // 카테고리
              Row(
                children: [
                  Icon(Icons.category, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '카테고리',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _link.category,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // 태그
              if (_link.tags.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.label, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '태그',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _link.tags.map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Colors.grey[200],
                  )).toList(),
                ),
                const SizedBox(height: 24),
              ],
              
              // 날짜 정보
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '생성일',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('yyyy년 MM월 dd일 HH:mm').format(_link.createdAt),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.update, color: Colors.grey[600], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '수정일',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('yyyy년 MM월 dd일 HH:mm').format(_link.updatedAt),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}