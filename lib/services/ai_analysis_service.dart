import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AiAnalysisService {
  static GenerativeModel? _model;
  static final YoutubeExplode _youtube = YoutubeExplode();
  
  // AI 분석 결과 데이터 모델
  static Map<String, String>? _lastAnalysisResult;
  
  // Gemini 모델 초기화
  static void _initializeModel() {
    if (_model == null && ApiConfig.geminiApiKey != 'YOUR_GEMINI_API_KEY') {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: ApiConfig.geminiApiKey,
      );
    }
  }
  
  // URL 타입 확인
  static bool isYouTubeUrl(String url) {
    final youtubePatterns = [
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)'),
    ];
    
    return youtubePatterns.any((pattern) => pattern.hasMatch(url));
  }
  
  // URL 분석 메인 함수
  static Future<Map<String, String>> analyzeUrl(String url) async {
    try {
      _initializeModel();
      
      if (_model == null) {
        throw Exception('Gemini API 키가 설정되지 않았습니다.');
      }
      
      if (isYouTubeUrl(url)) {
        return await _analyzeYouTubeUrl(url);
      } else {
        return await _analyzeWebPage(url);
      }
    } catch (e) {
      print('URL 분석 오류: $e');
      throw Exception('URL 분석에 실패했습니다: $e');
    }
  }
  
  // YouTube URL 분석
  static Future<Map<String, String>> _analyzeYouTubeUrl(String url) async {
    try {
      // YouTube 동영상 정보 추출
      final videoId = _extractYouTubeVideoId(url);
      if (videoId == null) {
        throw Exception('유효하지 않은 YouTube URL입니다.');
      }
      
      final video = await _youtube.videos.get(videoId);
      final videoTitle = video.title;
      final videoDescription = video.description;
      final channelName = video.author;
      final thumbnailUrl = video.thumbnails.highResUrl;
      
      // Gemini에게 분석 요청
      final prompt = '''
다음 YouTube 동영상 정보를 분석해주세요:

제목: $videoTitle
채널: $channelName
설명: ${videoDescription.length > 500 ? videoDescription.substring(0, 500) + '...' : videoDescription}

다음 형식으로 응답해주세요:
제목: [핵심 내용을 담은 간결한 제목]
요약: [동영상의 주요 내용 3-5줄 요약]
태그: [관련 키워드 5개, 쉼표로 구분]
''';
      
      final content = [Content.text(prompt)];
      final geminiResponse = await _model!.generateContent(content);
      
      final analysisResult = _parseGeminiResponse(geminiResponse.text ?? '');
      analysisResult['thumbnail'] = thumbnailUrl;
      analysisResult['channel'] = channelName;
      
      _lastAnalysisResult = analysisResult;
      return analysisResult;
      
    } catch (e) {
      print('YouTube 분석 오류: $e');
      throw Exception('YouTube 동영상 분석에 실패했습니다: $e');
    }
  }
  
  // 일반 웹페이지 분석
  static Future<Map<String, String>> _analyzeWebPage(String url) async {
    try {
      // 웹페이지 내용 가져오기
      final httpResponse = await http.get(Uri.parse(url));
      if (httpResponse.statusCode != 200) {
        throw Exception('웹페이지를 불러올 수 없습니다.');
      }
      
      // HTML에서 텍스트 추출 (간단한 방식)
      String webContent = httpResponse.body;
      
      // 메타 태그에서 정보 추출
      final titleMatch = RegExp(r'<title>(.*?)</title>', caseSensitive: false).firstMatch(webContent);
      final metaDescriptionMatch = RegExp(r'<meta\s+name="description"\s+content="([^"]*)"', caseSensitive: false).firstMatch(webContent);
      
      final pageTitle = titleMatch?.group(1) ?? '';
      final metaDescription = metaDescriptionMatch?.group(1) ?? '';
      
      // 본문 내용 추출 (간소화된 버전 - 실제로는 더 정교한 HTML 파싱 필요)
      webContent = webContent.replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '');
      webContent = webContent.replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '');
      webContent = webContent.replaceAll(RegExp(r'<[^>]+>'), ' ');
      webContent = webContent.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      // 내용이 너무 길면 자르기
      if (webContent.length > 3000) {
        webContent = webContent.substring(0, 3000) + '...';
      }
      
      // Gemini에게 분석 요청
      final prompt = '''
다음 웹페이지 내용을 분석해주세요:

페이지 제목: $pageTitle
메타 설명: $metaDescription
본문 내용: $webContent

다음 형식으로 응답해주세요:
제목: [간결한 제목]
요약: [3-5줄 핵심 내용 요약]
태그: [관련 키워드 5개, 쉼표로 구분]
''';
      
      final content = [Content.text(prompt)];
      final geminiResponse = await _model!.generateContent(content);
      
      final analysisResult = _parseGeminiResponse(geminiResponse.text ?? '');
      _lastAnalysisResult = analysisResult;
      return analysisResult;
      
    } catch (e) {
      print('웹페이지 분석 오류: $e');
      throw Exception('웹페이지 분석에 실패했습니다: $e');
    }
  }
  
  // YouTube 비디오 ID 추출
  static String? _extractYouTubeVideoId(String url) {
    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    
    return null;
  }
  
  // Gemini 응답 파싱
  static Map<String, String> _parseGeminiResponse(String response) {
    final result = <String, String>{};
    
    // 제목 추출
    final titleMatch = RegExp(r'제목:\s*(.+)').firstMatch(response);
    result['title'] = titleMatch?.group(1)?.trim() ?? '';
    
    // 요약 추출
    final summaryMatch = RegExp(r'요약:\s*(.+?)(?=태그:|$)', dotAll: true).firstMatch(response);
    result['summary'] = summaryMatch?.group(1)?.trim() ?? '';
    
    // 태그 추출
    final tagsMatch = RegExp(r'태그:\s*(.+)').firstMatch(response);
    result['tags'] = tagsMatch?.group(1)?.trim() ?? '';
    
    return result;
  }
  
  // 마지막 분석 결과 가져오기
  static Map<String, String>? getLastAnalysisResult() {
    return _lastAnalysisResult;
  }
  
  // 리소스 정리
  static void dispose() {
    _youtube.close();
  }
}