import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';
import '../main.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    
    // 인증 상태 변화 리스너
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _user = data.session?.user;
        });
      }
    });
  }

  Future<void> _checkAuthState() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      setState(() {
        _user = session?.user;
        _isLoading = false;
      });
    } catch (e) {
      print('Auth state check failed: $e');
      setState(() {
        _user = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('OneMoment+ 시작 중...'),
            ],
          ),
        ),
      );
    }

    // 사용자가 로그인되어 있으면 메인 앱 표시
    if (_user != null) {
      return widget.child;
    }

    // 로그인되어 있지 않으면 로그인 화면 표시
    return const LoginScreen();
  }
}