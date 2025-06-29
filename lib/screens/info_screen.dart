import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_link_screen.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Sample data - replace with actual data from storage
  List<Map<String, dynamic>> _links = [
    {
      'id': '1',
      'url': 'https://flutter.dev',
      'title': 'Flutter - Build apps for any screen',
      'tags': ['개발', 'Flutter'],
      'date': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': '2',
      'url': 'https://github.com',
      'title': 'GitHub: Let\'s build from here',
      'tags': ['개발', 'Git'],
      'date': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'id': '3',
      'url': 'https://material.io',
      'title': 'Material Design',
      'tags': ['디자인', 'UI'],
      'date': DateTime.now().subtract(const Duration(days: 5)),
    },
  ];

  List<Map<String, dynamic>> _filteredLinks = [];
  
  @override
  void initState() {
    super.initState();
    _filteredLinks = List.from(_links);
    _searchController.addListener(_filterLinks);
  }

  void _filterLinks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLinks = _links.where((link) {
        return link['title'].toLowerCase().contains(query) ||
               link['tags'].any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    });
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddLinkScreen()),
    );
    
    if (result != null) {
      setState(() {
        _links.insert(0, result);
        _filterLinks();
      });
    }
  }

  void _deleteLink(String id) {
    setState(() {
      _links.removeWhere((link) => link['id'] == id);
      _filterLinks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정보 보관함'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '제목이나 태그로 검색...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          
          Expanded(
            child: _filteredLinks.isEmpty
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
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredLinks.length,
                    itemBuilder: (context, index) {
                      final link = _filteredLinks[index];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _launchUrl(link['url']),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        link['title'],
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteLink(link['id']),
                                      icon: const Icon(Icons.delete_outline),
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 8),
                                
                                Text(
                                  link['url'],
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                const SizedBox(height: 8),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: Wrap(
                                        spacing: 4,
                                        children: (link['tags'] as List<String>)
                                            .map((tag) => Chip(
                                                  label: Text(
                                                    tag,
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                    Text(
                                      '${link['date'].month}/${link['date'].day}',
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