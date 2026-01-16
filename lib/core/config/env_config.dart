class EnvConfig {
  // Fallback key from launch.json to ensure it works even if injection fails
  static const _fallbackGeminiKey = 'AIzaSyCEz5h58Q_9LplzfBLQvJ8981lm0ok3zLg';

  static String get geminiApiKey {
    const key = String.fromEnvironment('GEMINI_API_KEY');
    if (key.isEmpty) {
      return _fallbackGeminiKey;
    }
    return key;
  }
}
