import 'package:flutter/material.dart';

class IotDevice {
  final String name;
  final String type;
  final String status;
  final String lastData;
  final IconData icon;

  IotDevice({
    required this.name,
    required this.type,
    required this.status,
    required this.lastData,
    required this.icon,
  });
}

class IotHubScreen extends StatefulWidget {
  const IotHubScreen({super.key});

  @override
  State<IotHubScreen> createState() => _IotHubScreenState();
}

class _IotHubScreenState extends State<IotHubScreen> {
  final List<IotDevice> _devices = [
    IotDevice(name: 'Coleira PetLink', type: 'GPS & Activity', status: 'Conectado', lastData: '3.420 passos hoje', icon: Icons.watch_outlined),
    IotDevice(name: 'Comedouro Smart', type: 'Feeder', status: 'Conectado', lastData: '150g servidos às 08:00', icon: Icons.restaurant),
    IotDevice(name: 'Fonte de Água', type: 'Water Fountain', status: 'Offline', lastData: 'Nível baixo detectado', icon: Icons.water_drop),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Hub'),
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
              'Dispositivos Inteligentes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sincronize coleiras GPS, comedouros e fontes de água para um monitoramento 360º.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ..._devices.map((device) => _buildDeviceCard(device)),
            
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('PAREAR NOVO DISPOSITIVO'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 40),
            _buildActivityInsight(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(IotDevice device) {
    bool isConnected = device.status == 'Conectado';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isConnected ? Colors.blue.shade50 : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(device.icon, color: isConnected ? Colors.blue : Colors.grey),
        ),
        title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.type, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(device.status, style: TextStyle(fontSize: 11, color: isConnected ? Colors.green : Colors.red)),
                const SizedBox(width: 12),
                Text(device.lastData, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  Widget _buildActivityInsight() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade800]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Insight de Atividade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Com base na sua Coleira PetLink, o gasto calórico de Thor está 15% acima da média. Considere ajustar a porção no Comedouro Smart.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), foregroundColor: Colors.white),
            child: const Text('VER RELATÓRIO COMPLETO'),
          ),
        ],
      ),
    );
  }
}
