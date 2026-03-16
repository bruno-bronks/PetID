import 'package:flutter/material.dart';

class PrivacyCenterScreen extends StatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> {
  bool _shareHealthWithGuardians = true;
  bool _publicSosEnabled = true;
  bool _anonymizeDataForResearch = false;
  bool _blockchainLedgerPublic = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Privacidade'),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.blue, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'Seus Dados, Seu Controle',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No PetID, a privacidade do seu pet é prioritária. Gerencie quem tem acesso a cada informação.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.blue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSectionHeader('Compartilhamento'),
            _buildPrivacyOption(
              title: 'Saúde com Guardiões',
              subtitle: 'Permite que co-tutores visualizem exames e histórico médico.',
              value: _shareHealthWithGuardians,
              onChanged: (val) => setState(() => _shareHealthWithGuardians = val),
            ),
            _buildPrivacyOption(
              title: 'SOS Comunitário',
              subtitle: 'Torna seu pet visível para a rede local em caso de fuga ativa.',
              value: _publicSosEnabled,
              onChanged: (val) => setState(() => _publicSosEnabled = val),
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Vanguarda e Ledger'),
            _buildPrivacyOption(
              title: 'Blockchain Ledger Público',
              subtitle: 'Torna o hash dos seus registros médicos verificável por terceiros.',
              value: _blockchainLedgerPublic,
              onChanged: (val) => setState(() => _blockchainLedgerPublic = val),
            ),
            _buildPrivacyOption(
              title: 'Contribuição para Ciência',
              subtitle: 'Compartilha dados anônimos para estudos de saúde animal.',
              value: _anonymizeDataForResearch,
              onChanged: (val) => setState(() => _anonymizeDataForResearch = val),
            ),

            const SizedBox(height: 32),
            _buildSecurityInfo(),
            
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preferências de privacidade salvas!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2937),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('SALVAR PREFERÊNCIAS'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPrivacyOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_clock_outlined, size: 20, color: Colors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Todos os seus dados são criptografados de ponta a ponta (AES-256) antes da sincronização.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
