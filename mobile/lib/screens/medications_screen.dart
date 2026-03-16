import 'package:flutter/material.dart';
import '../services/medication_service.dart';

class MedicationsScreen extends StatefulWidget {
  final int petId;

  const MedicationsScreen({super.key, required this.petId});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final _medicationService = MedicationService();
  List<Medication> _medications = [];
  bool _isLoading = true;
  bool _showActiveOnly = true;

  static const _purple = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    try {
      final meds = await _medicationService.listMedications(
        widget.petId,
        activeOnly: _showActiveOnly,
      );
      if (mounted) {
        setState(() {
          _medications = meds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddEditDialog([Medication? med]) async {
    final nameController = TextEditingController(text: med?.name ?? '');
    final dosageController = TextEditingController(text: med?.dosage ?? '');
    final frequencyController = TextEditingController(text: med?.frequency ?? '');
    final instructionsController = TextEditingController(text: med?.instructions ?? '');
    final notesController = TextEditingController(text: med?.notes ?? '');
    final prescribedByController = TextEditingController(text: med?.prescribedBy ?? '');

    DateTime startDate = med?.startDate ?? DateTime.now();
    DateTime? endDate = med?.endDate;
    bool reminderEnabled = med?.reminderEnabled ?? true;
    bool isContinuous = med?.endDate == null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.medication, color: _purple, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                med == null ? 'Novo Medicamento' : 'Editar Medicamento',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogField(nameController, 'Nome do Medicamento *', Icons.medication),
                const SizedBox(height: 12),
                _buildDialogField(dosageController, 'Dosagem', Icons.format_list_numbered,
                    hint: 'Ex: 1 comprimido, 5ml'),
                const SizedBox(height: 12),
                _buildDialogField(frequencyController, 'Frequência', Icons.schedule,
                    hint: 'Ex: 2x ao dia, a cada 8h'),
                const SizedBox(height: 12),
                _buildDialogField(instructionsController, 'Instruções', Icons.info_outline,
                    maxLines: 2),
                const SizedBox(height: 16),
                // Data de início
                _buildDateTile(
                  'Data de Início',
                  startDate,
                  Icons.calendar_today,
                  () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setDialogState(() => startDate = date);
                  },
                ),
                // Uso contínuo
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: const Text('Uso contínuo', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Sem data de término', style: TextStyle(fontSize: 12)),
                    value: isContinuous,
                    activeColor: _purple,
                    onChanged: (value) {
                      setDialogState(() {
                        isContinuous = value;
                        if (value) {
                          endDate = null;
                        } else {
                          endDate = DateTime.now().add(const Duration(days: 7));
                        }
                      });
                    },
                  ),
                ),
                if (!isContinuous)
                  _buildDateTile(
                    'Data de Término',
                    endDate ?? DateTime.now().add(const Duration(days: 7)),
                    Icons.event,
                    () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: startDate,
                        lastDate: DateTime(2030),
                      );
                      if (date != null) setDialogState(() => endDate = date);
                    },
                  ),
                const SizedBox(height: 4),
                // Lembrete
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: const Text('Lembrete', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Notificações de horário', style: TextStyle(fontSize: 12)),
                    value: reminderEnabled,
                    activeColor: _purple,
                    onChanged: (value) => setDialogState(() => reminderEnabled = value),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDialogField(prescribedByController, 'Prescrito por', Icons.person,
                    hint: 'Nome do veterinário'),
                const SizedBox(height: 12),
                _buildDialogField(notesController, 'Observações', Icons.notes, maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nome é obrigatório')),
                  );
                  return;
                }
                try {
                  if (med == null) {
                    await _medicationService.createMedication(
                      petId: widget.petId,
                      name: nameController.text,
                      startDate: startDate,
                      dosage: dosageController.text.isEmpty ? null : dosageController.text,
                      frequency: frequencyController.text.isEmpty ? null : frequencyController.text,
                      instructions: instructionsController.text.isEmpty ? null : instructionsController.text,
                      endDate: isContinuous ? null : endDate,
                      reminderEnabled: reminderEnabled,
                      notes: notesController.text.isEmpty ? null : notesController.text,
                      prescribedBy: prescribedByController.text.isEmpty ? null : prescribedByController.text,
                    );
                  } else {
                    await _medicationService.updateMedication(
                      petId: widget.petId,
                      medicationId: med.id,
                      name: nameController.text,
                      startDate: startDate,
                      dosage: dosageController.text.isEmpty ? null : dosageController.text,
                      frequency: frequencyController.text.isEmpty ? null : frequencyController.text,
                      instructions: instructionsController.text.isEmpty ? null : instructionsController.text,
                      endDate: isContinuous ? null : endDate,
                      reminderEnabled: reminderEnabled,
                      notes: notesController.text.isEmpty ? null : notesController.text,
                      prescribedBy: prescribedByController.text.isEmpty ? null : prescribedByController.text,
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
      ),
    );

    if (result == true) _loadMedications();
  }

  Widget _buildDialogField(
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDateTile(String title, DateTime date, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: _purple, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(_formatDate(date), style: const TextStyle(fontSize: 14)),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _logMedication(Medication med, {bool skipped = false}) async {
    String? skipReason;

    if (skipped) {
      skipReason = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Motivo'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Por que o medicamento foi pulado?',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      );
      if (skipReason == null) return;
    }

    try {
      await _medicationService.logMedication(
        petId: widget.petId,
        medicationId: med.id,
        administeredAt: DateTime.now(),
        skipped: skipped,
        skipReason: skipReason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(skipped ? Icons.skip_next : Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(skipped ? 'Medicamento pulado' : '${med.name} registrado!'),
            ],
          ),
          backgroundColor: skipped ? Colors.orange : Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _toggleActive(Medication med) async {
    try {
      await _medicationService.updateMedication(
        petId: widget.petId,
        medicationId: med.id,
        isActive: !med.isActive,
      );
      _loadMedications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Medicamentos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                _showActiveOnly ? 'Ativos' : 'Todos',
                style: TextStyle(
                  fontSize: 12,
                  color: _showActiveOnly ? _purple : Colors.grey.shade700,
                ),
              ),
              selected: _showActiveOnly,
              onSelected: (value) {
                setState(() => _showActiveOnly = value);
                _loadMedications();
              },
              selectedColor: _purple.withValues(alpha: 0.1),
              checkmarkColor: _purple,
              side: BorderSide(color: _showActiveOnly ? _purple : Colors.grey.shade300),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _purple))
          : _medications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: _purple,
                  onRefresh: _loadMedications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _medications.length,
                    itemBuilder: (context, index) => _buildMedicationCard(_medications[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
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
            child: Icon(Icons.medication, size: 52, color: _purple.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhum medicamento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione os medicamentos do seu pet\npara controlar os horários',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Medicamento'),
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

  Widget _buildMedicationCard(Medication med) {
    final isExpired = med.isExpired;
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (!med.isActive) {
      statusColor = Colors.grey;
      statusLabel = 'Pausado';
      statusIcon = Icons.pause_circle;
    } else if (isExpired) {
      statusColor = Colors.red;
      statusLabel = 'Encerrado';
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.green;
      statusLabel = 'Ativo';
      statusIcon = Icons.check_circle;
    }

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
        onTap: () => _showAddEditDialog(med),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.medication, color: statusColor, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: !med.isActive ? Colors.grey : Colors.black87,
                            decoration: !med.isActive ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (med.dosage != null || med.frequency != null)
                          Text(
                            [med.dosage, med.frequency].where((e) => e != null).join(' • '),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(
                              med.isActive ? Icons.pause : Icons.play_arrow,
                              color: med.isActive ? Colors.orange : Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(med.isActive ? 'Pausar' : 'Retomar'),
                          ],
                        ),
                        onTap: () => _toggleActive(med),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Período
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      med.isContinuous
                          ? 'Uso contínuo desde ${_formatDate(med.startDate)}'
                          : '${_formatDate(med.startDate)} até ${_formatDate(med.endDate!)}',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                    if (med.isContinuous) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Contínuo',
                          style: TextStyle(fontSize: 10, color: _purple, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (med.prescribedBy != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      'Dr. ${med.prescribedBy}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ],
              if (med.instructions != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          med.instructions!,
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Ações rápidas
              if (med.isActive) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _logMedication(med),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Administrar', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _logMedication(med, skipped: true),
                      icon: const Icon(Icons.skip_next, size: 16),
                      label: const Text('Pular', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
