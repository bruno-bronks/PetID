import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceItem {
  final String name;
  final String category;
  final String address;
  final String phone;
  final double rating;
  final String icon;

  ServiceItem({
    required this.name,
    required this.category,
    required this.address,
    required this.phone,
    required this.rating,
    required this.icon,
  });
}

class ServicesDirectoryScreen extends StatefulWidget {
  const ServicesDirectoryScreen({super.key});

  @override
  State<ServicesDirectoryScreen> createState() => _ServicesDirectoryScreenState();
}

class _ServicesDirectoryScreenState extends State<ServicesDirectoryScreen> {
  String _selectedCategory = 'Todos';
  
  final List<String> _categories = [
    'Todos',
    'Pet Shop',
    'Adestradores',
    'Hospedagem',
    'Banho e Tosa',
    'Passeadores',
  ];

  final List<ServiceItem> _services = [
    ServiceItem(
      name: 'Pet Love Store',
      category: 'Pet Shop',
      address: 'Rua das Flores, 123 - Centro',
      phone: '(11) 98888-7777',
      rating: 4.8,
      icon: '🛍️',
    ),
    ServiceItem(
      name: 'Adestrador Amigo',
      category: 'Adestradores',
      address: 'Atendimento em Domicílio',
      phone: '(11) 97777-6666',
      rating: 4.9,
      icon: '🎓',
    ),
    ServiceItem(
      name: 'Hotel do Totó',
      category: 'Hospedagem',
      address: 'Av. Paulista, 1000 - Bela Vista',
      phone: '(11) 96666-5555',
      rating: 4.7,
      icon: '🏨',
    ),
    ServiceItem(
      name: 'Banho & Carinho',
      category: 'Banho e Tosa',
      address: 'Rua Augusta, 500 - Consolação',
      phone: '(11) 95555-4444',
      rating: 4.6,
      icon: '🧼',
    ),
    ServiceItem(
      name: 'Dog Walkers SP',
      category: 'Passeadores',
      address: 'Parque do Ibirapuera e Região',
      phone: '(11) 94444-3333',
      rating: 5.0,
      icon: '🦮',
    ),
  ];

  List<ServiceItem> get _filteredServices {
    if (_selectedCategory == 'Todos') return _services;
    return _services.where((s) => s.category == _selectedCategory).toList();
  }

  Future<void> _openMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        title: const Text('Guia de Serviços', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
      ),
      body: Column(
        children: [
          // Filtros de Categoria
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    selectedColor: const Color(0xFF7C3AED).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF7C3AED),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade200,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Lista de Serviços
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredServices.length,
              itemBuilder: (context, index) {
                final service = _filteredServices[index];
                return _buildServiceCard(service);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ServiceItem service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(service.icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              service.rating.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.category,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF7C3AED).withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          service.address,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _openMaps(service.address),
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('Mapa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          launchUrl(Uri.parse('tel:${service.phone}'));
                        },
                        icon: const Icon(Icons.phone_outlined, size: 16),
                        label: const Text('Ligar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7C3AED),
                          side: const BorderSide(color: Color(0xFF7C3AED)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
