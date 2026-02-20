'use client';

import { useParams } from 'next/navigation';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { QRCodeSVG } from 'qrcode.react';
import { Printer, ArrowLeft, Loader2, PawPrint, Syringe, Pill, Stethoscope, Fingerprint } from 'lucide-react';
import api from '@/lib/axios';
import { Button } from '@/components/ui/button';

interface Pet {
    id: number;
    name: string;
    species: string;
    breed: string | null;
    birth_date: string | null;
    sex: string | null;
    color: string | null;
    microchip: string | null;
    photo_url: string | null;
    weight: number | null;
    has_biometry?: boolean;
}

interface MedicalRecord {
    id: number;
    type: string;
    title: string;
    event_date: string;
    veterinarian: string | null;
    clinic: string | null;
    notes: string | null;
    next_due_date?: string | null;
}

interface Medication {
    id: number;
    name: string;
    dosage: string;
    frequency: string;
    start_date: string;
    end_date: string | null;
    is_active: boolean;
    prescribed_by: string | null;
}

interface Vet {
    id: number;
    name: string;
    clinic_name: string | null;
    phone: string | null;
    specialty: string | null;
}

const speciesLabel: Record<string, string> = { dog: 'Cão', cat: 'Gato', other: 'Outro' };
const sexLabel: Record<string, string> = { male: 'Macho', female: 'Fêmea', unknown: 'N/I' };
const speciesEmoji: Record<string, string> = { dog: '🐶', cat: '🐱', other: '🐾' };

function calcAge(birthDate: string): string {
    const birth = new Date(birthDate);
    const now = new Date();
    const years = now.getFullYear() - birth.getFullYear();
    const months = now.getMonth() - birth.getMonth();
    const totalMonths = years * 12 + months;
    if (totalMonths < 12) return `${totalMonths} ${totalMonths === 1 ? 'mês' : 'meses'}`;
    const y = Math.floor(totalMonths / 12);
    const m = totalMonths % 12;
    return m > 0 ? `${y} ano${y > 1 ? 's' : ''} e ${m} mês` : `${y} ano${y > 1 ? 's' : ''}`;
}

