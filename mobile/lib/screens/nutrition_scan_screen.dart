import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';

class NutritionScanScreen extends StatefulWidget {
  const NutritionScanScreen({super.key});

  @override
  State<NutritionScanScreen> createState() => _NutritionScanScreenState();
}

class _NutritionScanScreenState extends State<NutritionScanScreen> {
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

  Future<void> _analyzeNutrition() async {
    if (_image == null) return;

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    try {
      final bytes = await _image!.readAsBytes();
      const prompt = 'Analise este rótulo de ração ou petísco para pets. '
          '1. Identifique os principais ingredientes. '
          '2. Verifique se há ingredientes potencialmente tóxicos ou de baixa qualidade (ex: corantes artificiais, conservantes químicos, excesso de sódio). '
          '3. Avalie se o nível de proteína e gordura parece adequado para um cão/gato adulto médio. '
          '4. Dê uma nota de 1 a 5 para a qualidade do produto. '
          'Responda de forma organizada com tópicos.';
      
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
        title: const Text('IA: Nutrição Inteligente'),
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
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: const Row(
                children: [
                  Icon(Icons.restaurant_menu, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Fotografe a tabela nutricional ou lista de ingredientes da ração para uma análise instantânea da qualidade.',
                      style: TextStyle(fontSize: 13, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
                      Icon(Icons.camera_enhance_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('Escanear Rótulo de Ração', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(_image!.path, height: 200, width: double.infinity, fit: BoxFit.cover),
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
                        onPressed: _isAnalyzing ? null : _analyzeNutrition,
                        icon: _isAnalyzing 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.shield_outlined),
                        label: Text(_isAnalyzing ? 'Analisando...' : 'Verificar Qualidade'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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
                'Análise Nutricional',
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
