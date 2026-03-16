import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import '../models/pet.dart';

class PdfService {
  final ApiService _apiService = ApiService();

  Future<Uint8List> generatePetDossier(Pet pet) async {
    final pdf = pw.Document();

    // Buscar Informações Adicionais (Vacinas, Medicações)
    List<dynamic> vaccines = [];
    List<dynamic> medications = [];
    
    try {
      final vResp = await _apiService.get('/pets/${pet.id}/vaccines');
      vaccines = vResp as List<dynamic>;
      
      final mResp = await _apiService.get('/pets/${pet.id}/medications');
      medications = mResp as List<dynamic>;
    } catch (e) {
      // Ignora erro se não conseguir buscar
      print('Erro ao buscar dados adicionais para o PDF: $e');
    }

    final dateFormat = DateFormat('dd/MM/yyyy');

    // Primeira Página - Capa e Info Básica
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(pet),
            pw.SizedBox(height: 20),
            _buildSectionTitle('Informações Básicas'),
            _buildInfoRow('Nome', pet.name),
            _buildInfoRow('Espécie', pet.speciesLabel),
            _buildInfoRow('Raça', pet.breed ?? 'Não informada'),
            _buildInfoRow('Sexo', pet.sexLabel),
            _buildInfoRow('Nascimento', pet.formattedBirthDate),
            _buildInfoRow('Cor/Pelagem', pet.color ?? 'Não informada'),
            _buildInfoRow('Peso', pet.weight != null ? '${pet.weight} kg' : 'Não informado'),
            if (pet.microchip != null && pet.microchip!.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              _buildInfoRow('Microchip', pet.microchip!),
            ],
            
            pw.SizedBox(height: 30),
            
            // Vacinas
            if (vaccines.isNotEmpty) ...[
              _buildSectionTitle('Registro de Vacinas'),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                headerHeight: 25,
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                },
                headers: ['Vacina', 'Data da Dose', 'Próxima Dose', 'Veterinário'],
                data: vaccines.map((v) {
                  final date = v['date'] != null ? dateFormat.format(DateTime.parse(v['date'])) : '-';
                  final nextDate = v['next_due_date'] != null ? dateFormat.format(DateTime.parse(v['next_due_date'])) : '-';
                  return [
                    v['name'] ?? 'Vacina',
                    date,
                    nextDate,
                    v['veterinarian_name'] ?? '-'
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 30),
            ],

            // Medicações
            if (medications.isNotEmpty) ...[
              _buildSectionTitle('Histórico de Medicações'),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                headerHeight: 25,
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                },
                headers: ['Medicamento', 'Dosagem', 'Início', 'Fim'],
                data: medications.map((m) {
                  final start = m['start_date'] != null ? dateFormat.format(DateTime.parse(m['start_date'])) : '-';
                  final end = m['end_date'] != null ? dateFormat.format(DateTime.parse(m['end_date'])) : 'Contínuo';
                  return [
                    m['name'] ?? 'Medicamento',
                    m['dosage'] ?? '-',
                    start,
                    end
                  ];
                }).toList(),
              ),
            ],
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Gerado via PetID App - Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(Pet pet) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Prontuário Médico - PetID',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#4A148C'), // Purple shade
              ),
            ),
            pw.Text(
              DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
              style: const pw.TextStyle(color: PdfColors.grey600),
            ),
          ],
        ),
        pw.Divider(color: PdfColors.grey400),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#4A148C'),
        ),
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> shareDossier(Pet pet) async {
    final pdfBytes = await generatePetDossier(pet);
    
    // Compartilha ou exibe preview na tela usando o Printing
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Prontuario_${pet.name.toString().replaceAll(' ', '_')}.pdf',
    );
  }
}
