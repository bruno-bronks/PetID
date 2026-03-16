import 'package:flutter/material.dart';
import '../services/record_service.dart';

class AddRecordScreen extends StatefulWidget {
  final int petId;
  
  const AddRecordScreen({super.key, required this.petId});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recordService = RecordService();
  
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _type = RecordType.visit;
  DateTime _eventDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _recordService.createRecord(
        petId: widget.petId,
        type: _type,
        title: _titleController.text.trim(),
        eventDate: _eventDate.toIso8601String().split('T').first,
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro adicionado com sucesso!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Registro'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tipo
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo *',
                prefixIcon: Icon(Icons.category),
              ),
              items: RecordType.all.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(RecordType.label(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _type = value!);
              },
            ),
            const SizedBox(height: 16),
            
            // Título
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título *',
                prefixIcon: const Icon(Icons.title),
                hintText: _getHintForType(_type),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite um título';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Data
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                'Data: ${_eventDate.day}/${_eventDate.month}/${_eventDate.year}',
              ),
              trailing: TextButton(
                onPressed: _selectDate,
                child: const Text('Alterar'),
              ),
            ),
            const SizedBox(height: 16),
            
            // Notas
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            
            // Botão salvar
            ElevatedButton(
              onPressed: _isLoading ? null : _saveRecord,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Salvar Registro'),
            ),
          ],
        ),
      ),
    );
  }

  String _getHintForType(String type) {
    switch (type) {
      case RecordType.vaccine:
        return 'Ex: Vacina V10, Antirrábica';
      case RecordType.visit:
        return 'Ex: Consulta de rotina';
      case RecordType.diagnosis:
        return 'Ex: Dermatite alérgica';
      case RecordType.medication:
        return 'Ex: Vermífugo Drontal';
      case RecordType.exam:
        return 'Ex: Hemograma completo';
      case RecordType.procedure:
        return 'Ex: Castração, Limpeza dentária';
      case RecordType.allergy:
        return 'Ex: Alergia a frango';
      default:
        return '';
    }
  }
}

