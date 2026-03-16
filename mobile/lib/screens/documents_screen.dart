import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/document_service.dart';

class DocumentsScreen extends StatefulWidget {
  final int petId;

  const DocumentsScreen({super.key, required this.petId});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _documentService = DocumentService();
  final _imagePicker = ImagePicker();
  List<PetDocument> _documents = [];
  bool _isLoading = true;
  String? _filterType;

  static const _purple = Color(0xFF7C3AED);

  final _documentTypes = [
    {'value': 'vaccination_card', 'label': 'Carteira de Vacinação', 'emoji': '💉'},
    {'value': 'health_certificate', 'label': 'Atestado de Saúde', 'emoji': '📋'},
    {'value': 'exam', 'label': 'Exame', 'emoji': '🔬'},
    {'value': 'prescription', 'label': 'Receita', 'emoji': '📝'},
    {'value': 'other', 'label': 'Outro', 'emoji': '📄'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _documentService.listDocuments(
        widget.petId,
        documentType: _filterType,
      );
      if (mounted) {
        setState(() {
          _documents = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadDocument() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'other';
    DateTime? documentDate;
    DateTime? expiryDate;
    XFile? selectedFile;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.upload_file, color: _purple, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Adicionar Documento',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Selecionar arquivo
                if (selectedFile == null) ...[
                  const Text(
                    'Selecionar arquivo',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPickerButton(
                          'Galeria',
                          Icons.image,
                          Colors.blue,
                          () async {
                            final file = await _imagePicker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (file != null) setBottomState(() => selectedFile = file);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPickerButton(
                          'Câmera',
                          Icons.camera_alt,
                          _purple,
                          () async {
                            final file = await _imagePicker.pickImage(
                              source: ImageSource.camera,
                            );
                            if (file != null) setBottomState(() => selectedFile = file);
                          },
                        ),
                      ),
                    ],
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedFile!.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setBottomState(() => selectedFile = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Título
                _buildBottomField(titleController, 'Título *', Icons.title,
                    hint: 'Ex: Carteira de Vacinação 2024'),
                const SizedBox(height: 12),

                // Tipo
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Documento',
                    prefixIcon: const Icon(Icons.category, color: _purple, size: 20),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  items: _documentTypes.map((type) {
                    return DropdownMenuItem(
                      value: type['value'],
                      child: Text('${type['emoji']} ${type['label']}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setBottomState(() => selectedType = value);
                  },
                ),
                const SizedBox(height: 12),

                // Descrição
                _buildBottomField(descriptionController, 'Descrição', Icons.notes,
                    hint: 'Opcional', maxLines: 2),
                const SizedBox(height: 12),

                // Datas
                Row(
                  children: [
                    Expanded(
                      child: _buildDateButton(
                        'Data do doc.',
                        documentDate,
                        () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setBottomState(() => documentDate = date);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateButton(
                        'Validade',
                        expiryDate,
                        () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) setBottomState(() => expiryDate = date);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Botões
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedFile == null || titleController.text.isEmpty
                            ? null
                            : () async {
                                try {
                                  await _documentService.uploadDocument(
                                    petId: widget.petId,
                                    filePath: selectedFile!.path,
                                    title: titleController.text,
                                    documentType: selectedType,
                                    description: descriptionController.text.isEmpty
                                        ? null
                                        : descriptionController.text,
                                    documentDate: documentDate,
                                    expiryDate: expiryDate,
                                  );
                                  Navigator.pop(context, true);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erro: $e')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Enviar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) _loadDocuments();
  }

  Widget _buildPickerButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _purple, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _purple, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: _purple),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  Text(
                    date != null
                        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                        : 'Opcional',
                    style: TextStyle(
                      fontSize: 12,
                      color: date != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDocument(PetDocument doc) async {
    try {
      final url = await _documentService.getDownloadUrl(widget.petId, doc.id);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir documento: $e')),
      );
    }
  }

  Future<void> _deleteDocument(PetDocument doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja remover "${doc.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _documentService.deleteDocument(widget.petId, doc.id);
        if (!mounted) return;
        _loadDocuments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Documento removido'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _getDocTypeStyle(String type) {
    switch (type) {
      case 'vaccination_card':
        return {'icon': Icons.vaccines, 'color': Colors.green, 'emoji': '💉'};
      case 'health_certificate':
        return {'icon': Icons.verified, 'color': Colors.blue, 'emoji': '📋'};
      case 'exam':
        return {'icon': Icons.biotech, 'color': const Color(0xFF7C3AED), 'emoji': '🔬'};
      case 'prescription':
        return {'icon': Icons.receipt_long, 'color': Colors.orange, 'emoji': '📝'};
      default:
        return {'icon': Icons.description, 'color': Colors.grey, 'emoji': '📄'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Documentos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          PopupMenuButton<String?>(
            icon: Icon(
              Icons.filter_list,
              color: _filterType != null ? _purple : Colors.grey.shade700,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              setState(() => _filterType = value);
              _loadDocuments();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Text('📂', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text('Todos'),
                  ],
                ),
              ),
              ..._documentTypes.map((type) => PopupMenuItem(
                    value: type['value'],
                    child: Row(
                      children: [
                        Text(type['emoji']!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(type['label']!),
                      ],
                    ),
                  )),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _purple))
          : _documents.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: _purple,
                  onRefresh: _loadDocuments,
                  child: Column(
                    children: [
                      if (_filterType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: _purple.withValues(alpha: 0.05),
                          child: Row(
                            children: [
                              Icon(Icons.filter_alt, size: 16, color: _purple),
                              const SizedBox(width: 6),
                              Text(
                                'Filtro: ${_documentTypes.firstWhere((t) => t['value'] == _filterType, orElse: () => {'label': ''})['label']}',
                                style: TextStyle(color: _purple, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  setState(() => _filterType = null);
                                  _loadDocuments();
                                },
                                child: const Icon(Icons.close, size: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _documents.length,
                          itemBuilder: (context, index) => _buildDocumentCard(_documents[index]),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadDocument,
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.folder_open, size: 52, color: _purple.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhum documento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione documentos do seu pet como\ncarteiras de vacinação e atestados',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _uploadDocument,
            icon: const Icon(Icons.upload_file),
            label: const Text('Adicionar Documento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(PetDocument doc) {
    final style = _getDocTypeStyle(doc.documentType);
    final Color color = style['color'] as Color;
    final IconData icon = style['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openDocument(doc),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          doc.documentTypeLabel,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Badges de validade
                  if (doc.isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        'Vencido',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    )
                  else if (doc.isExpiringSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        'Vence em breve',
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade500, size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new, size: 18),
                            SizedBox(width: 8),
                            Text('Abrir'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Excluir', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'open') {
                        _openDocument(doc);
                      } else if (value == 'delete') {
                        _deleteDocument(doc);
                      }
                    },
                  ),
                ],
              ),
              if (doc.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  doc.description!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        doc.fileName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                    if (doc.fileSizeFormatted.isNotEmpty) ...[
                      Text(
                        doc.fileSizeFormatted,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      ),
                    ],
                    if (doc.documentDate != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text(
                        '${doc.documentDate!.day.toString().padLeft(2, '0')}/${doc.documentDate!.month.toString().padLeft(2, '0')}/${doc.documentDate!.year}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              // Abrir botão
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openDocument(doc),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Abrir documento', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
