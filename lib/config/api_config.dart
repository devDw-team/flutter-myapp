class ApiConfig {
  // TODO: OpenWeather API 키를 여기에 입력하세요
  // https://openweathermap.org/api 에서 무료로 발급받을 수 있습니다
  static const String openWeatherApiKey = '';
  
  static const String openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  
  static const Map<String, String> weatherConditionKorean = {
    'Clear': '맑음',
    'Clouds': '구름',
    'Rain': '비',
    'Drizzle': '이슬비',
    'Thunderstorm': '천둥번개',
    'Snow': '눈',
    'Mist': '안개',
    'Fog': '짙은 안개',
    'Haze': '연무',
    'Dust': '먼지',
    'Sand': '모래',
    'Ash': '재',
    'Squall': '돌풍',
    'Tornado': '토네이도',
  };
  
  // Gemini API 설정
  // TODO: Gemini API 키를 여기에 입력하세요
  // https://makersuite.google.com/app/apikey 에서 발급받을 수 있습니다
  static const String geminiApiKey = '';
}