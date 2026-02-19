'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useMutation } from '@tanstack/react-query';
import { ArrowLeft } from 'lucide-react';
import api from '@/lib/axios';
import PetForm, { PetFormValues } from '@/components/pets/PetForm';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import Link from 'next/link';

export default function NewPetPage() {
    const router = useRouter();
    const [error, setError] = useState('');

    const mutation = useMutation({
        mutationFn: async (values: PetFormValues) => {
            const payload = {
                ...values,
                birth_date: values.birth_date || null,
            };
            return api.post('/pets/', payload);
        },
        onSuccess: (res) => {
            router.push(`/pets/${res.data.id}`);
        },
        onError: () => {
            setError('Erro ao cadastrar pet. Verifique os dados e tente novamente.');
        },
    });

    const handleSubmit = async (values: PetFormValues) => {
        setError('');
        mutation.mutate(values);
    };

    return (
        <div className="space-y-6 max-w-2xl">
            <div className="flex items-center gap-3">
                <Button variant="ghost" size="icon" asChild>
                    <Link href="/pets">
                        <ArrowLeft className="h-4 w-4" />
                    </Link>
                </Button>
                <div>
                    <h1 className="text-2xl font-bold tracking-tight">Novo Pet</h1>
                    <p className="text-muted-foreground text-sm">Preencha as informações do seu pet</p>
                </div>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Informações do Pet</CardTitle>
                    <CardDescription>Apenas o nome e a espécie são obrigatórios.</CardDescription>
                </CardHeader>
                <CardContent>
                    {error && (
                        <div className="mb-4 p-3 text-sm text-red-600 bg-red-50 border border-red-200 rounded-md">
                            {error}
                        </div>
                    )}
                    <PetForm
                        onSubmit={handleSubmit}
                        isLoading={mutation.isPending}
                        submitLabel="Cadastrar Pet"
                    />
                </CardContent>
            </Card>
        </div>
    );
}