export default function PetCardPage() {
    const params = useParams();
    const petId = Number(params.id);
    const publicUrl = typeof window !== 'undefined' ? `${window.location.origin}/p/${petId}` : `/p/${petId}`;

    const { data: pet, isLoading: petLoading } = useQuery<Pet>({
        queryKey: ['pet', petId],
        queryFn: async () => (await api.get(`/pets/${petId}`)).data,
    });

    const { data: records, isLoading: recordsLoading } = useQuery<MedicalRecord[]>({
        queryKey: ['records', petId],
        queryFn: async () => (await api.get(`/pets/${petId}/records`)).data,
    });

    const { data: medications } = useQuery<Medication[]>({
        queryKey: ['medications', petId],
        queryFn: async () => (await api.get(`/pets/${petId}/medications`)).data,
    });

    const { data: vets } = useQuery<Vet[]>({
        queryKey: ['veterinarians', petId],
        queryFn: async () => (await api.get(`/pets/${petId}/veterinarians`)).data,
    });

    const vaccines = records?.filter((r) => r.type === 'vaccine') ?? [];
    const activeMeds = medications?.filter((m) => m.is_active) ?? [];

    if (petLoading || recordsLoading) {
        return (
            <div className="flex h-96 items-center justify-center">
                <Loader2 className="h-8 w-8 animate-spin text-gray-400" />
            </div>
        );
    }

    if (!pet) return null;

    return (
        <>
            {/* Print styles */}
            <style>{`
                @media print {
                    .no-print { display: none !important; }
                    body { background: white !important; }
                    .print-card { box-shadow: none !important; border: 1px solid #e5e7eb !important; }
                }
            `}</style>

            {/* Toolbar – hidden on print */}
            <div className="no-print mb-6 flex items-center justify-between">
                <Button variant="ghost" asChild>
                    <Link href={`/pets/${petId}`}>
                        <ArrowLeft className="mr-2 h-4 w-4" />
                        Voltar
                    </Link>
                </Button>
                <Button onClick={() => window.print()}>
                    <Printer className="mr-2 h-4 w-4" />
                    Imprimir / Salvar PDF
                </Button>
            </div>

            {/* Card */}
            <div className="print-card mx-auto max-w-2xl rounded-2xl bg-white shadow-xl overflow-hidden border">
                {/* Header strip */}
                <div className="bg-gradient-to-r from-violet-600 to-purple-700 px-6 py-5 text-white">
                    <div className="flex items-center gap-4">
                        {/* Photo */}
                        <div className="h-20 w-20 rounded-full border-4 border-white/40 overflow-hidden bg-white/20 flex items-center justify-center shrink-0">
                            {pet.photo_url ? (
                                // eslint-disable-next-line @next/next/no-img-element
                                <img src={pet.photo_url} alt={pet.name} className="h-full w-full object-cover" />
                            ) : (
                                <span className="text-4xl">{speciesEmoji[pet.species] ?? '🐾'}</span>
                            )}
                        </div>

                        <div className="flex-1 min-w-0">
                            <h1 className="text-2xl font-bold truncate">{pet.name}</h1>
                            <p className="text-white/80 text-sm">
                                {speciesLabel[pet.species] ?? pet.species}
                                {pet.breed ? ` · ${pet.breed}` : ''}
                            </p>
                            <div className="mt-2 flex flex-wrap gap-2">
                                {pet.microchip && (
                                    <span className="rounded-full bg-white/20 px-2.5 py-0.5 text-xs font-medium">
                                        🔖 {pet.microchip}
                                    </span>
                                )}
                                {pet.has_biometry && (
                                    <span className="rounded-full bg-white/20 px-2.5 py-0.5 text-xs font-medium flex items-center gap-1">
                                        <Fingerprint className="h-3 w-3" /> Biometria
                                    </span>
                                )}
                            </div>
                        </div>

                        {/* QR Code */}
                        <div className="shrink-0 rounded-xl bg-white p-2">
                            <QRCodeSVG value={publicUrl} size={80} />
                        </div>
                    </div>
                </div>

                {/* Body */}
                <div className="p-6 space-y-6">
                    {/* Basic info grid */}
                    <section>
                        <h2 className="text-xs font-semibold uppercase tracking-wider text-gray-400 mb-3">Informações Gerais</h2>
                        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                            {[
                                { label: 'Sexo', value: sexLabel[pet.sex ?? 'unknown'] ?? pet.sex },
                                { label: 'Idade', value: pet.birth_date ? calcAge(pet.birth_date) : '—' },
                                { label: 'Peso', value: pet.weight ? `${pet.weight} kg` : '—' },
                                { label: 'Pelagem', value: pet.color || '—' },
                            ].map(({ label, value }) => (
                                <div key={label} className="rounded-lg bg-gray-50 px-3 py-2">
                                    <p className="text-xs text-gray-400">{label}</p>
                                    <p className="text-sm font-semibold text-gray-800">{value}</p>
                                </div>
                            ))}
                        </div>
                    </section>

                    <hr className="border-gray-100" />

                    {/* Vaccines */}
                    <section>
                        <h2 className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-gray-400 mb-3">
                            <Syringe className="h-3.5 w-3.5" /> Vacinas ({vaccines.length})
                        </h2>
                        {vaccines.length === 0 ? (
                            <p className="text-sm text-gray-400">Nenhuma vacina registrada.</p>
                        ) : (
                            <div className="space-y-1.5">
                                {vaccines.slice(0, 8).map((v) => (
                                    <div key={v.id} className="flex items-center justify-between text-sm">
                                        <div className="flex items-center gap-2">
                                            <div className="h-1.5 w-1.5 rounded-full bg-green-500" />
                                            <span className="font-medium text-gray-800">{v.title}</span>
                                            {v.veterinarian && <span className="text-gray-400 text-xs">· {v.veterinarian}</span>}
                                        </div>
                                        <span className="text-gray-400 text-xs shrink-0">
                                            {new Date(v.event_date).toLocaleDateString('pt-BR')}
                                        </span>
                                    </div>
                                ))}
                                {vaccines.length > 8 && (
                                    <p className="text-xs text-gray-400">+ {vaccines.length - 8} mais...</p>
                                )}
                            </div>
                        )}
                    </section>

                    <hr className="border-gray-100" />

                    {/* Active Medications */}
                    <section>
                        <h2 className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-gray-400 mb-3">
                            <Pill className="h-3.5 w-3.5" /> Medicamentos Ativos ({activeMeds.length})
                        </h2>
                        {activeMeds.length === 0 ? (
                            <p className="text-sm text-gray-400">Sem medicamentos ativos.</p>
                        ) : (
                            <div className="space-y-1.5">
                                {activeMeds.map((m) => (
                                    <div key={m.id} className="flex items-center justify-between text-sm">
                                        <div className="flex items-center gap-2">
                                            <div className="h-1.5 w-1.5 rounded-full bg-purple-500" />
                                            <span className="font-medium text-gray-800">{m.name}</span>
                                            <span className="text-gray-400 text-xs">· {m.dosage} · {m.frequency}</span>
                                        </div>
                                        {m.prescribed_by && (
                                            <span className="text-gray-400 text-xs shrink-0">Dr(a). {m.prescribed_by}</span>
                                        )}
                                    </div>
                                ))}
                            </div>
                        )}
                    </section>

                    {/* Vets */}
                    {vets && vets.length > 0 && (
                        <>
                            <hr className="border-gray-100" />
                            <section>
                                <h2 className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-gray-400 mb-3">
                                    <Stethoscope className="h-3.5 w-3.5" /> Veterinários
                                </h2>
                                <div className="space-y-1.5">
                                    {vets.map((vet) => (
                                        <div key={vet.id} className="flex items-center justify-between text-sm">
                                            <div className="flex items-center gap-2">
                                                <div className="h-1.5 w-1.5 rounded-full bg-blue-400" />
                                                <span className="font-medium text-gray-800">{vet.name}</span>
                                                {vet.specialty && <span className="text-gray-400 text-xs">· {vet.specialty}</span>}
                                            </div>
                                            {vet.phone && (
                                                <span className="text-gray-400 text-xs shrink-0">{vet.phone}</span>
                                            )}
                                        </div>
                                    ))}
                                </div>
                            </section>
                        </>
                    )}

                    <hr className="border-gray-100" />

                    {/* Footer */}
                    <div className="flex items-center justify-between text-xs text-gray-400">
                        <div className="flex items-center gap-1.5">
                            <PawPrint className="h-3.5 w-3.5" />
                            <span>Gerado por <strong className="text-gray-600">PetID</strong> em {new Date().toLocaleDateString('pt-BR')}</span>
                        </div>
                        <span className="font-mono text-gray-300">{publicUrl}</span>
                    </div>
                </div>
            </div>

            {/* Below card hint */}
            <p className="no-print mt-4 text-center text-sm text-muted-foreground">
                Use <kbd className="rounded bg-gray-100 px-1.5 py-0.5 font-mono text-xs">Ctrl+P</kbd> para imprimir ou salvar como PDF
            </p>
        </>
    );
}
