import 'dart:io';
import 'package:flutter/material.dart';

class ConnectivityHelper {
  static Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static Future<bool> checkSupabaseConnection() async {
    try {
      final result = await InternetAddress.lookup('exmbyyqmhjqsvbyyrmad.supabase.co');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static void showConnectionDialog(BuildContext context, VoidCallback onRetry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('연결 문제'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('네트워크 연결에 문제가 있습니다.'),
              SizedBox(height: 8),
              Text('확인사항:'),
              Text('• Wi-Fi 또는 모바일 데이터 연결 상태'),
              Text('• 방화벽 또는 VPN 설정'),
              Text('• 인터넷 연결 상태'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('닫기'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('재시도'),
            ),
          ],
        );
      },
    );
  }
}