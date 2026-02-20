import { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { PawPrint, Phone, AlertTriangle, Heart, MapPin, MessageCircle, ScanFace, Pill } from 'lucide-react';

// --- Type ---
interface VaccinePublic {
    title: string;
    event_date: string;
}

interface MedicationPublic {
    name: string;
    dosage: string | null;
    frequency: string | null;
}

interface PetPublicProfile {
    id: number;
    name: string;
    species: string | null;
    breed: string | null;
    sex: string | null;
    photo_url: string | null;
    is_lost: boolean;
    owner_name: string | null;
    owner_phone: string | null;
    has_biometry: boolean;
    vaccines: VaccinePublic[];
    active_medications: MedicationPublic[];
}

const BACKEND = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000/api';

async function getPetProfile(id: string): Promise<PetPublicProfile | null> {
    try {
        const res = await fetch(`${BACKEND}/public/pet/${id}`, { cache: 'no-store' });
        if (!res.ok) return null;
        return res.json();
    } catch {
        return null;
    }
}

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
    const { id } = await params;
    const pet = await getPetProfile(id);
    if (!pet) return { title: 'Pet não encontrado – PetID' };
    return {
        title: `${pet.name} – PetID`,
        description: pet.is_lost
            ? `⚠️ ${pet.name} está PERDIDO! Ajude a encontrá-lo.`
            : `Perfil público de ${pet.name} no PetID.`,
    };
}

const speciesEmoji: Record<string, string> = {
    dog: '🐶',
    cat: '🐱',
    other: '🐾',
};

const speciesLabel: Record<string, string> = {
    dog: 'Cão',
    cat: 'Gato',
    other: 'Outro',
};

const sexLabel: Record<string, string> = {
    male: 'Macho',
    female: 'Fêmea',
    unknown: 'Não informado',
};

function formatPhoneForWhatsApp(phone: string): string {
    // Remove tudo exceto números
    const digits = phone.replace(/\D/g, '');
    // Adiciona código do Brasil se não tiver
    if (digits.length === 11 || digits.length === 10) {
        return `55${digits}`;
    }
    return digits;
}

