import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';

class HealthExamAnalysisScreen extends StatefulWidget {
  const HealthExamAnalysisScreen({super.key});

  @override
  State<HealthExamAnalysisScreen> createState() => _HealthExamAnalysisScreenState();
}

class _HealthExamAnalysisScreenState extends State<HealthExamAnalysisScreen> {
  final _aiService = AiService();
  final _picker = ImagePicker();
  
  XFile? _image;
  bool _isAnalyzing = false;
  String? _result;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selected = await _picker.pickImage(source: source);
    if (selected != null) {
      setState(() {
        _image = selected;
        _result = null;
      });
    }
  }

  Future<void> _analyzeExam() async {
    if (_image == null) return;

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    try {
      final bytes = await _image!.readAsBytes();
      const prompt = 'Analise esta imagem de um exame veterinário (sangue, urina, raio-x, etc.). '
          'Identifique os valores que estão fora da referência, explique o que cada termo significa de forma simples para um tutor '
          'e sugira perguntas que o tutor pode fazer ao veterinário na próxima consulta. '
          'IMPORTANTE: Comece dizendo que esta análise não substitui o diagnóstico de um profissional.';
      
      final response = await _aiService.analyzeImage(bytes, prompt);
      setState(() => _result = response);
    } catch (e) {
      setState(() => _result = 'Erro ao analisar: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IA: Análise de Exames'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header informativo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tire uma foto nítida do exame do seu pet para que a IA ajude a traduzir os termos médicos.',
                      style: TextStyle(fontSize: 13, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Seletor de Imagem
            if (_image == null)
              GestureDetector(
                onTap: () => _showPickerOptions(),
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
                      Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('Adicionar foto do exame', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      _image!.path,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showPickerOptions(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Trocar Foto'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _analyzeExam,
                        icon: _isAnalyzing 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.analytics_outlined),
                        label: Text(_isAnalyzing ? 'Analisando...' : 'Analisar Exame'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            // Resultado da Análise
            if (_result != null) ...[
              const SizedBox(height: 32),
              const Text(
                'Resultado da Análise',
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

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
