'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import api from '@/lib/axios';
import { Loader2, Plus, Search, PawPrint, QrCode } from 'lucide-react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';

interface Pet {
    id: number;
    name: string;
    breed: string | null;
    species: string;
    sex: string | null;
    birth_date: string | null;
    microchip: string | null;
    is_lost?: boolean;
}

const speciesLabel: Record<string, { label: string; emoji: string; color: string }> = {
    dog: { label: 'Cão', emoji: '🐶', color: 'bg-amber-100 text-amber-700' },
    cat: { label: 'Gato', emoji: '🐱', color: 'bg-purple-100 text-purple-700' },
    other: { label: 'Outro', emoji: '🐾', color: 'bg-gray-100 text-gray-700' },
};

function calcAge(birthDate: string | null): string {
    if (!birthDate) return '—';
    const diff = Date.now() - new Date(birthDate).getTime();
    const months = Math.floor(diff / (1000 * 60 * 60 * 24 * 30));
    if (months < 12) return `${months}m`;
    return `${Math.floor(months / 12)}a`;
}

export default function PetsPage() {
    const router = useRouter();
    const [search, setSearch] = useState('');
    const [speciesFilter, setSpeciesFilter] = useState('all');

    const { data: pets, isLoading, error } = useQuery<Pet[]>({
        queryKey: ['pets'],
        queryFn: async () => (await api.get('/pets/')).data,
    });

    const filtered = pets?.filter((pet) => {
        const matchSearch =
            pet.name.toLowerCase().includes(search.toLowerCase()) ||
            (pet.breed ?? '').toLowerCase().includes(search.toLowerCase());
        const matchSpecies = speciesFilter === 'all' || pet.species === speciesFilter;
        return matchSearch && matchSpecies;
    }) ?? [];

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Meus Pets</h1>
                    <p className="text-muted-foreground mt-1">
                        {pets?.length ?? 0} pet{(pets?.length ?? 0) !== 1 ? 's' : ''} cadastrado{(pets?.length ?? 0) !== 1 ? 's' : ''}
                    </p>
                </div>
                <Button onClick={() => router.push('/pets/new')}>
                    <Plus className="mr-2 h-4 w-4" />
                    Novo Pet
                </Button>
            </div>

            {/* Filters */}
            <div className="flex flex-col gap-3 sm:flex-row">
                <div className="relative flex-1 max-w-sm">
                    <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                    <Input
                        placeholder="Buscar por nome ou raça..."
                        className="pl-9"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                    />
                </div>
                <Select value={speciesFilter} onValueChange={setSpeciesFilter}>
                    <SelectTrigger className="w-[180px]">
                        <SelectValue placeholder="Espécie" />
                    </SelectTrigger>
                    <SelectContent>
                        <SelectItem value="all">Todas as espécies</SelectItem>
                        <SelectItem value="dog">🐶 Cão</SelectItem>
                        <SelectItem value="cat">🐱 Gato</SelectItem>
                        <SelectItem value="other">🐾 Outro</SelectItem>
                    </SelectContent>
                </Select>
            </div>

            {/* Content */}
            {isLoading ? (
                <div className="flex h-48 items-center justify-center">
                    <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                </div>
            ) : error ? (
                <div className="flex h-48 items-center justify-center text-red-500 text-sm">
                    Erro ao carregar pets. Verifique a conexão com o servidor.
                </div>
            ) : filtered.length === 0 ? (
                <div className="flex h-48 flex-col items-center justify-center gap-3 text-muted-foreground">
                    <PawPrint className="h-10 w-10 opacity-30" />
                    {pets?.length === 0 ? (
                        <>
                            <p className="text-sm">Nenhum pet cadastrado ainda.</p>
                            <Button onClick={() => router.push('/pets/new')}>
                                <Plus className="mr-2 h-4 w-4" />
                                Cadastrar primeiro pet
                            </Button>
                        </>
                    ) : (
                        <p className="text-sm">Nenhum pet encontrado para a busca.</p>
                    )}
                </div>
            ) : (
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                    {filtered.map((pet) => {
                        const sp = speciesLabel[pet.species] ?? speciesLabel.other;
                        return (
                            <Card
                                key={pet.id}
                                className="group cursor-pointer transition-all hover:shadow-md hover:-translate-y-0.5"
                                onClick={() => router.push(`/pets/${pet.id}`)}
                            >
                                <CardContent className="p-4">
                                    {/* Avatar + name */}
                                    <div className="flex items-start justify-between">
                                        <div className="flex items-center gap-3">
                                            <div className="flex h-11 w-11 items-center justify-center rounded-full bg-primary/10 text-xl">
                                                {sp.emoji}
                                            </div>
                                            <div>
                                                <p className="font-semibold text-sm leading-tight">{pet.name}</p>
                                                <p className="text-xs text-muted-foreground">{pet.breed || 'Raça não informada'}</p>
                                            </div>
                                        </div>
                                        {pet.is_lost && (
                                            <Badge variant="destructive" className="text-xs shrink-0">
                                                Perdido
                                            </Badge>
                                        )}
                                    </div>

                                    {/* Tags */}
                                    <div className="mt-3 flex flex-wrap gap-1.5">
                                        <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${sp.color}`}>
                                            {sp.label}
                                        </span>
                                        {pet.birth_date && (
                                            <span className="rounded-full px-2 py-0.5 text-xs bg-gray-100 text-gray-600">
                                                {calcAge(pet.birth_date)}
                                            </span>
                                        )}
                                        {pet.microchip && (
                                            <span className="rounded-full px-2 py-0.5 text-xs bg-green-100 text-green-700">
                                                🔖 Chip
                                            </span>
                                        )}
                                    </div>

                                    {/* Actions */}
                                    <div className="mt-3 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                        <Button
                                            variant="outline"
                                            size="sm"
                                            className="flex-1 h-7 text-xs"
                                            onClick={(e) => { e.stopPropagation(); router.push(`/pets/${pet.id}`); }}
                                        >
                                            Ver detalhes
                                        </Button>
                                        <Button
                                            variant="ghost"
                                            size="sm"
                                            className="h-7 w-7 p-0"
                                            title="QR Code"
                                            asChild
                                            onClick={(e) => e.stopPropagation()}
                                        >
                                            <Link href={`/p/${pet.id}`} target="_blank">
                                                <QrCode className="h-3.5 w-3.5" />
                                            </Link>
                                        </Button>
                                    </div>
                                </CardContent>
                            </Card>
                        );
                    })}
                </div>
            )}
        </div>
    );
}
