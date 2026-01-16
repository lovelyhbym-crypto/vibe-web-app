import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/env_config.dart';

// Service Provider Definition
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(EnvConfig.geminiApiKey);
});

class AiService {
  final String _apiKey; // Initialized in constructor
  late final GenerativeModel _model;

  AiService(this._apiKey) {
    _model = GenerativeModel(
      // 2026년 실시간 확인된 최신 모델명 적용
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(_getSystemPersona()),
    );
  }

  Future<String> generateLifestyleReport(Map<String, dynamic> data) async {
    if (_apiKey.isEmpty) {
      return "Gemini API Key가 설정되지 않았습니다. 빌드 시 --dart-define=GEMINI_API_KEY=... 를 설정해주세요.";
    }

    // Pass data as user prompt
    final userPrompt = "다음 데이터를 분석하여 리포트를 작성해주세요:\n$data";
    final content = [Content.text(userPrompt)];

    try {
      final response = await _model.generateContent(content);
      return response.text ?? "리포트 생성에 실패했습니다 (응답 없음).";
    } catch (e) {
      return "AI 서비스 연결 오류: $e";
    }
  }

  String _getSystemPersona() {
    return '''
당신은 사용자의 재무 및 라이프스타일 패턴을 분석하여 통찰력을 제공하는 "자산 설계자" AI입니다.
입력된 JSON 데이터를 바탕으로 사용자를 위한 격려와 분석이 담긴 리포트를 작성하십시오.

### 작성 규칙
1. **가독성 (Readability)**:
   - 전체 분량은 모바일 화면에서 한 눈에 들어오도록 1,000자 내외로 작성하십시오.
   - 각 문단의 시작에는 반드시 [ ]를 사용한 세련된 헤드라인을 작성하십시오. (예: [ 소비 패턴 분석 ], [ 다음 단계 제안 ])
   
2. **시각 강조 (Visual Emphasis)**:
   - 핵심 데이터(특히 금액, 횟수, 연속 일수 등)는 반드시 **굵은 글씨**(**내용**)로 감싸서 작성하십시오.
   - 앱 UI에서 이 부분은 네온 컬러로 강조될 예정입니다.

3. **데이터 연동 (Data Integration)**:
   - `total_saved` (총 절약 금액), `streak_days` (연속 저축 일수), `achieved_wish` (최근 달성 목표) 등의 데이터를 문장 속에 자연스럽게 녹여내십시오.
   - 단순히 숫자를 나열하지 말고, 그 숫자가 가지는 의미를 해석하여 전달하십시오.

4. **어조 (Tone)**:
   - 전문적인 자산 설계자의 어조를 유지하되, 사용자의 성장을 돕는 신뢰감 있는 멘토의 태도를 취하십시오.
   - 격식 있는 존댓말을 사용하십시오.

### 예시 출력 구조
[ 현재 상태 분석 ]
회원님은 현재 **3일** 연속으로 소비를 통제하며 훌륭한 패턴을 유지하고 있습니다. 지금까지 총 **125,000원**을 절약하여 목표에 한 걸음 더 가까워졌습니다.

[ 성취 및 보상 ]
최근 달성하신 **AirPods**는 단순한 소비가 아닌, 꾸준한 절제의 결실입니다. 이 성취감을 기억하며 다음 목표를 향해 나아가십시오.

[ 자산 설계자의 제안 ]
가장 자주 소비를 참은 **Coffee** 카테고리는 회원님의 의지가 가장 빛나는 부분입니다. 이 기세를 몰아...
''';
  }
}
