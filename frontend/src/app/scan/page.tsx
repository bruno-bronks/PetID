'use client';

import { useRef, useState } from 'react';
import Link from 'next/link';
import { Camera, Loader2, Search, PawPrint, Phone, User, ScanFace, ArrowLeft, XCircle, MessageCircle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

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

const speciesLabel: Record<string, string> = {
    dog: '🐶 Cão',
    cat: '🐱 Gato',
    other: '🐾 Outro',
};

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

export default function ScanPage() {
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [preview, setPreview] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);
    const [results, setResults] = useState<SearchResponse | null>(null);
    const [error, setError] = useState<string | null>(null);

    const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        setError(null);
        setResults(null);
        const localUrl = URL.createObjectURL(file);
        setPreview(localUrl);

        setLoading(true);
        try {
            const base64 = await fileToBase64(file);
            const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api'}/biometry/search`, {
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
            setResults(data);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Erro ao processar imagem');
        } finally {
            setLoading(false);
        }
    };

    const reset = () => {
        setPreview(null);
        setResults(null);
        setError(null);
        if (fileInputRef.current) fileInputRef.current.value = '';
    };

    return (
        <div className="min-h-screen bg-gradient-to-b from-purple-50 to-white dark:from-gray-950 dark:to-gray-900">
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

            <main className="container mx-auto px-4 py-12 max-w-2xl">
                <div className="text-center mb-8">
                    <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-primary/10 mb-4">
                        <ScanFace className="h-8 w-8 text-primary" />
                    </div>
                    <h1 className="text-3xl font-bold tracking-tight">Identificar Pet</h1>
                    <p className="text-muted-foreground mt-2">
                        Escaneie o focinho e acesse as informações do pet
                    </p>
                </div>

                <Card>
                    <CardHeader>
                        <CardTitle className="text-lg">Escanear Focinho</CardTitle>
                        <CardDescription>
                            Tire uma foto do focinho. O sistema compara com a base de dados e retorna as informações do pet.
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
                                    {loading && (
                                        <div className="absolute inset-0 flex items-center justify-center bg-black/50 rounded-lg">
                                            <div className="text-center text-white">
                                                <Loader2 className="h-8 w-8 animate-spin mx-auto mb-2" />
                                                <p className="text-sm">Analisando focinho...</p>
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

                                {results && (
                                    <div className="space-y-4">
                                        {results.found ? (
                                            <>
                                                <div className="flex items-center gap-2 text-green-700 bg-green-50 rounded-lg p-3">
                                                    <Search className="h-5 w-5" />
                                                    <span className="font-medium">{results.message}</span>
                                                </div>

                                                <div className="space-y-3">
                                                    {results.results.map((pet) => (
                                                        <div
                                                            key={pet.pet_id}
                                                            className="rounded-lg border bg-white p-4 shadow-sm"
                                                        >
                                                            <div className="flex items-start justify-between">
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
                                                            </div>

                                                            <div className="mt-4 pt-4 border-t space-y-2">
                                                                <div className="flex items-center gap-2 text-sm">
                                                                    <User className="h-4 w-4 text-muted-foreground" />
                                                                    <span>Dono: <strong>{pet.owner_name}</strong></span>
                                                                </div>
                                                                {pet.owner_phone && (
                                                                    <div className="flex items-center gap-2 text-sm">
                                                                        <Phone className="h-4 w-4 text-muted-foreground" />
                                                                        <span>Telefone: <strong>{pet.owner_phone}</strong></span>
                                                                    </div>
                                                                )}
                                                                <div className="flex gap-2 mt-3">
                                                                    {pet.owner_phone && (
                                                                        <>
                                                                            <a
                                                                                href={`tel:${pet.owner_phone.replace(/\D/g, '')}`}
                                                                                className="flex-1 flex items-center justify-center gap-1.5 rounded-lg bg-purple-50 px-3 py-2 text-sm font-medium text-purple-700 hover:bg-purple-100 transition-colors"
                                                                            >
                                                                                <Phone className="h-3.5 w-3.5" />
                                                                                Ligar
                                                                            </a>
                                                                            <a
                                                                                href={`https://wa.me/55${pet.owner_phone.replace(/\D/g, '')}?text=${encodeURIComponent(`Ol\u00e1! Encontrei um pet que pode ser seu. Vi pelo sistema PetID.`)}`}
                                                                                target="_blank"
                                                                                rel="noopener noreferrer"
                                                                                className="flex-1 flex items-center justify-center gap-1.5 rounded-lg bg-green-50 px-3 py-2 text-sm font-medium text-green-700 hover:bg-green-100 transition-colors"
                                                                            >
                                                                                <MessageCircle className="h-3.5 w-3.5" />
                                                                                WhatsApp
                                                                            </a>
                                                                        </>
                                                                    )}
                                                                </div>
                                                                <Link
                                                                    href={`/p/${pet.pet_id}`}
                                                                    className="block text-center text-xs text-purple-600 hover:underline mt-2"
                                                                >
                                                                    Ver perfil completo →
                                                                </Link>
                                                            </div>
                                                        </div>
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
            </main>
        </div>
    );
}
