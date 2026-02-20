'use client';

import { useRef, useState } from 'react';
import Link from 'next/link';
import {
    Camera,
    Loader2,
    Search,
    PawPrint,
    Phone,
    User,
    ScanFace,
    ArrowLeft,
    XCircle,
    MessageCircle,
    Syringe,
    Pill,
    Calendar,
    AlertTriangle,
    CheckCircle,
    Heart,
    QrCode,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';

// === TYPES ===
interface PetResult {
    pet_id: number;
    pet_name: string;
    species: string;
    breed: string | null;
    owner_name: string;
    owner_phone: string | null;
    similarity: number;
    has_contact_permission: boolean;
}

interface SearchResponse {
    found: boolean;
    results: PetResult[];
    message: string;
}

interface VaccinePublic {
    title: string;
    event_date: string;
}

interface MedicationPublic {
    name: string;
    dosage: string | null;
    frequency: string | null;
    is_active: boolean;
}

interface PetFullProfile {
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

// === CONSTANTS ===
const speciesLabel: Record<string, string> = {
    dog: '🐶 Cão',
    cat: '🐱 Gato',
    other: '🐾 Outro',
};

const speciesEmoji: Record<string, string> = {
    dog: '🐶',
    cat: '🐱',
    other: '🐾',
};

const sexLabel: Record<string, string> = {
    male: 'Macho',
    female: 'Fêmea',
    unknown: 'Não informado',
};

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api';

// === HELPERS ===
function fileToBase64(file: File): Promise<string> {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => {
            const result = reader.result as string;
            resolve(result.split(',')[1]);
        };
        reader.onerror = reject;
        reader.readAsDataURL(file);
    });
}

function formatPhoneForWhatsApp(phone: string): string {
    const digits = phone.replace(/\D/g, '');
    if (digits.length === 11 || digits.length === 10) {
        return `55${digits}`;
    }
    return digits;
}

