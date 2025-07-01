import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/connectivity_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;

  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    // 네트워크 연결 확인
    final hasInternet = await ConnectivityHelper.checkInternetConnection();
    if (!hasInternet) {
      if (mounted) {
        ConnectivityHelper.showConnectionDialog(context, _handleAuth);
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      print('인증 시도: ${_isSignUp ? "회원가입" : "로그인"} - $email');

      if (_isSignUp) {
        // 회원가입
        final response = await _supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (response.user != null) {
          // 사용자 프로필 생성
          await _createUserProfile(response.user!);
          
          if (mounted) {
            // 이메일 확인이 필요한 경우와 아닌 경우를 구분
            if (response.session == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('회원가입이 완료되었습니다! 이메일을 확인해 주세요.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 5),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('회원가입이 완료되었습니다!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            
            // 회원가입 후 로그인 모드로 전환
            setState(() {
              _isSignUp = false;
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('회원가입에 실패했습니다. 다시 시도해 주세요.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // 로그인
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (mounted) {
          // 로그인 성공 시 메인 화면으로 이동
          Navigator.of(context).pushReplacementNamed('/main');
        }
      }
    } on AuthException catch (e) {
      print('Auth 오류: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getAuthErrorMessage(e.message)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('일반 오류: $e');
      String errorMessage = '오류가 발생했습니다';
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection failed')) {
        errorMessage = '인터넷 연결을 확인해 주세요. Wi-Fi 또는 모바일 데이터가 활성화되어 있는지 확인하세요.';
      } else if (e.toString().contains('Operation not permitted')) {
        errorMessage = '네트워크 접근이 차단되었습니다. 앱을 재시작하거나 네트워크 설정을 확인해 주세요.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = '연결 시간이 초과되었습니다. 잠시 후 다시 시도해 주세요.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '재시도',
              textColor: Colors.white,
              onPressed: () {
                _handleAuth();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createUserProfile(User user) async {
    try {
      // 사용자 프로필이 이미 존재하는지 확인
      final existingProfile = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        // 사용자 프로필 생성 (트랜잭션으로 처리)
        await _supabase.from('user_profiles').insert({
          'user_id': user.id,
          'timezone': 'Asia/Seoul',
          'language': 'ko',
          'settings': {
            'notifications_enabled': true,
            'theme': 'system',
            'backup_enabled': true,
          },
        });

        // 사용자 통계 테이블 초기화
        await _supabase.from('user_statistics').insert({
          'user_id': user.id,
          'total_moments': 0,
          'total_media': 0,
          'current_streak': 0,
          'longest_streak': 0,
          'avg_mood_score': 0.0,
          'monthly_stats': {},
        });
        
        print('사용자 프로필 생성 완료: ${user.id}');
      } else {
        print('기존 프로필 존재: ${user.id}');
      }
    } catch (e) {
      print('프로필 생성 오류: $e');
      // 프로필 생성 실패해도 회원가입은 성공으로 처리
      // 나중에 앱 사용 중에 프로필을 다시 생성할 수 있음
    }
  }

  String _getAuthErrorMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    } else if (message.contains('Email not confirmed')) {
      return '이메일 인증이 필요합니다. 메일함을 확인해 주세요.';
    } else if (message.contains('User already registered')) {
      return '이미 가입된 이메일입니다. 로그인을 시도해 주세요.';
    } else if (message.contains('Password should be at least')) {
      return '비밀번호는 최소 6자 이상이어야 합니다.';
    } else if (message.contains('Invalid email')) {
      return '올바른 이메일 형식을 입력해 주세요.';
    } else if (message.contains('Signup is disabled')) {
      return '현재 회원가입이 비활성화되어 있습니다.';
    } else if (message.contains('Unable to validate email address')) {
      return '이메일 주소를 확인할 수 없습니다.';
    } else if (message.contains('Password is too weak')) {
      return '비밀번호가 너무 약합니다. 더 강한 비밀번호를 사용해 주세요.';
    } else if (message.contains('rate limit')) {
      return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해 주세요.';
    } else {
      return '오류가 발생했습니다: $message';
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 익명 로그인 시도
      final response = await _supabase.auth.signInAnonymously();
      
      // 익명 사용자 프로필 생성
      if (response.user != null) {
        await _createUserProfile(response.user!);
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게스트 로그인에 실패했습니다: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 로고 및 앱 이름
                const Icon(
                  Icons.book,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  'OneMoment+',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '소중한 순간을 기록하세요',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // 이메일 입력
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return '올바른 이메일 형식을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 비밀번호 입력
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: '6자 이상 입력',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 최소 6자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 로그인/회원가입 버튼
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isSignUp ? '회원가입' : '로그인',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // 로그인/회원가입 전환
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                          });
                        },
                  child: Text(
                    _isSignUp ? '이미 계정이 있으신가요? 로그인' : '계정이 없으신가요? 회원가입',
                  ),
                ),
                const SizedBox(height: 24),

                // 구분선
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('또는'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // 게스트 로그인 버튼
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGuestLogin,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('게스트로 시작하기'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}