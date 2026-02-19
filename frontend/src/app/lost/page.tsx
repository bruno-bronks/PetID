'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { PawPrint, MapPin, Loader2, AlertTriangle, Phone, MessageCircle, Navigation } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';

interface LostPetReport {
    id: number;
    pet_id: number | null;
    pet_name: string | null;
    pet_species: string | null;
    pet_breed: string | null;
    pet_photo_url: string | null;
    report_type: 'lost' | 'found';
    status: 'active' | 'resolved';
    description: string;
    city: string | null;
    address: string | null;
    contact_phone: string | null;
    event_date: string;
    created_at: string;
    distance_km: number | null;
}

const speciesEmoji: Record<string, string> = {
    dog: '🐶',
    cat: '🐱',
    other: '🐾',
};

function formatPhone(phone: string): string {
    const digits = phone.replace(/\D/g, '');
    if (digits.length === 11 || digits.length === 10) {
        return `55${digits}`;
    }
    return digits;
}

export default function LostPetsPage() {
    const [location, setLocation] = useState<{ lat: number; lng: number } | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [reports, setReports] = useState<LostPetReport[]>([]);
    const [radius, setRadius] = useState('10');
    const [filter, setFilter] = useState<'all' | 'lost' | 'found'>('all');

    const fetchNearbyPets = async (lat: number, lng: number, radiusKm: number) => {
        setLoading(true);
        setError(null);
        try {
            const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api';
            const res = await fetch(
                `${apiUrl}/public/lost-pets/nearby?latitude=${lat}&longitude=${lng}&radius_km=${radiusKm}`
            );
            if (!res.ok) throw new Error('Erro ao buscar pets');
            const data = await res.json();
            setReports(data);
        } catch {
            setError('Não foi possível carregar os pets perdidos. Tente novamente.');
        } finally {
            setLoading(false);
        }
    };

    const requestLocation = () => {
        if (!navigator.geolocation) {
            setError('Seu navegador não suporta geolocalização');
            return;
        }

        setLoading(true);
        setError(null);

        navigator.geolocation.getCurrentPosition(
            (position) => {
                const { latitude, longitude } = position.coords;
                setLocation({ lat: latitude, lng: longitude });
                fetchNearbyPets(latitude, longitude, parseInt(radius));
            },
            () => {
                setError('Não foi possível obter sua localização. Permita o acesso à localização.');
                setLoading(false);
            }
        );
    };

    useEffect(() => {
        if (location) {
            fetchNearbyPets(location.lat, location.lng, parseInt(radius));
        }
    }, [radius, location]);

    const filteredReports = reports.filter((r) => {
        if (filter === 'all') return true;
        return r.report_type === filter;
    });

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

            <main className="container mx-auto px-4 py-8 max-w-2xl">
                <div className="text-center mb-8">
                    <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-orange-100 dark:bg-orange-900/30 mb-4">
                        <AlertTriangle className="h-8 w-8 text-orange-500" />
                    </div>
                    <h1 className="text-3xl font-bold tracking-tight">Pets Perdidos</h1>
                    <p className="text-muted-foreground mt-2">
                        Encontre pets perdidos perto de você e ajude a reunir famílias
                    </p>
                </div>

                {!location ? (
                    <Card>
                        <CardHeader className="text-center">
                            <CardTitle className="text-lg">Permitir localização</CardTitle>
                            <CardDescription>
                                Para ver pets perdidos próximos, precisamos saber sua localização
                            </CardDescription>
                        </CardHeader>
                        <CardContent className="flex flex-col items-center gap-4">
                            <div className="rounded-full bg-purple-50 dark:bg-purple-900/30 p-6">
                                <Navigation className="h-12 w-12 text-purple-500" />
                            </div>
                            <Button onClick={requestLocation} disabled={loading}>
                                {loading ? (
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                ) : (
                                    <MapPin className="mr-2 h-4 w-4" />
                                )}
                                Usar minha localização
                            </Button>
                            {error && (
                                <p className="text-sm text-red-500 text-center">{error}</p>
                            )}
                        </CardContent>
                    </Card>
                ) : (
                    <div className="space-y-6">
                        {/* Filters */}
                        <div className="flex flex-wrap gap-3 items-center justify-between">
                            <div className="flex items-center gap-2">
                                <span className="text-sm text-muted-foreground">Raio:</span>
                                <Select value={radius} onValueChange={setRadius}>
                                    <SelectTrigger className="w-24 h-8">
                                        <SelectValue />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="5">5 km</SelectItem>
                                        <SelectItem value="10">10 km</SelectItem>
                                        <SelectItem value="25">25 km</SelectItem>
                                        <SelectItem value="50">50 km</SelectItem>
                                        <SelectItem value="100">100 km</SelectItem>
                                    </SelectContent>
                                </Select>
                            </div>
                            <div className="flex gap-2">
                                <Button
                                    size="sm"
                                    variant={filter === 'all' ? 'default' : 'outline'}
                                    onClick={() => setFilter('all')}
                                >
                                    Todos
                                </Button>
                                <Button
                                    size="sm"
                                    variant={filter === 'lost' ? 'destructive' : 'outline'}
                                    onClick={() => setFilter('lost')}
                                >
                                    Perdidos
                                </Button>
                                <Button
                                    size="sm"
                                    variant={filter === 'found' ? 'default' : 'outline'}
                                    onClick={() => setFilter('found')}
                                    className={filter === 'found' ? 'bg-green-600 hover:bg-green-700' : ''}
                                >
                                    Encontrados
                                </Button>
                            </div>
                        </div>

                        {/* Results */}
                        {loading ? (
                            <div className="flex justify-center py-12">
                                <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                            </div>
                        ) : error ? (
                            <Card>
                                <CardContent className="py-12 text-center text-red-500">
                                    {error}
                                </CardContent>
                            </Card>
                        ) : filteredReports.length === 0 ? (
                            <Card>
                                <CardContent className="py-12 text-center">
                                    <PawPrint className="h-12 w-12 mx-auto text-muted-foreground/30 mb-4" />
                                    <p className="text-muted-foreground">
                                        Nenhum pet {filter === 'lost' ? 'perdido' : filter === 'found' ? 'encontrado' : ''} nessa região.
                                    </p>
                                    <p className="text-sm text-muted-foreground mt-1">
                                        Tente aumentar o raio de busca.
                                    </p>
                                </CardContent>
                            </Card>
                        ) : (
                            <div className="space-y-4">
                                <p className="text-sm text-muted-foreground">
                                    {filteredReports.length} resultado(s) em {radius}km
                                </p>
                                {filteredReports.map((report) => (
                                    <Card key={report.id} className="overflow-hidden">
                                        <div className="flex">
                                            {/* Photo */}
                                            <div className="w-28 h-28 bg-gray-100 dark:bg-gray-800 flex-shrink-0 flex items-center justify-center">
                                                {report.pet_photo_url ? (
                                                    // eslint-disable-next-line @next/next/no-img-element
                                                    <img
                                                        src={report.pet_photo_url}
                                                        alt={report.pet_name || 'Pet'}
                                                        className="w-full h-full object-cover"
                                                    />
                                                ) : (
                                                    <span className="text-4xl">
                                                        {speciesEmoji[report.pet_species || ''] || '🐾'}
                                                    </span>
                                                )}
                                            </div>

                                            {/* Info */}
                                            <div className="flex-1 p-4">
                                                <div className="flex items-start justify-between gap-2">
                                                    <div>
                                                        <h3 className="font-semibold">
                                                            {report.pet_name || 'Pet desconhecido'}
                                                        </h3>
                                                        <p className="text-xs text-muted-foreground">
                                                            {report.pet_species && (speciesEmoji[report.pet_species] + ' ')}
                                                            {report.pet_breed || report.pet_species || 'Espécie não informada'}
                                                        </p>
                                                    </div>
                                                    <Badge
                                                        variant={report.report_type === 'lost' ? 'destructive' : 'default'}
                                                        className={report.report_type === 'found' ? 'bg-green-600' : ''}
                                                    >
                                                        {report.report_type === 'lost' ? 'Perdido' : 'Encontrado'}
                                                    </Badge>
                                                </div>

                                                <p className="text-sm text-muted-foreground mt-2 line-clamp-2">
                                                    {report.description}
                                                </p>

                                                <div className="flex items-center gap-4 mt-3 text-xs text-muted-foreground">
                                                    {report.city && (
                                                        <span className="flex items-center gap-1">
                                                            <MapPin className="h-3 w-3" />
                                                            {report.city}
                                                        </span>
                                                    )}
                                                    {report.distance_km !== null && (
                                                        <span className="flex items-center gap-1">
                                                            <Navigation className="h-3 w-3" />
                                                            {report.distance_km} km
                                                        </span>
                                                    )}
                                                </div>

                                                {report.contact_phone && (
                                                    <div className="flex gap-2 mt-3">
                                                        <a
                                                            href={`tel:${report.contact_phone.replace(/\D/g, '')}`}
                                                            className="flex items-center gap-1 text-xs text-purple-600 hover:text-purple-800"
                                                        >
                                                            <Phone className="h-3 w-3" />
                                                            Ligar
                                                        </a>
                                                        <a
                                                            href={`https://wa.me/${formatPhone(report.contact_phone)}?text=${encodeURIComponent(
                                                                report.report_type === 'lost'
                                                                    ? `Olá! Vi o anúncio do pet ${report.pet_name || ''} perdido no PetID.`
                                                                    : `Olá! Vi que você encontrou um pet no PetID.`
                                                            )}`}
                                                            target="_blank"
                                                            rel="noopener noreferrer"
                                                            className="flex items-center gap-1 text-xs text-green-600 hover:text-green-800"
                                                        >
                                                            <MessageCircle className="h-3 w-3" />
                                                            WhatsApp
                                                        </a>
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    </Card>
                                ))}
                            </div>
                        )}

                        <Button
                            variant="outline"
                            className="w-full"
                            onClick={() => fetchNearbyPets(location.lat, location.lng, parseInt(radius))}
                            disabled={loading}
                        >
                            {loading ? (
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                            ) : (
                                <Navigation className="mr-2 h-4 w-4" />
                            )}
                            Atualizar
                        </Button>
                    </div>
                )}

                {/* Info */}
                <div className="mt-12 text-center">
                    <p className="text-sm text-muted-foreground">
                        Perdeu seu pet?{' '}
                        <Link href="/login" className="text-primary hover:underline font-medium">
                            Faça login
                        </Link>{' '}
                        para criar um alerta.
                    </p>
                </div>
            </main>
        </div>
    );
}
