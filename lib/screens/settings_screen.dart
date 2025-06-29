import 'package:flutter/material.dart';
import 'admin/database_admin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
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
              '데이터',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('백업'),
            subtitle: const Text('데이터를 백업합니다'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('백업 기능은 준비 중입니다.')),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('복원'),
            subtitle: const Text('백업된 데이터를 복원합니다'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('복원 기능은 준비 중입니다.')),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('전체 데이터 삭제'),
            subtitle: const Text('모든 기록을 삭제합니다'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('전체 데이터 삭제'),
                    content: const Text('정말로 모든 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('데이터 삭제 기능은 준비 중입니다.')),
                          );
                        },
                        child: const Text('삭제'),
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
              '개발자 도구',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('데이터베이스 관리'),
            subtitle: const Text('데이터베이스 스키마 설정 및 관리'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DatabaseAdminScreen(),
                ),
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