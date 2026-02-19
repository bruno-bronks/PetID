'use client';

import { useRef, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/axios';
import { Camera, Loader2, Trash2, CheckCircle, XCircle, ScanFace } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
    AlertDialogTrigger,
} from '@/components/ui/alert-dialog';

interface BiometryData {
    id: number;
    pet_id: number;
    quality_score: number | null;
    is_active: boolean;
    created_at: string;
}

interface BiometryTabProps {
    petId: number;
    petName: string;
}

function fileToBase64(file: File): Promise<string> {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => {
            const result = reader.result as string;
            // Remove data:image/...;base64, prefix
            resolve(result.split(',')[1]);
        };
        reader.onerror = reject;
        reader.readAsDataURL(file);
    });
}

export default function BiometryTab({ petId, petName }: BiometryTabProps) {
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [preview, setPreview] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const queryClient = useQueryClient();

    const { data: biometry, isLoading } = useQuery<BiometryData | null>({
        queryKey: ['biometry', petId],
        queryFn: async () => {
            try {
                return (await api.get(`/biometry/${petId}`)).data;
            } catch (e: unknown) {
                if ((e as { response?: { status?: number } })?.response?.status === 404) return null;
                throw e;
            }
        },
        retry: false,
    });

    const registerMutation = useMutation({
        mutationFn: async (base64: string) =>
            (await api.post('/biometry/register', { pet_id: petId, image_base64: base64 })).data,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['biometry', petId] });
            setPreview(null);
            setError(null);
        },
        onError: (e: unknown) => {
            const msg = (e as { response?: { data?: { detail?: string } } })?.response?.data?.detail ?? 'Erro ao registrar biometria.';
            setError(msg);
        },
    });

    const deleteMutation = useMutation({
        mutationFn: async () => api.delete(`/biometry/${petId}`),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['biometry', petId] });
            setPreview(null);
        },
    });

    const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;
        setError(null);
        const localUrl = URL.createObjectURL(file);
        setPreview(localUrl);
        const base64 = await fileToBase64(file);
        registerMutation.mutate(base64);
    };

    const qualityColor = (score: number | null) => {
        if (score === null) return 'bg-gray-100 text-gray-600';
        if (score >= 80) return 'bg-green-100 text-green-700';
        if (score >= 50) return 'bg-yellow-100 text-yellow-700';
        return 'bg-red-100 text-red-700';
    };

    return (
        <Card>
            <CardHeader>
                <div className="flex items-center justify-between">
                    <div>
                        <CardTitle className="text-base flex items-center gap-2">
                            <ScanFace className="h-4 w-4" />
                            Biometria Nasal
                        </CardTitle>
                        <CardDescription className="mt-1 text-xs">
                            Identifique {petName} pelo focinho. Tire uma foto nítida do nariz com boa iluminação.
                        </CardDescription>
                    </div>
                    {biometry && (
                        <AlertDialog>
                            <AlertDialogTrigger asChild>
                                <Button variant="ghost" size="icon" className="text-red-500 hover:text-red-700 hover:bg-red-50">
                                    <Trash2 className="h-4 w-4" />
                                </Button>
                            </AlertDialogTrigger>
                            <AlertDialogContent>
                                <AlertDialogHeader>
                                    <AlertDialogTitle>Remover biometria?</AlertDialogTitle>
                                    <AlertDialogDescription>
                                        A biometria nasal de {petName} será removida. Não será mais possível identificar o pet por foto do focinho.
                                    </AlertDialogDescription>
                                </AlertDialogHeader>
                                <AlertDialogFooter>
                                    <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                    <AlertDialogAction
                                        onClick={() => deleteMutation.mutate()}
                                        className="bg-red-600 hover:bg-red-700"
                                    >
                                        Remover
                                    </AlertDialogAction>
                                </AlertDialogFooter>
                            </AlertDialogContent>
                        </AlertDialog>
                    )}
                </div>
            </CardHeader>
            <CardContent>
                {isLoading ? (
                    <div className="flex justify-center py-8">
                        <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
                    </div>
                ) : biometry ? (
                    /* Already registered */
                    <div className="space-y-4">
                        <div className="flex items-center gap-3 rounded-lg border border-green-200 bg-green-50 p-4">
                            <CheckCircle className="h-6 w-6 text-green-600 shrink-0" />
                            <div>
                                <p className="font-medium text-green-800 text-sm">Biometria registrada</p>
                                <p className="text-xs text-green-600 mt-0.5">
                                    Cadastrada em {new Date(biometry.created_at).toLocaleDateString('pt-BR')}
                                </p>
                            </div>
                            <div className="ml-auto text-right">
                                {biometry.quality_score !== null && (
                                    <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${qualityColor(biometry.quality_score)}`}>
                                        Qualidade: {biometry.quality_score}%
                                    </span>
                                )}
                                <Badge
                                    variant={biometry.is_active ? 'default' : 'secondary'}
                                    className="mt-1 block text-xs"
                                >
                                    {biometry.is_active ? 'Ativa' : 'Inativa'}
                                </Badge>
                            </div>
                        </div>
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={() => fileInputRef.current?.click()}
                            disabled={registerMutation.isPending}
                        >
                            {registerMutation.isPending ? (
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                            ) : (
                                <Camera className="mr-2 h-4 w-4" />
                            )}
                            Atualizar biometria
                        </Button>
                    </div>
                ) : (
                    /* Not registered yet */
                    <div className="space-y-4">
                        {preview ? (
                            <div className="relative flex justify-center">
                                {/* eslint-disable-next-line @next/next/no-img-element */}
                                <img src={preview} alt="Preview do focinho" className="max-h-48 rounded-lg object-cover border" />
                                {registerMutation.isPending && (
                                    <div className="absolute inset-0 flex items-center justify-center rounded-lg bg-black/40">
                                        <Loader2 className="h-8 w-8 text-white animate-spin" />
                                    </div>
                                )}
                                {registerMutation.isSuccess && (
                                    <div className="absolute inset-0 flex items-center justify-center rounded-lg bg-green-500/40">
                                        <CheckCircle className="h-10 w-10 text-white" />
                                    </div>
                                )}
                            </div>
                        ) : (
                            <div className="flex flex-col items-center gap-3 rounded-lg border-2 border-dashed border-muted p-10 text-center">
                                <ScanFace className="h-12 w-12 text-muted-foreground/40" />
                                <p className="text-sm text-muted-foreground">
                                    Nenhuma biometria registrada para este pet.
                                </p>
                            </div>
                        )}
                        {error && (
                            <div className="flex items-center gap-2 rounded-md border border-red-200 bg-red-50 p-3 text-sm text-red-700">
                                <XCircle className="h-4 w-4 shrink-0" />
                                {error}
                            </div>
                        )}
                        <Button
                            onClick={() => fileInputRef.current?.click()}
                            disabled={registerMutation.isPending}
                        >
                            <Camera className="mr-2 h-4 w-4" />
                            {registerMutation.isPending ? 'Processando...' : 'Cadastrar biometria do focinho'}
                        </Button>
                        <p className="text-xs text-muted-foreground">
                            Dica: Use uma foto frontal do focinho com boa iluminação e foco nítido.
                        </p>
                    </div>
                )}
                <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/jpeg,image/png,image/webp"
                    className="hidden"
                    onChange={handleFileChange}
                />
            </CardContent>
        </Card>
    );
}
