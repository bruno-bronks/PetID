import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  // NOTA: Em produção, esta chave deve ser armazenada de forma segura (ex: via backend ou secrets)
  // Por enquanto, usaremos um placeholder ou uma chave de ambiente se disponível
  final String _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'YOUR_GEMINI_API_KEY_HERE');
  
  late final GenerativeModel _model;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
      systemInstruction: Content.system('Você é o PetID AI, um assistente virtual especializado em saúde e bem-estar animal. '
          'Seu objetivo é ajudar tutores de pets com dúvidas sobre sintomas, nutrição, comportamento e cuidados gerais. '
          'IMPORTANTE: Você NÃO é um veterinário. Sempre recomende que o tutor consulte um médico veterinário presencialmente para diagnósticos e tratamentos. '
          'Seja empático, profissional e use termos acessíveis. Responda sempre em Português do Brasil.'),
    );
    
    _initialized = true;
  }

  Future<String> getChatResponse(String message, {List<Content>? history}) async {
    if (!_initialized) initialize();

    try {
      final chat = _model.startChat(history: history);
      final response = await chat.sendMessage(Content.text(message));
      return response.text ?? 'Desculpe, não consegui processar sua pergunta agora.';
    } catch (e) {
      return 'Erro ao conversar com a IA: ${e.toString()}';
    }
  }

  Future<String> analyzeImage(Uint8List imageBytes, String prompt) async {
    if (!_initialized) initialize();

    try {
      final content = [
        Content.multi([
          DataPart('image/jpeg', imageBytes),
          TextPart(prompt),
        ])
      ];

      final response = await _model.generateContent(content);
      return response.text ?? 'Não foi possível analisar a imagem.';
    } catch (e) {
      return 'Erro na análise de imagem: ${e.toString()}';
    }
  }
}
