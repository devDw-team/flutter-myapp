import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  // Sample data - replace with actual data from storage
  final List<Map<String, dynamic>> _records = [
    {
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'text': '오늘은 날씨가 정말 좋았다. 친구들과 공원에서 산책을 즐겼다.',
      'hasImage': true,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'text': '새로운 책을 읽기 시작했다. 흥미로운 내용이 많아서 기대된다.',
      'hasImage': false,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'text': '맛있는 파스타를 만들어 먹었다. 요리하는 재미를 새롭게 발견했다.',
      'hasImage': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('타임라인'),
        centerTitle: true,
      ),
      body: _records.isEmpty
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final record = _records[index];
                final date = record['date'] as DateTime;
                final text = record['text'] as String;
                final hasImage = record['hasImage'] as bool;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              DateFormat('MM월 dd일').format(date),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('E').format(date),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        if (hasImage)
                          Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        
                        if (hasImage) const SizedBox(height: 12),
                        
                        Text(
                          text,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}