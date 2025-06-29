import 'package:flutter/material.dart';
import '../../utils/database_setup_helper.dart';
import '../../services/database_migration_service.dart';

class DatabaseAdminScreen extends StatefulWidget {
  const DatabaseAdminScreen({super.key});

  @override
  State<DatabaseAdminScreen> createState() => _DatabaseAdminScreenState();
}

class _DatabaseAdminScreenState extends State<DatabaseAdminScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _lastResult;
  String _selectedOperation = 'check_status';

  final Map<String, String> _operations = {
    'check_status': '데이터베이스 상태 확인',
    'setup_schema': '완전한 스키마 설정',
    'step_by_step': '단계별 테이블 생성',
    'migrate_data': '기존 데이터 마이그레이션',
    'full_migration': '전체 마이그레이션 실행',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('데이터베이스 관리'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 작업 선택
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '작업 선택',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedOperation,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '실행할 작업',
                      ),
                      items: _operations.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedOperation = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 실행 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _executeOperation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
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
                        Text('실행 중...'),
                      ],
                    )
                  : Text(
                      '${_operations[_selectedOperation]} 실행',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // 결과 표시
            if (_lastResult != null) ...[
              const Text(
                '실행 결과',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: _buildResultWidget(_lastResult!),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Expanded(
                child: Center(
                  child: Text(
                    '작업을 선택하고 실행 버튼을 눌러주세요.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _executeOperation() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      Map<String, dynamic> result;

      switch (_selectedOperation) {
        case 'check_status':
          result = await DatabaseSetupHelper.checkDatabaseStatus();
          break;
        case 'setup_schema':
          result = await DatabaseSetupHelper.setupCompleteSchema();
          break;
        case 'step_by_step':
          result = await DatabaseSetupHelper.createTablesStepByStep();
          break;
        case 'migrate_data':
          result = await DatabaseSetupHelper.migrateExistingData();
          break;
        case 'full_migration':
          result = await DatabaseMigrationService.runFullMigration();
          break;
        default:
          result = {'error': 'Unknown operation'};
      }

      setState(() {
        _lastResult = result;
      });

      // 결과에 따른 스낵바 표시
      if (result['status'] == 'success' || result['status'] == 'completed') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('작업이 성공적으로 완료되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result['error'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _lastResult = {'error': e.toString()};
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('예외 발생: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildResultWidget(Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상태 표시
        if (result['status'] != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(result['status']),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '상태: ${result['status']}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 에러 메시지
        if (result['error'] != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오류:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result['error'].toString(),
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 상세 결과
        ...result.entries
            .where((entry) => entry.key != 'status' && entry.key != 'error')
            .map((entry) => _buildResultItem(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildResultItem(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatValue(value),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return Colors.green;
      case 'failed':
      case 'error':
        return Colors.red;
      case 'pending':
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatValue(dynamic value) {
    if (value is Map) {
      return value.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
    } else if (value is List) {
      return value.join('\n');
    } else {
      return value.toString();
    }
  }
}