import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';

class BehavioralAnalysisScreen extends StatefulWidget {
  const BehavioralAnalysisScreen({super.key});

  @override
  State<BehavioralAnalysisScreen> createState() => _BehavioralAnalysisScreenState();
}

class _BehavioralAnalysisScreenState extends State<BehavioralAnalysisScreen> {
  final _aiService = AiService();
  final _picker = ImagePicker();
  
  XFile? _video;
  bool _isAnalyzing = false;
  String? _result;

  Future<void> _pickVideo() async {
    final XFile? selected = await _picker.pickVideo(source: ImageSource.gallery);
    if (selected != null) {
      setState(() {
        _video = selected;
        _result = null;
      });
    }
  }

  Future<void> _analyzeBehavior() async {
    if (_video == null) return;

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    try {
      // Nota: Para análise de vídeo real consumindo muitos dados, idealmente enviaríamos frames.
      // Aqui simularemos o envio de um thumbnail ou metadados para o Gemini 1.5 Flash.
      // Em uma implementação real com Gemini 1.5 Pro, enviaríamos o arquivo de vídeo completo.
      final bytes = await _video!.readAsBytes();
      
      const prompt = 'Analise este vídeo (ou frames deste vídeo) de um pet. '
          'Procure por sinais sutis de: '
          '1. Claudicação (mancar) ou rigidez ao andar. '
          '2. Sinais de dor (orelhas caídas, olhar baixo, lambedura excessiva). '
          '3. Ansiedade de separação ou estresse repetitivo. '
          'Descreva o que observou tecnicamente e sugira o nível de urgência para uma consulta veterinária. '
          'IMPORTANTE: Afirme que isso é uma triagem baseada em IA e não substitui o olhar do veterinário.';
      
      final response = await _aiService.analyzeImage(bytes, prompt);
      setState(() => _result = response);
    } catch (e) {
      setState(() => _result = 'Erro na análise de vídeo: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IA: Análise Comportamental'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: const Row(
                children: [
                  Icon(Icons.video_library_outlined, color: Colors.purple),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Grave um vídeo de 10 a 20 segundos do seu pet andando ou em repouso para analisar sinais de dor ou ansiedade.',
                      style: TextStyle(fontSize: 13, color: Colors.purple),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_video == null)
              GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('Selecionar Vídeo para Análise', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.play_circle_fill, size: 64, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Text('Vídeo selecionado: ${_video!.name}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _pickVideo,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Trocar Vídeo'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _analyzeBehavior,
                        icon: _isAnalyzing 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.psychology_outlined),
                        label: Text(_isAnalyzing ? 'Processando...' : 'Analisar Comportamento'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            if (_result != null) ...[
              const SizedBox(height: 32),
              const Text(
                'Relatório Comportamental',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                  ],
                ),
                child: SelectableText(
                  _result!,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