export default async function PublicPetPage({ params }: { params: Promise<{ id: string }> }) {
    const { id } = await params;
    const pet = await getPetProfile(id);
    if (!pet) notFound();

    const emoji = speciesEmoji[pet.species ?? ''] ?? '🐾';
    const whatsappNumber = pet.owner_phone ? formatPhoneForWhatsApp(pet.owner_phone) : null;
    const whatsappMessage = pet.is_lost
        ? `Olá! Encontrei seu pet ${pet.name} e vi o perfil no PetID.`
        : `Olá! Estou entrando em contato sobre o pet ${pet.name} que vi no PetID.`;

    return (
        <main className="min-h-screen bg-gradient-to-b from-slate-900 to-slate-800 flex items-center justify-center p-4">
            <div className="w-full max-w-sm">
                {/* Lost banner */}
                {pet.is_lost && (
                    <div className="mb-4 flex items-center gap-2 rounded-xl bg-red-500 px-4 py-3 text-white font-bold text-center justify-center animate-pulse">
                        <AlertTriangle className="h-5 w-5" />
                        ESTE PET ESTÁ PERDIDO – AJUDE A ENCONTRÁ-LO!
                    </div>
                )}

                {/* Card */}
                <div className="rounded-3xl bg-white shadow-2xl overflow-hidden">
                    {/* Header / photo area */}
                    <div className="relative h-48 bg-gradient-to-br from-purple-500 to-violet-600 flex items-center justify-center">
                        {pet.photo_url ? (
                            // eslint-disable-next-line @next/next/no-img-element
                            <img
                                src={pet.photo_url}
                                alt={pet.name}
                                className="h-full w-full object-cover"
                            />
                        ) : (
                            <div className="flex flex-col items-center gap-2 text-white">
                                <span className="text-7xl">{emoji}</span>
                            </div>
                        )}

                        {/* PetID badge */}
                        <Link
                            href="/"
                            className="absolute top-3 right-3 flex items-center gap-1 rounded-full bg-white/20 backdrop-blur-sm px-3 py-1 text-white text-xs font-semibold hover:bg-white/30 transition-colors"
                        >
                            <PawPrint className="h-3 w-3" />
                            PetID
                        </Link>

                        {/* Biometry badge */}
                        {pet.has_biometry && (
                            <div className="absolute bottom-3 left-3 flex items-center gap-1 rounded-full bg-green-500/90 backdrop-blur-sm px-3 py-1 text-white text-xs font-semibold">
                                <ScanFace className="h-3 w-3" />
                                Biometria ativa
                            </div>
                        )}
                    </div>

                    {/* Body */}
                    <div className="p-6 space-y-5">
                        <div className="text-center">
                            <h1 className="text-3xl font-bold text-gray-900">{pet.name}</h1>
                            <p className="text-gray-500 mt-1">
                                {emoji} {speciesLabel[pet.species ?? ''] ?? pet.species}
                                {pet.breed ? ` • ${pet.breed}` : ''}
                            </p>
                            {pet.sex && (
                                <p className="text-sm text-gray-400">
                                    {sexLabel[pet.sex] ?? pet.sex}
                                </p>
                            )}
                        </div>

                        <hr className="border-gray-100" />

                        {/* Medical Summary */}
                        {(pet.vaccines.length > 0 || pet.active_medications.length > 0) && (
                            <div className="space-y-4">
                                {pet.vaccines.length > 0 && (
                                    <div className="space-y-2">
                                        <p className="text-xs font-semibold uppercase tracking-wider text-gray-400 flex items-center gap-1.5">
                                            <Heart className="h-3 w-3" /> Vacinas recentes
                                        </p>
                                        <div className="space-y-1.5">
                                            {pet.vaccines.map((v, i) => (
                                                <div key={i} className="flex items-center justify-between text-xs">
                                                    <span className="text-gray-700 font-medium">{v.title}</span>
                                                    <span className="text-gray-400">{new Date(v.event_date).toLocaleDateString('pt-BR')}</span>
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                )}

                                {pet.active_medications.length > 0 && (
                                    <div className="space-y-2">
                                        <p className="text-xs font-semibold uppercase tracking-wider text-gray-400 flex items-center gap-1.5">
                                            <Pill className="h-3 w-3" /> Medicamentos em uso
                                        </p>
                                        <div className="space-y-1.5">
                                            {pet.active_medications.map((m, i) => (
                                                <div key={i} className="rounded-lg bg-orange-50 px-2.5 py-2 text-xs">
                                                    <p className="font-semibold text-orange-800">{m.name}</p>
                                                    <p className="text-orange-600 opacity-80">{m.dosage} · {m.frequency}</p>
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                )}
                                <hr className="border-gray-100" />
                            </div>
                        )}

                        {/* Owner info */}
                        {(pet.owner_name || pet.owner_phone) && (
                            <div className="space-y-3">
                                <p className="text-xs font-semibold uppercase tracking-wider text-gray-400">
                                    Informações do Tutor
                                </p>

                                {pet.owner_name && (
                                    <div className="flex items-center gap-3">
                                        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-purple-50">
                                            <Heart className="h-4 w-4 text-purple-500" />
                                        </div>
                                        <div>
                                            <p className="text-xs text-gray-500">Tutor</p>
                                            <p className="font-semibold text-gray-800">{pet.owner_name}</p>
                                        </div>
                                    </div>
                                )}

                                {pet.owner_phone && (
                                    <div className="grid grid-cols-2 gap-2">
                                        <a
                                            href={`tel:${pet.owner_phone.replace(/\D/g, '')}`}
                                            className="flex items-center justify-center gap-2 rounded-xl bg-purple-50 px-4 py-3 hover:bg-purple-100 transition-colors"
                                        >
                                            <Phone className="h-4 w-4 text-purple-600" />
                                            <span className="font-medium text-purple-700 text-sm">Ligar</span>
                                        </a>
                                        {whatsappNumber && (
                                            <a
                                                href={`https://wa.me/${whatsappNumber}?text=${encodeURIComponent(whatsappMessage)}`}
                                                target="_blank"
                                                rel="noopener noreferrer"
                                                className="flex items-center justify-center gap-2 rounded-xl bg-green-50 px-4 py-3 hover:bg-green-100 transition-colors"
                                            >
                                                <MessageCircle className="h-4 w-4 text-green-600" />
                                                <span className="font-medium text-green-700 text-sm">WhatsApp</span>
                                            </a>
                                        )}
                                    </div>
                                )}
                            </div>
                        )}

                        {pet.is_lost && (
                            <div className="rounded-xl bg-red-50 border border-red-200 px-4 py-3 flex items-start gap-3">
                                <MapPin className="h-5 w-5 text-red-500 mt-0.5 shrink-0" />
                                <p className="text-sm text-red-700">
                                    Se você encontrou este pet, por favor entre em contato com o tutor acima. Muito obrigado!
                                </p>
                            </div>
                        )}

                        {/* Biometry CTA */}
                        {pet.has_biometry && (
                            <Link
                                href="/scan"
                                className="flex items-center justify-center gap-2 rounded-xl border border-gray-200 px-4 py-3 hover:bg-gray-50 transition-colors"
                            >
                                <ScanFace className="h-4 w-4 text-gray-500" />
                                <span className="text-sm text-gray-600">Identificar pet pelo focinho</span>
                            </Link>
                        )}

                        {/* Footer */}
                        <p className="text-center text-xs text-gray-300 pt-2">
                            Perfil gerado pelo{' '}
                            <Link href="/" className="font-semibold text-gray-400 hover:text-gray-600">
                                PetID
                            </Link>
                        </p>
                    </div>
                </div>
            </div>
        </main>
    );
}
