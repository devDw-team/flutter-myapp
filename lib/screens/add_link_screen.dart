import 'package:flutter/material.dart';

class AddLinkScreen extends StatefulWidget {
  const AddLinkScreen({super.key});

  @override
  State<AddLinkScreen> createState() => _AddLinkScreenState();
}

class _AddLinkScreenState extends State<AddLinkScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  
  final List<String> _tags = [];
  bool _isValidUrl = true;

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _validateUrl() {
    final url = _urlController.text.trim();
    setState(() {
      _isValidUrl = url.isEmpty || Uri.tryParse(url) != null;
    });
  }

  void _extractTitle() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty && Uri.tryParse(url) != null) {
      // Simple title extraction from URL
      try {
        final uri = Uri.parse(url);
        final domain = uri.host.replaceAll('www.', '');
        _titleController.text = domain;
      } catch (e) {
        // Handle extraction error
      }
    }
  }

  void _saveLink() {
    final url = _urlController.text.trim();
    final title = _titleController.text.trim();
    
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL을 입력해주세요.')),
      );
      return;
    }
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요.')),
      );
      return;
    }
    
    if (!_isValidUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 URL을 입력해주세요.')),
      );
      return;
    }

    final newLink = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'url': url,
      'title': title,
      'tags': List.from(_tags),
      'date': DateTime.now(),
    };

    Navigator.pop(context, newLink);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 링크 저장'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveLink,
            child: const Text('저장'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com',
                border: const OutlineInputBorder(),
                errorText: !_isValidUrl ? '올바른 URL을 입력해주세요' : null,
                suffixIcon: IconButton(
                  onPressed: _extractTitle,
                  icon: const Icon(Icons.download),
                  tooltip: '제목 자동 추출',
                ),
              ),
              onChanged: (value) => _validateUrl(),
              keyboardType: TextInputType.url,
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '링크 제목을 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _tagController,
              decoration: InputDecoration(
                labelText: '태그',
                hintText: '태그를 입력하세요',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add),
                ),
              ),
              onSubmitted: (value) => _addTag(),
            ),
            
            const SizedBox(height: 16),
            
            if (_tags.isNotEmpty) ...[
              const Text(
                '추가된 태그:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => _removeTag(tag),
                )).toList(),
              ),
            ],
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveLink,
                child: const Text('링크 저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}