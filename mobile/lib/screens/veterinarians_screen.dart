import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/veterinarian_service.dart';

class VeterinariansScreen extends StatefulWidget {
  final int petId;

  const VeterinariansScreen({super.key, required this.petId});

  @override
  State<VeterinariansScreen> createState() => _VeterinariansScreenState();
}

class _VeterinariansScreenState extends State<VeterinariansScreen> {
  final _vetService = VeterinarianService();
  List<Veterinarian> _vets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVets();
  }

  Future<void> _loadVets() async {
    setState(() => _isLoading = true);
    try {
      final vets = await _vetService.listVeterinarians(widget.petId);
      if (mounted) {
        setState(() {
          _vets = vets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddEditDialog([Veterinarian? vet]) async {
    final nameController = TextEditingController(text: vet?.name ?? '');
    final clinicController = TextEditingController(text: vet?.clinicName ?? '');
    final phoneController = TextEditingController(text: vet?.phone ?? '');
    final emailController = TextEditingController(text: vet?.email ?? '');
    final addressController = TextEditingController(text: vet?.address ?? '');
    final specialtyController = TextEditingController(text: vet?.specialty ?? '');
    final notesController = TextEditingController(text: vet?.notes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vet == null ? 'Adicionar Veterinário' : 'Editar Veterinário'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Veterinário *',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: clinicController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Clínica',
                  prefixIcon: Icon(Icons.local_hospital),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Endereço',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Especialidade',
                  prefixIcon: Icon(Icons.medical_services),
                  hintText: 'Ex: Clínico Geral, Dermatologista...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nome é obrigatório')),
                );
                return;
              }

              try {
                if (vet == null) {
                  await _vetService.createVeterinarian(
                    petId: widget.petId,
                    name: nameController.text,
                    clinicName: clinicController.text.isEmpty ? null : clinicController.text,
                    phone: phoneController.text.isEmpty ? null : phoneController.text,
                    email: emailController.text.isEmpty ? null : emailController.text,
                    address: addressController.text.isEmpty ? null : addressController.text,
                    specialty: specialtyController.text.isEmpty ? null : specialtyController.text,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  );
                } else {
                  await _vetService.updateVeterinarian(
                    petId: widget.petId,
                    vetId: vet.id,
                    name: nameController.text,
                    clinicName: clinicController.text.isEmpty ? null : clinicController.text,
                    phone: phoneController.text.isEmpty ? null : phoneController.text,
                    email: emailController.text.isEmpty ? null : emailController.text,
                    address: addressController.text.isEmpty ? null : addressController.text,
                    specialty: specialtyController.text.isEmpty ? null : specialtyController.text,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  );
                }
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: $e')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadVets();
    }
  }

  Future<void> _deleteVet(Veterinarian vet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja remover o veterinário ${vet.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _vetService.deleteVeterinarian(widget.petId, vet.id);
        _loadVets();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veterinário removido'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _callVet(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _emailVet(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    // Tenta abrir no Google Maps primeiro, depois Apple Maps/Browser
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o mapa')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veterinários'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vets.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadVets,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vets.length,
                    itemBuilder: (context, index) => _buildVetCard(_vets[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_hospital, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Nenhum veterinário cadastrado',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione os contatos dos veterinários\ndo seu pet para fácil acesso',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVetCard(Veterinarian vet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAddEditDialog(vet),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.person, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vet.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (vet.clinicName != null)
                          Text(
                            vet.clinicName!,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteVet(vet),
                  ),
                ],
              ),
              if (vet.specialty != null) ...[
                const SizedBox(height: 8),
                Chip(
                  label: Text(vet.specialty!),
                  backgroundColor: Colors.green.shade50,
                  labelStyle: TextStyle(color: Colors.green.shade700, fontSize: 12),
                ),
              ],
              const Divider(height: 24),
              // Ações rápidas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (vet.phone != null)
                    TextButton.icon(
                      onPressed: () => _callVet(vet.phone!),
                      icon: const Icon(Icons.phone, color: Colors.green),
                      label: const Text('Ligar'),
                    ),
                  if (vet.email != null)
                    TextButton.icon(
                      onPressed: () => _emailVet(vet.email!),
                      icon: const Icon(Icons.email, color: Colors.blue),
                      label: const Text('E-mail'),
                    ),
                ],
              ),
              if (vet.address != null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _openMap(vet.address!),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          vet.address!,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Icon(Icons.open_in_new, size: 12, color: Colors.blue.shade700),
                    ],
                  ),
                ),
              ],
              if (vet.notes != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vet.notes!,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