// === COMPONENT ===
export default function ScanPage() {
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [preview, setPreview] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);
    const [loadingProfile, setLoadingProfile] = useState(false);
    const [searchResults, setSearchResults] = useState<SearchResponse | null>(null);
    const [selectedPet, setSelectedPet] = useState<PetFullProfile | null>(null);
    const [similarity, setSimilarity] = useState<number>(0);
    const [error, setError] = useState<string | null>(null);

    const fetchPetProfile = async (petId: number, matchSimilarity: number) => {
        setLoadingProfile(true);
        try {
            // Usa endpoint /identified que retorna telefone completo para contato direto
            const res = await fetch(`${API_URL}/public/pet/${petId}/identified`);
            if (!res.ok) throw new Error('Erro ao carregar perfil');
            const data: PetFullProfile = await res.json();
            setSelectedPet(data);
            setSimilarity(matchSimilarity);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Erro ao carregar perfil do pet');
        } finally {
            setLoadingProfile(false);
        }
    };

    const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        setError(null);
        setSearchResults(null);
        setSelectedPet(null);
        const localUrl = URL.createObjectURL(file);
        setPreview(localUrl);

        setLoading(true);
        try {
            const base64 = await fileToBase64(file);
            const res = await fetch(`${API_URL}/biometry/search`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    image_base64: base64,
                    threshold: 0.75,
                    max_results: 5,
                }),
            });

            if (!res.ok) {
                const data = await res.json().catch(() => ({}));
                throw new Error(data.detail || 'Erro ao buscar');
            }

            const data: SearchResponse = await res.json();
            setSearchResults(data);

            // Se encontrou resultado com alta similaridade, carrega perfil automaticamente
            if (data.found && data.results.length > 0) {
                const bestMatch = data.results[0];
                if (bestMatch.similarity >= 0.85) {
                    await fetchPetProfile(bestMatch.pet_id, bestMatch.similarity);
                }
            }
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Erro ao processar imagem');
        } finally {
            setLoading(false);
        }
    };

    const reset = () => {
        setPreview(null);
        setSearchResults(null);
        setSelectedPet(null);
        setError(null);
        if (fileInputRef.current) fileInputRef.current.value = '';
    };

    const whatsappNumber = selectedPet?.owner_phone ? formatPhoneForWhatsApp(selectedPet.owner_phone) : null;
    const whatsappMessage = selectedPet?.is_lost
        ? `Olá! Encontrei seu pet ${selectedPet.name} e vi o perfil no PetID.`
        : `Olá! Estou entrando em contato sobre o pet ${selectedPet?.name} que identifiquei pelo PetID.`;

    return (
        <div className="min-h-screen bg-gradient-to-b from-purple-100 to-purple-50 dark:from-gray-950 dark:to-gray-900">
            {/* Header */}
            <header className="border-b bg-white/80 dark:bg-gray-950/80 backdrop-blur-sm sticky top-0 z-10">
                <div className="container mx-auto px-4 h-16 flex items-center justify-between">
                    <Link href="/" className="flex items-center gap-2 font-bold text-lg">
                        <PawPrint className="h-6 w-6 text-primary" />
                        <span>PetID</span>
                    </Link>
                    <Link href="/login">
                        <Button variant="outline" size="sm">Entrar</Button>
                    </Link>
                </div>
            </header>

            <main className="container mx-auto px-4 py-8 max-w-2xl">
                {!selectedPet ? (
                    // === SCAN MODE ===
                    <>
                        <div className="text-center mb-8">
                            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-primary/10 mb-4">
                                <ScanFace className="h-8 w-8 text-primary" />
                            </div>
                            <h1 className="text-3xl font-bold tracking-tight">Identificar Pet</h1>
                            <p className="text-muted-foreground mt-2">
                                Escaneie o focinho e acesse a ficha completa do pet
                            </p>
                        </div>

                        <Card>
                            <CardHeader>
                                <CardTitle className="text-lg">Escanear Focinho</CardTitle>
                                <CardDescription>
                                    Tire uma foto do focinho. O sistema compara com a base de dados e retorna a ficha completa.
                                </CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-6">
                                {!preview ? (
                                    /* Upload area */
                                    <div
                                        className="flex flex-col items-center justify-center gap-4 rounded-xl border-2 border-dashed border-muted-foreground/25 p-12 cursor-pointer hover:border-primary/50 hover:bg-primary/5 transition-colors"
                                        onClick={() => fileInputRef.current?.click()}
                                    >
                                        <div className="rounded-full bg-primary/10 p-4">
                                            <Camera className="h-8 w-8 text-primary" />
                                        </div>
                                        <div className="text-center">
                                            <p className="font-medium">Clique para tirar ou enviar foto</p>
                                            <p className="text-sm text-muted-foreground mt-1">
                                                Foto frontal do focinho com boa iluminação
                                            </p>
                                        </div>
                                        <Button>
                                            <Camera className="mr-2 h-4 w-4" />
                                            Tirar Foto
                                        </Button>
                                    </div>
                                ) : (
                                    /* Preview and results */
                                    <div className="space-y-6">
                                        <div className="relative">
                                            {/* eslint-disable-next-line @next/next/no-img-element */}
                                            <img
                                                src={preview}
                                                alt="Foto do focinho"
                                                className="w-full max-h-64 object-cover rounded-lg"
                                            />
                                            {(loading || loadingProfile) && (
                                                <div className="absolute inset-0 flex items-center justify-center bg-black/50 rounded-lg">
                                                    <div className="text-center text-white">
                                                        <Loader2 className="h-8 w-8 animate-spin mx-auto mb-2" />
                                                        <p className="text-sm">
                                                            {loadingProfile ? 'Carregando ficha...' : 'Analisando focinho...'}
                                                        </p>
                                                    </div>
                                                </div>
                                            )}
                                        </div>

                                        {error && (
                                            <div className="flex items-center gap-2 rounded-md border border-red-200 bg-red-50 p-4 text-red-700">
                                                <XCircle className="h-5 w-5 shrink-0" />
                                                <p className="text-sm">{error}</p>
                                            </div>
                                        )}

                                        {searchResults && !selectedPet && (
                                            <div className="space-y-4">
                                                {searchResults.found ? (
                                                    <>
                                                        <div className="flex items-center gap-2 text-green-700 bg-green-50 rounded-lg p-3">
                                                            <Search className="h-5 w-5" />
                                                            <span className="font-medium">{searchResults.message}</span>
                                                        </div>

                                                        <p className="text-sm text-muted-foreground">
                                                            Clique em um resultado para ver a ficha completa:
                                                        </p>

                                                        <div className="space-y-3">
                                                            {searchResults.results.map((pet) => (
                                                                <button
                                                                    key={pet.pet_id}
                                                                    onClick={() => fetchPetProfile(pet.pet_id, pet.similarity)}
                                                                    className="w-full rounded-lg border bg-white p-4 shadow-sm hover:border-primary hover:shadow-md transition-all text-left"
                                                                >
                                                                    <div className="flex items-center justify-between">
                                                                        <div>
                                                                            <div className="flex items-center gap-2">
                                                                                <h3 className="font-semibold text-lg">{pet.pet_name}</h3>
                                                                                <Badge variant="secondary" className="text-xs">
                                                                                    {Math.round(pet.similarity * 100)}% match
                                                                                </Badge>
                                                                            </div>
                                                                            <p className="text-sm text-muted-foreground">
                                                                                {speciesLabel[pet.species] || pet.species}
                                                                                {pet.breed && ` • ${pet.breed}`}
                                                                            </p>
                                                                        </div>
                                                                        <ArrowLeft className="h-5 w-5 rotate-180 text-muted-foreground" />
                                                                    </div>
                                                                </button>
                                                            ))}
                                                        </div>
                                                    </>
                                                ) : (
                                                    <div className="text-center py-8 text-muted-foreground">
                                                        <ScanFace className="h-12 w-12 mx-auto mb-3 opacity-30" />
                                                        <p className="font-medium">Pet não cadastrado</p>
                                                        <p className="text-sm mt-1">Este pet ainda não possui biometria registrada no sistema.</p>
                                                    </div>
                                                )}
                                            </div>
                                        )}

                                        <div className="flex gap-3">
                                            <Button variant="outline" className="flex-1" onClick={reset}>
                                                <ArrowLeft className="mr-2 h-4 w-4" />
                                                Nova busca
                                            </Button>
                                            <Button className="flex-1" onClick={() => fileInputRef.current?.click()}>
                                                <Camera className="mr-2 h-4 w-4" />
                                                Outra foto
                                            </Button>
                                        </div>
                                    </div>
                                )}

                                <input
                                    ref={fileInputRef}
                                    type="file"
                                    accept="image/jpeg,image/png,image/webp"
                                    capture="environment"
                                    className="hidden"
                                    onChange={handleFileChange}
                                />
                            </CardContent>
                        </Card>

                        {/* Tips */}
                        <div className="mt-8 grid gap-4 sm:grid-cols-3">
                            <div className="text-center p-4">
                                <div className="text-2xl mb-2">📸</div>
                                <p className="text-sm font-medium">Foto nítida</p>
                                <p className="text-xs text-muted-foreground">Foco no focinho do pet</p>
                            </div>
                            <div className="text-center p-4">
                                <div className="text-2xl mb-2">💡</div>
                                <p className="text-sm font-medium">Boa iluminação</p>
                                <p className="text-xs text-muted-foreground">Luz natural funciona melhor</p>
                            </div>
                            <div className="text-center p-4">
                                <div className="text-2xl mb-2">🐕</div>
                                <p className="text-sm font-medium">Pet calmo</p>
                                <p className="text-xs text-muted-foreground">Evite fotos desfocadas</p>
                            </div>
                        </div>
                    </>
                ) : (
                    // === PET PROFILE MODE ===
                    <div className="space-y-6">
                        {/* Back button */}
                        <Button variant="ghost" onClick={reset} className="mb-2">
                            <ArrowLeft className="mr-2 h-4 w-4" />
                            Nova identificação
                        </Button>

                        {/* Match banner */}
                        <div className="flex items-center gap-3 rounded-xl bg-green-100 dark:bg-green-900/30 p-4">
                            <CheckCircle className="h-6 w-6 text-green-600" />
                            <div>
                                <p className="font-semibold text-green-800 dark:text-green-200">Pet identificado!</p>
                                <p className="text-sm text-green-700 dark:text-green-300">
                                    Similaridade: {Math.round(similarity * 100)}%
                                </p>
                            </div>
                        </div>

                        {/* Lost banner */}
                        {selectedPet.is_lost && (
                            <div className="flex items-center gap-3 rounded-xl bg-red-500 p-4 text-white animate-pulse">
                                <AlertTriangle className="h-6 w-6" />
                                <div>
                                    <p className="font-bold">ESTE PET ESTÁ PERDIDO!</p>
                                    <p className="text-sm opacity-90">Por favor, entre em contato com o tutor.</p>
                                </div>
                            </div>
                        )}

                        {/* Pet Card */}
                        <Card className="overflow-hidden">
                            {/* Photo header */}
                            <div className="relative h-48 bg-gradient-to-br from-purple-500 to-violet-600 flex items-center justify-center">
                                {selectedPet.photo_url ? (
                                    // eslint-disable-next-line @next/next/no-img-element
                                    <img
                                        src={selectedPet.photo_url}
                                        alt={selectedPet.name}
                                        className="h-full w-full object-cover"
                                    />
                                ) : (
                                    <span className="text-7xl">
                                        {speciesEmoji[selectedPet.species || ''] || '🐾'}
                                    </span>
                                )}
                                <Badge className="absolute top-3 right-3 bg-white/20 backdrop-blur-sm">
                                    <ScanFace className="h-3 w-3 mr-1" />
                                    Biometria ativa
                                </Badge>
                            </div>

                            <CardContent className="p-6 space-y-6">
                                {/* Pet info */}
                                <div className="text-center">
                                    <h1 className="text-3xl font-bold">{selectedPet.name}</h1>
                                    <p className="text-muted-foreground mt-1">
                                        {speciesEmoji[selectedPet.species || '']} {speciesLabel[selectedPet.species || ''] || selectedPet.species}
                                        {selectedPet.breed && ` • ${selectedPet.breed}`}
                                    </p>
                                    {selectedPet.sex && (
                                        <p className="text-sm text-muted-foreground">
                                            {sexLabel[selectedPet.sex] || selectedPet.sex}
                                        </p>
                                    )}
                                </div>

                                <Separator />

                                {/* Tabs */}
                                <Tabs defaultValue="info" className="w-full">
                                    <TabsList className="grid w-full grid-cols-3">
                                        <TabsTrigger value="info">
                                            <User className="h-4 w-4 mr-1" />
                                            Tutor
                                        </TabsTrigger>
                                        <TabsTrigger value="vaccines">
                                            <Syringe className="h-4 w-4 mr-1" />
                                            Vacinas
                                        </TabsTrigger>
                                        <TabsTrigger value="meds">
                                            <Pill className="h-4 w-4 mr-1" />
                                            Medicamentos
                                        </TabsTrigger>
                                    </TabsList>

                                    {/* Owner Tab */}
                                    <TabsContent value="info" className="space-y-4 mt-4">
                                        {selectedPet.owner_name && (
                                            <div className="flex items-center gap-3">
                                                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-purple-100">
                                                    <Heart className="h-5 w-5 text-purple-600" />
                                                </div>
                                                <div>
                                                    <p className="text-xs text-muted-foreground">Tutor</p>
                                                    <p className="font-semibold">{selectedPet.owner_name}</p>
                                                </div>
                                            </div>
                                        )}

                                        {selectedPet.owner_phone && (
                                            <div className="grid grid-cols-2 gap-3">
                                                <a
                                                    href={`tel:${selectedPet.owner_phone.replace(/\D/g, '')}`}
                                                    className="flex items-center justify-center gap-2 rounded-xl bg-purple-100 px-4 py-4 hover:bg-purple-200 transition-colors"
                                                >
                                                    <Phone className="h-5 w-5 text-purple-700" />
                                                    <span className="font-medium text-purple-800">Ligar</span>
                                                </a>
                                                {whatsappNumber && (
                                                    <a
                                                        href={`https://wa.me/${whatsappNumber}?text=${encodeURIComponent(whatsappMessage)}`}
                                                        target="_blank"
                                                        rel="noopener noreferrer"
                                                        className="flex items-center justify-center gap-2 rounded-xl bg-green-100 px-4 py-4 hover:bg-green-200 transition-colors"
                                                    >
                                                        <MessageCircle className="h-5 w-5 text-green-700" />
                                                        <span className="font-medium text-green-800">WhatsApp</span>
                                                    </a>
                                                )}
                                            </div>
                                        )}

                                        <div className="rounded-xl bg-muted/50 p-4">
                                            <div className="flex items-center gap-2 text-sm text-muted-foreground">
                                                <QrCode className="h-4 w-4" />
                                                <span>ID do pet: #{selectedPet.id}</span>
                                            </div>
                                        </div>
                                    </TabsContent>

                                    {/* Vaccines Tab */}
                                    <TabsContent value="vaccines" className="mt-4">
                                        {selectedPet.vaccines.length > 0 ? (
                                            <div className="space-y-3">
                                                {selectedPet.vaccines.map((vaccine, idx) => (
                                                    <div
                                                        key={idx}
                                                        className="flex items-center justify-between rounded-lg border p-3"
                                                    >
                                                        <div className="flex items-center gap-3">
                                                            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-blue-100">
                                                                <Syringe className="h-4 w-4 text-blue-600" />
                                                            </div>
                                                            <span className="font-medium">{vaccine.title}</span>
                                                        </div>
                                                        <div className="flex items-center gap-1 text-sm text-muted-foreground">
                                                            <Calendar className="h-3 w-3" />
                                                            {new Date(vaccine.event_date).toLocaleDateString('pt-BR')}
                                                        </div>
                                                    </div>
                                                ))}
                                            </div>
                                        ) : (
                                            <div className="text-center py-8 text-muted-foreground">
                                                <Syringe className="h-12 w-12 mx-auto mb-2 opacity-30" />
                                                <p>Nenhuma vacina registrada</p>
                                            </div>
                                        )}
                                    </TabsContent>

                                    {/* Medications Tab */}
                                    <TabsContent value="meds" className="mt-4">
                                        {selectedPet.active_medications.length > 0 ? (
                                            <div className="space-y-3">
                                                {selectedPet.active_medications.map((med, idx) => (
                                                    <div
                                                        key={idx}
                                                        className="rounded-lg border border-orange-200 bg-orange-50 p-4"
                                                    >
                                                        <div className="flex items-center gap-2 mb-1">
                                                            <Pill className="h-4 w-4 text-orange-600" />
                                                            <span className="font-semibold text-orange-800">{med.name}</span>
                                                            <Badge variant="outline" className="text-orange-600 border-orange-300">
                                                                Ativo
                                                            </Badge>
                                                        </div>
                                                        <p className="text-sm text-orange-700">
                                                            {med.dosage && `${med.dosage}`}
                                                            {med.dosage && med.frequency && ' · '}
                                                            {med.frequency && `${med.frequency}`}
                                                        </p>
                                                    </div>
                                                ))}
                                            </div>
                                        ) : (
                                            <div className="text-center py-8 text-muted-foreground">
                                                <Pill className="h-12 w-12 mx-auto mb-2 opacity-30" />
                                                <p>Nenhum medicamento ativo</p>
                                            </div>
                                        )}
                                    </TabsContent>
                                </Tabs>

                                <Separator />

                                {/* Footer */}
                                <div className="flex gap-3">
                                    <Link href={`/p/${selectedPet.id}`} className="flex-1">
                                        <Button variant="outline" className="w-full">
                                            <QrCode className="mr-2 h-4 w-4" />
                                            Ver página pública
                                        </Button>
                                    </Link>
                                    <Button className="flex-1" onClick={() => fileInputRef.current?.click()}>
                                        <ScanFace className="mr-2 h-4 w-4" />
                                        Escanear outro
                                    </Button>
                                </div>

                                <p className="text-center text-xs text-muted-foreground">
                                    Identificado pelo{' '}
                                    <Link href="/" className="font-semibold hover:text-primary">
                                        PetID
                                    </Link>
                                </p>
                            </CardContent>
                        </Card>

                        <input
                            ref={fileInputRef}
                            type="file"
                            accept="image/jpeg,image/png,image/webp"
                            capture="environment"
                            className="hidden"
                            onChange={handleFileChange}
                        />
                    </div>
                )}
            </main>
        </div>
    );
}
