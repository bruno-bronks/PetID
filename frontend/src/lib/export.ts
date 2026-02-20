/**
 * Utilitários para exportação de dados
 */

export function downloadCSV<T extends Record<string, unknown>>(data: T[], filename: string) {
    if (data.length === 0) return;

    // Pega as colunas do primeiro objeto
    const headers = Object.keys(data[0]);

    // Cria linhas CSV
    const csvRows = [
        headers.join(','), // Header row
        ...data.map(row =>
            headers.map(header => {
                const value = row[header];
                // Escapa valores com vírgula ou aspas
                if (value === null || value === undefined) return '';
                const stringValue = String(value);
                if (stringValue.includes(',') || stringValue.includes('"') || stringValue.includes('\n')) {
                    return `"${stringValue.replace(/"/g, '""')}"`;
                }
                return stringValue;
            }).join(',')
        )
    ];

    // Cria blob e faz download
    const csvContent = csvRows.join('\n');
    const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' }); // BOM for Excel
    const url = URL.createObjectURL(blob);

    const link = document.createElement('a');
    link.href = url;
    link.download = `${filename}_${new Date().toISOString().split('T')[0]}.csv`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
}

export interface PetExport extends Record<string, unknown> {
    id: number;
    nome: string;
    especie: string;
    raca: string;
    sexo: string;
    data_nascimento: string;
    cor: string;
    microchip: string;
}

export interface VaccineExport {
    pet_nome: string;
    vacina: string;
    data: string;
    veterinario: string;
    clinica: string;
}

export interface MedicationExport {
    pet_nome: string;
    medicamento: string;
    dosagem: string;
    frequencia: string;
    data_inicio: string;
    data_fim: string;
    ativo: string;
}

export function formatPetsForExport(pets: Array<{
    id: number;
    name: string;
    species: string;
    breed: string;
    sex: string;
    birth_date: string | null;
    color: string | null;
    microchip: string | null;
}>): PetExport[] {
    return pets.map(pet => ({
        id: pet.id,
        nome: pet.name,
        especie: pet.species === 'dog' ? 'Cão' : pet.species === 'cat' ? 'Gato' : 'Outro',
        raca: pet.breed || '',
        sexo: pet.sex === 'male' ? 'Macho' : pet.sex === 'female' ? 'Fêmea' : 'Não informado',
        data_nascimento: pet.birth_date || '',
        cor: pet.color || '',
        microchip: pet.microchip || '',
    }));
}
