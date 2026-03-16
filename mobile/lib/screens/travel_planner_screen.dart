import 'package:flutter/material.dart';

class TravelPlannerScreen extends StatefulWidget {
  const TravelPlannerScreen({super.key});

  @override
  State<TravelPlannerScreen> createState() => _TravelPlannerScreenState();
}

class _TravelPlannerScreenState extends State<TravelPlannerScreen> {
  String _selectedDestination = 'Nacional';
  final List<String> _destinations = ['Nacional', 'Internacional (Europa)', 'Internacional (EUA)', 'América Latina'];

  Map<String, List<String>> get _checklist {
    switch (_selectedDestination) {
      case 'Internacional (Europa)':
        return {
          'Documentação': ['Microchip padrão ISO', 'Vacina Antirrábica em dia', 'Sorologia de Anticorpos (90 dias antes)', 'CVI (Certificado Veterinário Internacional)'],
          'Saúde': ['Vermifugação', 'Tratamento contra Echinococcus', 'Check-up Geral'],
          'Transporte': ['Caixa de transporte padrão IATA', 'Reserva na Cia Aérea'],
        };
      case 'Internacional (EUA)':
        return {
          'Documentação': ['Certificado de Vacinação (CDC)', 'Atestado de Saúde', 'CVI'],
          'Saúde': ['Vacina Antirrábica', 'Microchip'],
          'Transporte': ['Caixa de transporte adequada', 'Checklist da Cia Aérea'],
        };
      default:
        return {
          'Documentação': ['Carteira de Vacinação física', 'Atestado de Saúde (para viagens aéreas)', 'RG do Pet (PetID)'],
          'Saúde': ['Controle de Pulgas e Carrapatos', 'Vermifugação recente'],
          'Transporte': ['Cinto de segurança pet ou caixa', 'Água e petiscos para o trajeto'],
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestor de Viagens'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Para onde vamos viajar?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDestination,
              items: _destinations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (val) => setState(() => _selectedDestination = val!),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ..._checklist.entries.map((category) => _buildCategory(category.key, category.value)),
            
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Checklist salvo no prontuário do pet!')),
                );
              },
              icon: const Icon(Icons.save_alt),
              label: const Text('Exportar Checklist PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
          ),
        ),
        ...items.map((item) => Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: CheckboxListTile(
            value: false,
            onChanged: (val) {},
            title: Text(item, style: const TextStyle(fontSize: 14)),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFF7C3AED),
          ),
        )),
      ],
    );
  }
}
