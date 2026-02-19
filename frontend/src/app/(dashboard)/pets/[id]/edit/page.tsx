'use client';

import { useParams, useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import Link from 'next/link';
import api from '@/lib/axios';
import PetForm, { PetFormValues } from '@/components/pets/PetForm';
import { ArrowLeft, Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';

interface Pet {
    id: number;
    name: string;
    species: string;
    breed: string;
    sex: string;
    birth_date: string | null;
    color: string | null;
    microchip: string | null;
    notes: string | null;
}

export default function EditPetPage() {
    const params = useParams();
    const router = useRouter();
    const queryClient = useQueryClient();
    const petId = Number(params.id);
    const [error, setError] = useState('');

    const { data: pet, isLoading } = useQuery<Pet>({
        queryKey: ['pet', petId],
        queryFn: async () => (await api.get(`/pets/${petId}`)).data,
    });

    const mutation = useMutation({
        mutationFn: async (values: PetFormValues) => {
            return api.patch(`/pets/${petId}`, values);
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['pet', petId] });
            queryClient.invalidateQueries({ queryKey: ['pets'] });
            router.push(`/pets/${petId}`);
        },
        onError: () => {
            setError('Erro ao atualizar pet. Tente novamente.');
        },
    });

    const handleSubmit = async (values: PetFormValues) => {
        setError('');
        mutation.mutate(values);
    };

    if (isLoading) {
        return (
            <div className="flex h-96 items-center justify-center">
                <Loader2 className="h-8 w-8 animate-spin text-gray-400" />
            </div>
        );
    }

    if (!pet) {
        return (
            <div className="flex h-96 flex-col items-center justify-center gap-4 text-muted-foreground">
                <p>Pet não encontrado.</p>
                <Button asChild variant="outline">
                    <Link href="/pets">Voltar para lista</Link>
                </Button>
            </div>
        );
    }

    return (
        <div className="space-y-6 max-w-2xl">
            <div className="flex items-center gap-3">
                <Button variant="ghost" size="icon" asChild>
                    <Link href={`/pets/${petId}`}>
                        <ArrowLeft className="h-4 w-4" />
                    </Link>
                </Button>
                <div>
                    <h1 className="text-2xl font-bold tracking-tight">Editar Pet</h1>
                    <p className="text-muted-foreground text-sm">Atualize as informações de {pet.name}</p>
                </div>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Informações do Pet</CardTitle>
                    <CardDescription>Altere os campos desejados e clique em Salvar.</CardDescription>
                </CardHeader>
                <CardContent>
                    {error && (
                        <div className="mb-4 p-3 text-sm text-red-600 bg-red-50 border border-red-200 rounded-md">
                            {error}
                        </div>
                    )}
                    <PetForm
                        defaultValues={{
                            name: pet.name,
                            species: pet.species as any,
                            breed: pet.breed ?? '',
                            sex: (pet.sex as any) ?? 'unknown',
                            birth_date: pet.birth_date ?? '',
                            color: pet.color ?? '',
                            microchip: pet.microchip ?? '',
                            notes: pet.notes ?? '',
                        }}
                        onSubmit={handleSubmit}
                        isLoading={mutation.isPending}
                        submitLabel="Salvar Alterações"
                    />
                </CardContent>
            </Card>
        </div>
    );
}
