import 'package:flutter/material.dart';

class BloodDonor {
  final String name;
  final String breed;
  final String bloodType;
  final String location;
  final double distance;
  final bool isAvailable;

  BloodDonor({
    required this.name,
    required this.breed,
    required this.bloodType,
    required this.location,
    required this.distance,
    required this.isAvailable,
  });
}

class BloodDonorNetworkScreen extends StatefulWidget {
  const BloodDonorNetworkScreen({super.key});

  @override
  State<BloodDonorNetworkScreen> createState() => _BloodDonorNetworkScreenState();
}

class _BloodDonorNetworkScreenState extends State<BloodDonorNetworkScreen> {
  final List<BloodDonor> _donors = [
    BloodDonor(name: 'Thor', breed: 'Golden Retriever', bloodType: 'DEA 1.1 Negativo', location: 'Moema, SP', distance: 1.2, isAvailable: true),
    BloodDonor(name: 'Luna', breed: 'Labrador', bloodType: 'DEA 1.1 Positivo', location: 'Pinheiros, SP', distance: 3.5, isAvailable: true),
    BloodDonor(name: 'Max', breed: 'Pastor Alemão', bloodType: 'DEA 1.1 Negativo', location: 'Vila Mariana, SP', distance: 4.8, isAvailable: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rede de Doadores'),
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
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Doe Sangue, Salve Vidas. Seja um doador solidário.',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: const Text('CADASTRAR MEU PET COMO DOADOR'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Doadores Próximos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(onPressed: () {}, icon: const Icon(Icons.filter_list), label: const Text('Tipo Sanguíneo')),
              ],
            ),
            const SizedBox(height: 12),
            ..._donors.map((donor) => _buildDonorCard(donor)),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text(
                    'Por que ser doador?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'A doação de sangue pet é fundamental para cirurgias e tratamentos de emergência. '
                    'Um único doador pode salvar até 4 vidas!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonorCard(BloodDonor donor) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets, color: Colors.red),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(donor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${donor.breed} • ${donor.bloodType}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      Text(' ${donor.location} (${donor.distance} km)', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            if (donor.isAvailable)
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                  foregroundColor: Colors.green,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('CONTATO', style: TextStyle(fontSize: 12)),
              )
            else
              const Text('Indisponível', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
