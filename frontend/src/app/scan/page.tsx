'use client';

import { useRef, useState, useCallback, useEffect } from 'react';
import Link from 'next/link';
import {
    Camera,
    Loader2,
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
    Video,
    VideoOff,
    RefreshCw,
    ImageIcon,
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
function formatPhoneForWhatsApp(phone: string): string {
    const digits = phone.replace(/\D/g, '');
    if (digits.length === 11 || digits.length === 10) {
        return `55${digits}`;
    }
    return digits;
}

// === COMPONENT ===
export default function ScanPage() {
    const videoRef = useRef<HTMLVideoElement>(null);
    const canvasRef = useRef<HTMLCanvasElement>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);
    const streamRef = useRef<MediaStream | null>(null);

    const [mode, setMode] = useState<'select' | 'camera' | 'photo'>('select');
    const [cameraActive, setCameraActive] = useState(false);
    const [scanning, setScanning] = useState(false);
    const [loading, setLoading] = useState(false);
    const [loadingProfile, setLoadingProfile] = useState(false);
    const [preview, setPreview] = useState<string | null>(null);
    const [searchResults, setSearchResults] = useState<SearchResponse | null>(null);
    const [selectedPet, setSelectedPet] = useState<PetFullProfile | null>(null);
    const [similarity, setSimilarity] = useState<number>(0);
    const [error, setError] = useState<string | null>(null);
    const [scanStatus, setScanStatus] = useState<string>('');
    const [facingMode, setFacingMode] = useState<'user' | 'environment'>('environment');

    // Cleanup camera on unmount
    useEffect(() => {
        return () => {
            if (streamRef.current) {
                streamRef.current.getTracks().forEach(track => track.stop());
            }
        };
    }, []);

    const startCamera = async () => {
        try {
            setError(null);
            const stream = await navigator.mediaDevices.getUserMedia({
                video: {
                    facingMode: facingMode,
                    width: { ideal: 1280 },
                    height: { ideal: 720 },
                },
            });

            if (videoRef.current) {
                videoRef.current.srcObject = stream;
                streamRef.current = stream;
                setCameraActive(true);
                setMode('camera');
            }
        } catch (err) {
            setError('Não foi possível acessar a câmera. Verifique as permissões.');
            console.error(err);
        }
    };

    const stopCamera = useCallback(() => {
        if (streamRef.current) {
            streamRef.current.getTracks().forEach(track => track.stop());
            streamRef.current = null;
        }
        setCameraActive(false);
        setScanning(false);
    }, []);

    const switchCamera = async () => {
        stopCamera();
        setFacingMode(prev => prev === 'user' ? 'environment' : 'user');
        setTimeout(() => startCamera(), 100);
    };

    const captureAndSearch = useCallback(async () => {
        if (!videoRef.current || !canvasRef.current || loading) return;

        const video = videoRef.current;
        const canvas = canvasRef.current;
        const ctx = canvas.getContext('2d');
        if (!ctx) return;

        // Set canvas size to video size
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;

        // Draw video frame to canvas
        ctx.drawImage(video, 0, 0);

        // Convert to base64
        const dataUrl = canvas.toDataURL('image/jpeg', 0.8);
        const base64 = dataUrl.split(',')[1];

        setLoading(true);
        setScanStatus('Analisando focinho...');

        try {
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

            if (data.found && data.results.length > 0) {
                // Found a match!
                setSearchResults(data);
                stopCamera();
                setPreview(dataUrl);

                // Auto-load profile if high similarity
                const bestMatch = data.results[0];
                if (bestMatch.similarity >= 0.80) {
                    await fetchPetProfile(bestMatch.pet_id, bestMatch.similarity);
                }
            } else {
                setScanStatus('Nenhum pet encontrado. Continue escaneando...');
            }
        } catch (err) {
            console.error(err);
            setScanStatus('Erro na busca. Tentando novamente...');
        } finally {
            setLoading(false);
        }
    }, [loading]);

    // Auto-scan every 2 seconds when camera is active
    useEffect(() => {
        let interval: NodeJS.Timeout;

        if (scanning && cameraActive && !loading && !selectedPet) {
            interval = setInterval(() => {
                captureAndSearch();
            }, 2000);
        }

        return () => {
            if (interval) clearInterval(interval);
        };
    }, [scanning, cameraActive, loading, selectedPet, captureAndSearch]);

    const fetchPetProfile = async (petId: number, matchSimilarity: number) => {
        setLoadingProfile(true);
        try {
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

        const reader = new FileReader();
        reader.onload = async () => {
            const dataUrl = reader.result as string;
            setPreview(dataUrl);
            setMode('photo');

            const base64 = dataUrl.split(',')[1];
            setLoading(true);

            try {
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

                if (data.found && data.results.length > 0 && data.results[0].similarity >= 0.80) {
                    await fetchPetProfile(data.results[0].pet_id, data.results[0].similarity);
                }
            } catch (err) {
                setError(err instanceof Error ? err.message : 'Erro ao processar imagem');
            } finally {
                setLoading(false);
            }
        };
        reader.readAsDataURL(file);
    };

    const reset = () => {
        stopCamera();
        setPreview(null);
        setSearchResults(null);
        setSelectedPet(null);
        setError(null);
        setScanStatus('');
        setMode('select');
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
                {/* Hidden canvas for capture */}
                <canvas ref={canvasRef} className="hidden" />

                {!selectedPet ? (
                    // === SCAN MODE ===
                    <>
                        <div className="text-center mb-8">
                            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-primary/10 mb-4">
                                <ScanFace className="h-8 w-8 text-primary" />
                            </div>
                            <h1 className="text-3xl font-bold tracking-tight">Identificar Pet</h1>
                            <p className="text-muted-foreground mt-2">
                                Escaneie o focinho em tempo real ou envie uma foto
                            </p>
                        </div>

                        {mode === 'select' && (
                            <Card>
                                <CardHeader>
                                    <CardTitle className="text-lg">Escolha como identificar</CardTitle>
                                    <CardDescription>
                                        Use a câmera ao vivo para escanear ou envie uma foto do focinho
                                    </CardDescription>
                                </CardHeader>
                                <CardContent className="space-y-4">
                                    <Button
                                        className="w-full h-24 text-lg"
                                        onClick={startCamera}
                                    >
                                        <Video className="mr-3 h-6 w-6" />
                                        Escanear com Câmera
                                    </Button>

                                    <div className="relative">
                                        <div className="absolute inset-0 flex items-center">
                                            <span className="w-full border-t" />
                                        </div>
                                        <div className="relative flex justify-center text-xs uppercase">
                                            <span className="bg-card px-2 text-muted-foreground">ou</span>
                                        </div>
                                    </div>

                                    <Button
                                        variant="outline"
                                        className="w-full h-16"
                                        onClick={() => fileInputRef.current?.click()}
                                    >
                                        <ImageIcon className="mr-2 h-5 w-5" />
                                        Enviar Foto
                                    </Button>

                                    <input
                                        ref={fileInputRef}
                                        type="file"
                                        accept="image/jpeg,image/png,image/webp"
                                        className="hidden"
                                        onChange={handleFileChange}
                                    />

                                    {error && (
                                        <div className="flex items-center gap-2 rounded-md border border-red-200 bg-red-50 p-4 text-red-700">
                                            <XCircle className="h-5 w-5 shrink-0" />
                                            <p className="text-sm">{error}</p>
                                        </div>
                                    )}
                                </CardContent>
                            </Card>
                        )}

                        {mode === 'camera' && (
                            <Card className="overflow-hidden">
                                <div className="relative">
                                    {/* Video feed */}
                                    <video
                                        ref={videoRef}
                                        autoPlay
                                        playsInline
                                        muted
                                        className="w-full aspect-[4/3] object-cover bg-black"
                                    />

                                    {/* Scanning overlay */}
                                    {scanning && (
                                        <div className="absolute inset-0 pointer-events-none">
                                            {/* Scanner frame */}
                                            <div className="absolute inset-8 border-2 border-white/50 rounded-2xl">
                                                <div className="absolute top-0 left-0 w-8 h-8 border-t-4 border-l-4 border-primary rounded-tl-xl" />
                                                <div className="absolute top-0 right-0 w-8 h-8 border-t-4 border-r-4 border-primary rounded-tr-xl" />
                                                <div className="absolute bottom-0 left-0 w-8 h-8 border-b-4 border-l-4 border-primary rounded-bl-xl" />
                                                <div className="absolute bottom-0 right-0 w-8 h-8 border-b-4 border-r-4 border-primary rounded-br-xl" />
                                            </div>

                                            {/* Scanning line animation */}
                                            <div className="absolute inset-8 overflow-hidden rounded-2xl">
                                                <div className="absolute inset-x-0 h-1 bg-gradient-to-r from-transparent via-primary to-transparent animate-scan" />
                                            </div>
                                        </div>
                                    )}

                                    {/* Loading overlay */}
                                    {loading && (
                                        <div className="absolute inset-0 bg-black/30 flex items-center justify-center">
                                            <div className="bg-white rounded-xl p-4 flex items-center gap-3">
                                                <Loader2 className="h-5 w-5 animate-spin text-primary" />
                                                <span className="text-sm font-medium">Analisando...</span>
                                            </div>
                                        </div>
                                    )}

                                    {/* Camera controls */}
                                    <div className="absolute top-4 right-4 flex gap-2">
                                        <Button
                                            size="icon"
                                            variant="secondary"
                                            className="rounded-full bg-white/80 hover:bg-white"
                                            onClick={switchCamera}
                                        >
                                            <RefreshCw className="h-4 w-4" />
                                        </Button>
                                    </div>
                                </div>

                                <CardContent className="p-4 space-y-4">
                                    {/* Status */}
                                    <div className="text-center">
                                        {scanning ? (
                                            <p className="text-sm text-muted-foreground flex items-center justify-center gap-2">
                                                <span className="relative flex h-2 w-2">
                                                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                                                    <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
                                                </span>
                                                {scanStatus || 'Escaneando... Aponte para o focinho do pet'}
                                            </p>
                                        ) : (
                                            <p className="text-sm text-muted-foreground">
                                                Clique em &quot;Iniciar Scan&quot; para começar
                                            </p>
                                        )}
                                    </div>

                                    {/* Buttons */}
                                    <div className="flex gap-3">
                                        <Button
                                            variant="outline"
                                            className="flex-1"
                                            onClick={reset}
                                        >
                                            <ArrowLeft className="mr-2 h-4 w-4" />
                                            Voltar
                                        </Button>

                                        {!scanning ? (
                                            <Button
                                                className="flex-1"
                                                onClick={() => setScanning(true)}
                                            >
                                                <ScanFace className="mr-2 h-4 w-4" />
                                                Iniciar Scan
                                            </Button>
                                        ) : (
                                            <Button
                                                variant="destructive"
                                                className="flex-1"
                                                onClick={() => setScanning(false)}
                                            >
                                                <VideoOff className="mr-2 h-4 w-4" />
                                                Parar Scan
                                            </Button>
                                        )}
                                    </div>

                                    {/* Manual capture button */}
                                    {cameraActive && (
                                        <Button
                                            variant="secondary"
                                            className="w-full"
                                            onClick={captureAndSearch}
                                            disabled={loading}
                                        >
                                            <Camera className="mr-2 h-4 w-4" />
                                            Capturar Manualmente
                                        </Button>
                                    )}
                                </CardContent>
                            </Card>
                        )}

                        {mode === 'photo' && preview && (
                            <Card>
                                <CardContent className="p-4 space-y-4">
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
                                                        <CheckCircle className="h-5 w-5" />
                                                        <span className="font-medium">{searchResults.message}</span>
                                                    </div>

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
                                                    <p className="font-medium">Pet não encontrado</p>
                                                    <p className="text-sm mt-1">Este pet não está cadastrado no sistema.</p>
                                                </div>
                                            )}
                                        </div>
                                    )}

                                    <div className="flex gap-3">
                                        <Button variant="outline" className="flex-1" onClick={reset}>
                                            <ArrowLeft className="mr-2 h-4 w-4" />
                                            Voltar
                                        </Button>
                                        <Button className="flex-1" onClick={() => fileInputRef.current?.click()}>
                                            <Camera className="mr-2 h-4 w-4" />
                                            Outra foto
                                        </Button>
                                    </div>

                                    <input
                                        ref={fileInputRef}
                                        type="file"
                                        accept="image/jpeg,image/png,image/webp"
                                        className="hidden"
                                        onChange={handleFileChange}
                                    />
                                </CardContent>
                            </Card>
                        )}

                        {/* Tips */}
                        {mode === 'select' && (
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
                                    <p className="text-xs text-muted-foreground">Evite movimentos bruscos</p>
                                </div>
                            </div>
                        )}
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
                                    <Button className="flex-1" onClick={reset}>
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
                    </div>
                )}
            </main>

            {/* CSS for scan animation */}
            <style jsx>{`
                @keyframes scan {
                    0% {
                        top: 0;
                    }
                    50% {
                        top: 100%;
                    }
                    100% {
                        top: 0;
                    }
                }
                .animate-scan {
                    animation: scan 2s ease-in-out infinite;
                }
            `}</style>
        </div>
    );
}
