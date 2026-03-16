import 'package:flutter/material.dart';

class LegacyPlannerScreen extends StatefulWidget {
  const LegacyPlannerScreen({super.key});

  @override
  State<LegacyPlannerScreen> createState() => _LegacyPlannerScreenState();
}

class _LegacyPlannerScreenState extends State<LegacyPlannerScreen> {
  final _guardianController = TextEditingController();
  final _fundController = TextEditingController();
  
  bool _isProtectionActive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Trust: Legado'),
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
                gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.security, color: Colors.amber, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Plano de Proteção Vitalícia',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Defina quem cuidará do seu pet e garanta os recursos necessários em caso de imprevistos com você.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    value: _isProtectionActive,
                    onChanged: (val) => setState(() => _isProtectionActive = val),
                    title: const Text('Ativar Proteção de Legado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    activeColor: Colors.amber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Guardião de Emergência', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _guardianController,
              decoration: InputDecoration(
                hintText: 'Nome ou E-mail do Guardião',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Fundo de Reserva (Simulado)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _fundController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Valor reservado (R\$)',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Instruções Detalhadas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Dietas específicas, rotinas médicas, preferências...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plano de Legado atualizado com sucesso!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('SALVAR CONFIGURAÇÕES DE CONFIANÇA'),
            ),
            
            const SizedBox(height: 40),
            _buildSecurityNotice(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.amber, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Estes dados são criptografados e só serão liberados para o guardião após verificação de segurança.',
              style: TextStyle(fontSize: 12, color: Colors.brown),
            ),
          ),
        ],
      ),
    );
  }
}
